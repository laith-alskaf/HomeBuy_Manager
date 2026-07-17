import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

// استيراد المودلز والخدمة المحلية لجلب البيانات
import '../data/services/local_storage_service.dart';

import '../data/models/shopping_item.dart';
import '../data/models/wallet_transaction.dart';
import '../data/models/price_history.dart';
import '../data/models/vault_transaction.dart';
import '../data/models/debt_record.dart';
import '../data/models/side_balance_transaction.dart';
import '../data/models/fixed_bill.dart';
import '../data/models/savings_goal.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final LocalStorageService _storageService = LocalStorageService();
  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _lastBackupTimeKey = 'last_auto_backup_time';

  // --- 1. Core Logic: Create Backup Data ---
  Future<Map<String, dynamic>> _collectAllData() async {
    final items = await _storageService.loadShoppingList();
    final deposits = await _storageService.loadWalletTransactions();
    final prices = await _storageService.loadPriceHistory();
    final vault = await _storageService.loadVaultTransactions();
    final debts = await _storageService.loadDebts();
    final sideBalance = await _storageService.loadSideBalanceTransactions();
    final fixedBills = await _storageService.loadFixedBills();
    final savingsGoals = await _storageService.loadSavingsGoals();
    final prefs = await SharedPreferences.getInstance();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '5.1.0',
      // --- البيانات الأساسية ---
      'items': items.map((e) => e.toMap()).toList(),
      'deposits': deposits.map((e) => e.toMap()).toList(),
      'prices': prices.map((e) => e.toMap()).toList(),
      'vault_transactions': vault.map((e) => e.toMap()).toList(),
      'debts': debts.map((e) => e.toMap()).toList(),
      // --- البيانات الجديدة ---
      'side_balance_transactions': sideBalance.map((e) => e.toMap()).toList(),
      'fixed_bills': fixedBills.map((e) => e.toMap()).toList(),
      'savings_goals': savingsGoals.map((e) => e.toMap()).toList(),
      // --- الإعدادات الكاملة ---
      'settings': {
        'vault_balance': prefs.getDouble('vault_balance') ?? 0.0,
        'vault_balances_v4': prefs.getString('vault_balances_v4'),
        'low_balance_threshold':
            prefs.getDouble('low_balance_threshold') ?? 50000.0,
        'cycle_start_date': prefs.getString('cycle_start_date') ?? '',
        'vault_auto_save': prefs.getBool('vault_auto_save') ?? false,
        'vault_auto_mode_percent':
            prefs.getBool('vault_auto_mode_percent') ?? true,
        'vault_auto_value': prefs.getDouble('vault_auto_value') ?? 10.0,
        'user_name': prefs.getString('user_name') ?? '',
        'custom_categories': prefs.getString('custom_categories') ?? '',
        'custom_suggested_items':
            prefs.getString('custom_suggested_items') ?? '',
      },
    };
  }

  // --- 2. Auto Backup & Rotation Logic ---
  Future<void> performAutoBackupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_autoBackupKey) ?? false;
    if (!isEnabled) return;

    final lastBackupMillis = prefs.getInt(_lastBackupTimeKey) ?? 0;
    final lastBackupDate = DateTime.fromMillisecondsSinceEpoch(
      lastBackupMillis,
    );
    final now = DateTime.now();

    // التحقق من مرور 24 ساعة
    if (now.difference(lastBackupDate).inHours >= 24) {
      try {
        await _createLocalBackup(isAuto: true);
        await prefs.setInt(_lastBackupTimeKey, now.millisecondsSinceEpoch);
        debugPrint('Auto backup completed successfully.');
        debugPrint('Auto backup completed successfully.');
      } catch (e) {
        debugPrint('Auto backup failed: $e');
      }
    }
  }

  Future<File> _createLocalBackup({bool isAuto = false}) async {
    final data = await _collectAllData();
    final jsonString = jsonEncode(data);

    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final prefix = isAuto ? 'auto_backup' : 'manual_backup';
    final fileName =
        '${prefix}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    final file = File('${backupDir.path}/$fileName');

    await file.writeAsString(jsonString);

    if (isAuto) {
      await _rotateAutoBackups(backupDir);
    }

    return file;
  }

  Future<void> _rotateAutoBackups(Directory backupDir) async {
    final files = backupDir
        .listSync()
        .where(
          (e) => e.path.contains('auto_backup') && e.path.endsWith('.json'),
        )
        .toList();

    // ترتيب الملفات حسب تاريخ التعديل (الأقدم أولاً)
    files.sort(
      (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
    );

    // حذف الملفات الزائدة عن 5
    while (files.length > 5) {
      try {
        await files.first.delete();
        files.removeAt(0);
      } catch (e) {
        debugPrint('Error deleting old backup: $e');
        break;
      }
    }
  }

  // --- 3. Public Methods for UI ---

  // تصدير (مشاركة)
  Future<void> exportBackup() async {
    try {
      final file = await _createLocalBackup(isAuto: false);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'نسخة احتياطية - رادار المصاريف');
    } catch (e) {
      // Error
    }
  }

  // استيراد
  Future<bool> importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final success = await _restoreFromFile(file);
        return success;
      }
      return false;
    } catch (e) {
      debugPrint('Import failed: $e');
      return false;
    }
  }

  Future<bool> restoreFromAutoBackup(File file) async {
    return await _restoreFromFile(file);
  }

  Future<bool> _restoreFromFile(File file) async {
    try {
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data;

      try {
        data = jsonDecode(jsonString);
      } catch (e) {
        debugPrint('Invalid JSON format: $e');
        return false;
      }

      // التحقق من النسخة
      final version = data['version'] as String? ?? '1.0.0';
      debugPrint('Restoring backup version: $version');

      // 1. Items
      final items = (data['items'] as List)
          .map((e) => ShoppingItem.fromMap(e))
          .toList();
      await _storageService.saveShoppingList(items);

      // 2. Wallet Transactions
      final deposits = (data['deposits'] as List)
          .map((e) => WalletTransaction.fromMap(e))
          .toList();
      await _storageService.saveWalletTransactions(deposits);

      // 3. Price History
      final prices = (data['prices'] as List)
          .map((e) => PriceHistory.fromMap(e))
          .toList();
      await _storageService.savePriceHistory(prices);

      // 4. Vault Transactions
      final vault = (data['vault_transactions'] as List)
          .map((e) => VaultTransaction.fromMap(e))
          .toList();
      await _storageService.saveVaultTransactions(vault);

      // 5. Debts
      final debts = (data['debts'] as List)
          .map((e) => DebtRecord.fromMap(e))
          .toList();
      await _storageService.saveDebts(debts);

      // 6. Side Balance (جديد)
      if (data.containsKey('side_balance_transactions')) {
        final sideBalance = (data['side_balance_transactions'] as List)
            .map((e) => SideBalanceTransaction.fromMap(e))
            .toList();
        await _storageService.saveSideBalanceTransactions(sideBalance);
      }

      // 7. Fixed Bills (جديد)
      if (data.containsKey('fixed_bills')) {
        final fixedBills = (data['fixed_bills'] as List)
            .map((e) => FixedBill.fromMap(e))
            .toList();
        await _storageService.saveFixedBills(fixedBills);
      }

      // 8. Savings Goals (جديد)
      if (data.containsKey('savings_goals')) {
        final savingsGoals = (data['savings_goals'] as List)
            .map((e) => SavingsGoal.fromMap(e))
            .toList();
        await _storageService.saveSavingsGoals(savingsGoals);
      }

      // 9. Settings (محسّن)
      final prefs = await SharedPreferences.getInstance();
      if (data['settings'] != null) {
        final settings = data['settings'] as Map<String, dynamic>;

        await prefs.setDouble(
          'vault_balance',
          settings['vault_balance'] ?? 0.0,
        );

        if (settings.containsKey('vault_balances_v4') &&
            settings['vault_balances_v4'] != null) {
          await prefs.setString(
            'vault_balances_v4',
            settings['vault_balances_v4'],
          );
          await prefs.setBool('migrated_to_v4', true);
        } else {
          // Old backup without v4 map -> force migration on next app load
          await prefs.remove('vault_balances_v4');
          await prefs.setBool('migrated_to_v4', false);
        }

        await prefs.setDouble(
          'low_balance_threshold',
          settings['low_balance_threshold'] ?? 50000.0,
        );

        if ((settings['cycle_start_date'] as String? ?? '').isNotEmpty) {
          await prefs.setString(
            'cycle_start_date',
            settings['cycle_start_date'],
          );
        }
        if (settings.containsKey('vault_auto_save') ||
            settings.containsKey('is_vault_auto_save')) {
          await prefs.setBool(
            'vault_auto_save',
            settings['vault_auto_save'] ??
                settings['is_vault_auto_save'] ??
                false,
          );
        }
        if (settings.containsKey('vault_auto_mode_percent')) {
          await prefs.setBool(
            'vault_auto_mode_percent',
            settings['vault_auto_mode_percent'] ?? true,
          );
        }
        if (settings.containsKey('vault_auto_value')) {
          await prefs.setDouble(
            'vault_auto_value',
            settings['vault_auto_value'] ?? 10.0,
          );
        }
        if ((settings['user_name'] as String? ?? '').isNotEmpty) {
          await prefs.setString('user_name', settings['user_name']);
        }
        if ((settings['custom_categories'] as String? ?? '').isNotEmpty) {
          await prefs.setString(
            'custom_categories',
            settings['custom_categories'],
          );
        }
        if ((settings['custom_suggested_items'] as String? ?? '').isNotEmpty) {
          await prefs.setString(
            'custom_suggested_items',
            settings['custom_suggested_items'],
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  Future<List<FileSystemEntity>> getAutoBackups() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    if (!await backupDir.exists()) return [];

    final files = backupDir
        .listSync()
        .where(
          (e) => e.path.contains('auto_backup') && e.path.endsWith('.json'),
        )
        .toList();

    // الأحدث أولاً للعرض
    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return files;
  }
}
