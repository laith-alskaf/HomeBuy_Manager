import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homebuy_manager/data/models/vault_transaction.dart';
import 'package:homebuy_manager/presentation/sheets/checkout_item_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../data/models/shopping_item.dart';
import '../../data/models/wallet_transaction.dart';
import '../../data/models/price_history.dart';
import '../../data/services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../data/models/debt_record.dart';
import '../../services/categories_service.dart';
import '../../services/currency_service.dart';
import '../../services/budget_service.dart';
import '../../data/models/side_balance_transaction.dart';

import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/flippable_wallet_card.dart';
import '../widgets/common/bottom_nav_bar.dart';
import '../widgets/common/app_drawer.dart';
import '../widgets/home/quick_stats.dart';
import '../widgets/home/currency_header_widget.dart';
import '../widgets/shopping_list/shopping_list_view.dart';
import '../widgets/analytics/analytics_view.dart';
import '../widgets/common/app_info_dialog.dart';

import '../dialogs/add_balance_dialog.dart';
import '../dialogs/currency_conversion_dialog.dart';
import '../dialogs/edit_deposit_dialog.dart';
import '../dialogs/name_entry_dialog.dart';
import '../sheets/add_item_sheet.dart';
import '../sheets/deposits_history_sheet.dart';
import '../dialogs/reallocation_dialog.dart';

import '../utils/page_transitions.dart';
import 'settings_page.dart';
import 'shopping_history_screen.dart';
import 'smart_vault_screen.dart';
import 'debt_manager_screen.dart';
import 'analytics_screen.dart';
import 'side_balance_screen.dart';
import 'bills_manager_screen.dart';
import 'goals_screen.dart';
import 'needs_list_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- Services ---
  final LocalStorageService _storageService = LocalStorageService();
  final CategoriesService _categoriesService = CategoriesService();
  final BudgetService _budgetService = BudgetService();

  // --- State Variables ---
  // --- State Variables ---
  List<ShoppingItem> _items = [];
  List<WalletTransaction> _deposits = [];
  List<DebtRecord> _debts = [];
  List<VaultTransaction> _vaultTransactions = [];
  List<SideBalanceTransaction> _sideBalanceTransactions = [];
  List<PriceHistory> _priceHistory = [];

  ShoppingItem? _lastDeletedItem;
  bool _isLoading = false;
  int _currentIndex = 0;

  // Settings / User State
  String _userName = '';
  double _lowBalanceThreshold = 50000;
  int _cycleStartDay = 1;
  bool _isAutoSaveEnabled = false;
  bool _isAutoSavePercent = false;
  double _autoSaveValue = 10.0;
  Map<String, double> _vaultBalancesByCurrency = {};

  // --- Getters ---
  Map<String, dynamic> get categories => _categoriesService.categories;
  Map<String, List<String>> get suggestedItems =>
      _categoriesService.suggestedItems;

  // --- Per-currency wallet balance calculation ---
  Map<String, double> get _walletBalancesByCurrency {
    final Map<String, double> balances = {};
    for (var d in _deposits) {
      balances[d.currency] = (balances[d.currency] ?? 0.0) + d.amount;
    }
    for (var i in _items) {
      if (i.isBought) {
        balances[i.currency] =
            (balances[i.currency] ?? 0.0) - (i.price * i.quantity);
      }
    }
    return balances;
  }

  // Legacy SYP currentBalance (for SmartWalletCard simplicity check)
  double get _currentBalance => _walletBalancesByCurrency['SYP'] ?? 0.0;

  // --- Multi-Currency Monthly Getters (For Display) ---
  Map<String, double> get _totalAvailableBalanceByCurrency =>
      _walletBalancesByCurrency;

  Map<String, double> get _currentCycleDepositsByCurrency {
    final Map<String, double> res = {};
    final cycleStart = _getActualCycleStartDate();
    for (var d in _deposits) {
      if (d.date.isAfter(cycleStart) || d.date.isAtSameMomentAs(cycleStart)) {
        res[d.currency] = (res[d.currency] ?? 0.0) + d.amount;
      }
    }
    return res;
  }

  Map<String, double> get _currentCycleSpentByCurrency {
    final Map<String, double> res = {};
    final cycleStart = _getActualCycleStartDate();
    for (var i in _items) {
      if (i.isBought &&
          i.dateBought != null &&
          (i.dateBought!.isAfter(cycleStart) ||
              i.dateBought!.isAtSameMomentAs(cycleStart))) {
        res[i.currency] = (res[i.currency] ?? 0.0) + (i.price * i.quantity);
      }
    }
    return res;
  }

  Map<String, double> get _rolloverBalanceByCurrency {
    final Map<String, double> res = {};
    final cycleStart = _getActualCycleStartDate();
    // الرصيد المدور هو الرصيد قبل بداية الدورة الحالية
    // مجموع كل الحركات (إيداعات - شراء) التي تمت قبل cycleStart
    for (var d in _deposits) {
      if (d.date.isBefore(cycleStart)) {
        res[d.currency] = (res[d.currency] ?? 0.0) + d.amount;
      }
    }
    for (var i in _items) {
      if (i.isBought &&
          i.dateBought != null &&
          i.dateBought!.isBefore(cycleStart)) {
        res[i.currency] = (res[i.currency] ?? 0.0) - (i.price * i.quantity);
      }
    }
    return res;
  }

  DateTime _getActualCycleStartDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, _cycleStartDay);
  }

  // --- Lifecycle ---
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadData();
    await _migrateOldData();
    // Analytics removed
  }

  // --- Data Loading & Saving ---
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    final loadedItems = await _storageService.loadShoppingList();
    final loadedDeposits = await _storageService.loadWalletTransactions();
    final loadedDebts = await _storageService.loadDebts();
    final loadedVaultTx = await _storageService.loadVaultTransactions();
    final loadedSideTx = await _storageService.loadSideBalanceTransactions();
    final loadedPriceHist = await _storageService.loadPriceHistory();

    setState(() {
      _items = loadedItems;
      _deposits = loadedDeposits;
      _debts = loadedDebts;
      _vaultTransactions = loadedVaultTx;
      _sideBalanceTransactions = loadedSideTx;
      _priceHistory = loadedPriceHist;

      _userName = prefs.getString('user_name') ?? '';
      _lowBalanceThreshold = prefs.getDouble('low_balance_threshold') ?? 50000;
      _isAutoSaveEnabled = prefs.getBool('is_auto_save_enabled') ?? false;
      _isAutoSavePercent = prefs.getBool('is_auto_save_percent') ?? false;
      _autoSaveValue = prefs.getDouble('auto_save_value') ?? 10.0;

      // حساب أرصدة الخزنة من المعاملات
      _vaultBalancesByCurrency = {};
      for (var tx in _vaultTransactions) {
        if (tx.type == VaultTransactionType.manualWithdraw) {
          _vaultBalancesByCurrency[tx.currency] =
              (_vaultBalancesByCurrency[tx.currency] ?? 0.0) - tx.amount;
        } else {
          _vaultBalancesByCurrency[tx.currency] =
              (_vaultBalancesByCurrency[tx.currency] ?? 0.0) + tx.amount;
        }
      }

      _isLoading = false;
    });

    // معالجة الالتزامات الآلية بعد تحميل البيانات
    await _processAutomaticBills();
  }

  Future<void> _saveData() async {
    await _storageService.saveShoppingList(_items);
    await _storageService.saveWalletTransactions(_deposits);
    await _storageService.saveDebts(_debts);
    await _storageService.saveVaultTransactions(_vaultTransactions);
    await _storageService.saveSideBalanceTransactions(_sideBalanceTransactions);
    await _storageService.savePriceHistory(_priceHistory);
  }

  /// --- Migration Logic: Backward Compatibility ---
  Future<void> _migrateOldData() async {
    final prefs = await SharedPreferences.getInstance();
    bool migrationNeeded = false;

    // 1. Migration from single balance to transactions (Wallet)
    if (prefs.containsKey('current_balance') &&
        !prefs.containsKey('migration_v2_done')) {
      final double oldBalance = prefs.getDouble('current_balance') ?? 0.0;
      if (oldBalance > 0 && _deposits.isEmpty) {
        _deposits.add(
          WalletTransaction(
            id: 'migrated_${DateTime.now().millisecondsSinceEpoch}',
            amount: oldBalance,
            currency: 'SYP',
            date: DateTime.now(),
            note: 'رصيد سابق (نسخة قديمة)',
          ),
        );
        migrationNeeded = true;
      }
      await prefs.setBool('migration_v2_done', true);
    }

    // 2. Migration for Vault
    if (prefs.containsKey('vault_balance') &&
        !prefs.containsKey('migration_vault_v2_done')) {
      final double oldVaultBalance = prefs.getDouble('vault_balance') ?? 0.0;
      if (oldVaultBalance > 0 && _vaultTransactions.isEmpty) {
        _vaultTransactions.add(
          VaultTransaction(
            id: 'migrated_vault_${DateTime.now().millisecondsSinceEpoch}',
            amount: oldVaultBalance,
            currency: 'SYP',
            date: DateTime.now(),
            type: VaultTransactionType.manualDeposit,
            note: 'رصيد خزنة مستورد',
          ),
        );
        migrationNeeded = true;
      }
      await prefs.setBool('migration_vault_v2_done', true);
    }

    // 3. Ensuring all items have a currency (migration for items)
    bool itemsUpdated = false;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].currency.isEmpty) {
        _items[i].currency = 'SYP';
        itemsUpdated = true;
      }
    }
    if (itemsUpdated) migrationNeeded = true;

    if (migrationNeeded) {
      await _saveData();
      setState(() {}); // Refresh UI
    }
  }

  // --- Logic Methods: Transactions ---
  void _addDeposit(double amount, String note, {String currency = 'SYP'}) {
    double walletAmount = amount;
    double vaultAmount = 0.0;

    // منطق الادخار الآلي — يُطبَّق فقط إذا كانت العملة SYP
    if (_isAutoSaveEnabled && currency == 'SYP') {
      if (_isAutoSavePercent) {
        vaultAmount = amount * (_autoSaveValue / 100);
      } else {
        vaultAmount = _autoSaveValue;
      }
      if (vaultAmount > amount) vaultAmount = amount;
      walletAmount = amount - vaultAmount;
    }

    setState(() {
      _deposits.add(
        WalletTransaction(
          id: DateTime.now().toString(),
          amount: walletAmount,
          currency: currency,
          date: DateTime.now(),
          note: note,
        ),
      );

      if (vaultAmount > 0) {
        _addToVault(
          vaultAmount,
          VaultTransactionType.autoSave,
          'ادخار آلي من إيداع: $note',
          currency: currency,
        );
      }

      _saveData();
    });

    final symbol = _currencySymbol(currency);
    String msg = 'تم إضافة ${walletAmount.toStringAsFixed(0)} $symbol للمحفظة';
    if (vaultAmount > 0) {
      msg += '\nوتم ادخار ${vaultAmount.toStringAsFixed(0)} $symbol في الخزنة';
    }
    NotificationService().showSuccess(context, msg);
  }

  /// مساعد: يُرجع رمز العملة للعرض
  String _currencySymbol(String currency) {
    switch (currency) {
      case 'SYP':
        return 'ل.س';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'SAR':
        return 'ر.س';
      case 'AED':
        return 'د.إ';
      default:
        return currency;
    }
  }

  /// تحويل مبلغ من عملة لأخرى — يُنشئ حركتين دفتريتين في سجل المحفظة
  void _convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    required double rate,
    String note = '',
  }) {
    final walletBal = _walletBalancesByCurrency[fromCurrency] ?? 0.0;
    if (amount > walletBal) {
      NotificationService().showError(
        context,
        'الرصيد غير كافٍ بـ $fromCurrency',
      );
      return;
    }
    final convertedAmount = amount * rate;
    final autoNote = note.isNotEmpty
        ? note
        : 'تصريف ${_currencySymbol(fromCurrency)} ← ${_currencySymbol(toCurrency)} بسعر $rate';

    setState(() {
      // حركة سحب (سالبة) من العملة المصدر
      _deposits.add(
        WalletTransaction(
          id: '${DateTime.now().millisecondsSinceEpoch}_from',
          amount: -amount,
          currency: fromCurrency,
          date: DateTime.now(),
          note: autoNote,
        ),
      );
      // حركة إيداع (موجبة) بالعملة الهدف
      _deposits.add(
        WalletTransaction(
          id: '${DateTime.now().millisecondsSinceEpoch}_to',
          amount: convertedAmount,
          currency: toCurrency,
          date: DateTime.now(),
          note: autoNote,
        ),
      );
      _saveData();
    });
    NotificationService().showSuccess(
      context,
      'تم التصريف: $amount ${_currencySymbol(fromCurrency)} → ${convertedAmount.toStringAsFixed(2)} ${_currencySymbol(toCurrency)}',
    );
  }

  void _editLastDeposit(double amount, String note) {
    if (_deposits.isNotEmpty) {
      setState(() {
        _deposits[_deposits.length - 1] = _deposits.last.copyWith(
          amount: amount,
          note: note,
        );
        _saveData();
      });
      NotificationService().showSuccess(context, 'تم تعديل الإيداع بنجاح');
    }
  }

  // --- Logic Methods: Vault ---
  /// يُضيف للخزنة ويحدث الرصيد حسب العملة
  void _addToVault(
    double amount,
    VaultTransactionType type,
    String note, {
    String currency = 'SYP',
  }) {
    _vaultBalancesByCurrency[currency] =
        (_vaultBalancesByCurrency[currency] ?? 0.0) + amount;
    _vaultTransactions.add(
      VaultTransaction(
        id: DateTime.now().toString(),
        amount: amount,
        currency: currency,
        date: DateTime.now(),
        type: type,
        note: note,
      ),
    );
  }

  /// إيداع من المحفظة إلى الخزنة (يخصم من رصيد العملة المحددة في المحفظة)
  bool _manualDepositToVault(
    double amount,
    String note, {
    String currency = 'SYP',
    bool deductFromWallet = true,
  }) {
    final walletBal = _walletBalancesByCurrency[currency] ?? 0.0;
    if (deductFromWallet && walletBal < amount) {
      NotificationService().showError(
        context,
        'رصيد المحفظة غير كافٍ بـ $currency',
      );
      return false;
    }
    setState(() {
      if (deductFromWallet) {
        _deposits.add(
          WalletTransaction(
            id: DateTime.now().toString(),
            amount: -amount,
            currency: currency,
            date: DateTime.now(),
            note: 'نقل إلى الخزنة: $note',
          ),
        );
      }
      _addToVault(
        amount,
        VaultTransactionType.manualDeposit,
        note,
        currency: currency,
      );
      _saveData();
    });
    NotificationService().showSuccess(
      context,
      'تم إيداع ${amount.toStringAsFixed(0)} ${_currencySymbol(currency)} في الخزنة',
    );
    return true;
  }

  /// سحب من الخزنة للمحفظة (مع إمكانية التصريف بين العملات)
  bool _manualWithdrawFromVault(
    double amount,
    String note, {
    String fromCurrency = 'SYP',
    String? toCurrency,
    double? conversionRate,
  }) {
    final vaultBal = _vaultBalancesByCurrency[fromCurrency] ?? 0.0;
    if (vaultBal < amount) {
      NotificationService().showError(
        context,
        'رصيد الخزنة غير كافٍ بـ $fromCurrency',
      );
      return false;
    }
    setState(() {
      _vaultBalancesByCurrency[fromCurrency] = vaultBal - amount;
      _vaultTransactions.add(
        VaultTransaction(
          id: DateTime.now().toString(),
          amount: amount,
          currency: fromCurrency,
          toCurrency: toCurrency,
          date: DateTime.now(),
          type: VaultTransactionType.manualWithdraw,
          note: note,
        ),
      );

      final targetCurrency = toCurrency ?? fromCurrency;
      final depositAmount = (toCurrency != null && conversionRate != null)
          ? amount * conversionRate
          : amount;

      _deposits.add(
        WalletTransaction(
          id: DateTime.now().toString(),
          amount: depositAmount,
          currency: targetCurrency,
          date: DateTime.now(),
          note: toCurrency != null
              ? 'سحب من الخزنة مع تصريف إلى ${_currencySymbol(targetCurrency)}: $note'
              : 'سحب من الخزنة: $note',
        ),
      );
      _saveData();
    });
    NotificationService().showSuccess(
      context,
      'تم سحب ${amount.toStringAsFixed(0)} ${_currencySymbol(fromCurrency)} من الخزنة',
    );
    return true;
  }

  /// معالجة الالتزامات الثابتة المبرمجة للدفع التلقائي
  Future<void> _processAutomaticBills() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    // تحديد الدورة الحالية (السنة-الشهر)
    final currentCycleId = '${now.year}-${now.month}';

    final bills = await _storageService.loadFixedBills();
    bool updated = false;

    for (var i = 0; i < bills.length; i++) {
      final bill = bills[i];
      // إذا كان الالتزام "دفع تلقائي" ولم يتم دفعه أو تخطيه في هذه الدورة
      if (bill.isAutoPay && !bill.statusHistory.containsKey(currentCycleId)) {
        final autoBillId = 'auto_bill_${bill.id}_$currentCycleId';

        // التحقق مما إذا كان قد تم إضافته مسبقاً في قائمة المشتريات (لزيادة الأمان)
        final alreadyExists = _items.any((item) => item.id == autoBillId);

        if (!alreadyExists) {
          // إضافة المصروف لقائمة المشتريات
          _items.add(
            ShoppingItem(
              id: autoBillId,
              name: bill.name,
              price: bill.amount,
              currency: bill.currency,
              quantity: 1,
              category: bill.category,
              note: 'دفع تلقائي (التزام ثابت)',
              dateBought: DateTime.now(),
              isBought: true,
            ),
          );
        }

        // تحديث حالة الالتزام في السجل
        bills[i].statusHistory[currentCycleId] = 'paid';
        updated = true;
      }
    }

    if (updated) {
      setState(() {
        // تحديث القائمة المحلية للمشتريات
      });
      await _storageService.saveFixedBills(bills);
      await _storageService.saveShoppingList(_items);
      if (mounted) {
        NotificationService().showInfo(
          context,
          'تم تنفيذ المدفوعات التلقائية لالتزاماتك الثابتة',
        );
      }
    }
  }

  // --- Logic Methods: Side Balance ---
  void _handleSideBalanceTransaction(
    double amount,
    String currency,
    String note,
    SideBalanceType type,
  ) {
    setState(() {
      _sideBalanceTransactions.add(
        SideBalanceTransaction(
          id: DateTime.now().toString(),
          amount: amount,
          currency: currency,
          date: DateTime.now(),
          type: type,
          note: note,
        ),
      );
      _saveData();
    });
    NotificationService().showSuccess(
      context,
      'تم حفظ حركة الرصيد الجانبي بنجاح',
    );
  }

  void _transferFromSideBalanceToWallet(
    double amount,
    String currency,
    String note,
  ) {
    setState(() {
      _sideBalanceTransactions.add(
        SideBalanceTransaction(
          id: DateTime.now().toString(),
          amount: amount,
          currency: currency,
          date: DateTime.now(),
          type: SideBalanceType.withdraw,
          note: 'تحويل للمحفظة الأساسية: $note',
        ),
      );
      _deposits.add(
        WalletTransaction(
          id: DateTime.now().toString(),
          amount: amount,
          currency: currency,
          date: DateTime.now(),
          note: 'تحويل من الرصيد الجانبي: $note',
        ),
      );
      _saveData();
    });
    NotificationService().showSuccess(
      context,
      'تم تحويل ${amount.toStringAsFixed(0)} ${_currencySymbol(currency)} للمحفظة بنجاح',
    );
  }

  void _editSideBalanceTransaction(
    SideBalanceTransaction oldTx,
    double newAmount,
    String newCurrency,
    String newNote,
    SideBalanceType newType,
  ) {
    setState(() {
      final idx = _sideBalanceTransactions.indexWhere((t) => t.id == oldTx.id);
      if (idx != -1) {
        _sideBalanceTransactions[idx] = SideBalanceTransaction(
          id: oldTx.id,
          amount: newAmount,
          currency: newCurrency,
          date: oldTx.date,
          type: newType,
          note: newNote,
        );
        _saveData();
      }
    });
    NotificationService().showSuccess(context, 'تم تعديل الحركة بنجاح');
  }

  void _deleteSideBalanceTransaction(String id) {
    setState(() {
      _sideBalanceTransactions.removeWhere((t) => t.id == id);
      _saveData();
    });
    NotificationService().showSuccess(context, 'تم حذف الحركة بنجاح');
  }

  // --- Logic Methods: User Profile ---
  void _showNameEntryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => NameEntryDialog(
        initialName: _userName,
        onSave: (newName) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', newName);

          // Analytics removed

          if (mounted) {
            setState(() {
              _userName = newName;
            });
            NotificationService().showSuccess(context, 'أهلاً بك يا $newName!');
            HapticFeedback.mediumImpact();
          }
        },
      ),
    );
  }

  // --- Logic Methods: Debts (Smart Integration) ---
  void _addDebt(DebtRecord debt, bool updateWallet) {
    setState(() {
      _debts.add(debt);

      if (updateWallet) {
        final amount = debt.type == DebtType.liability
            ? debt.totalAmount
            : -debt.totalAmount;
        final note = debt.type == DebtType.liability
            ? 'استدانة من: ${debt.personName}'
            : 'إقراض إلى: ${debt.personName}';

        _deposits.add(
          WalletTransaction(
            id: DateTime.now().toString(),
            amount: amount,
            date: DateTime.now(),
            note: note,
          ),
        );
      }
      _saveData();
    });
    NotificationService().showSuccess(context, 'تم إضافة السجل بنجاح');
  }

  void _addDebtPayment(String debtId, double amount, bool updateWallet) {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index != -1) {
      setState(() {
        final debt = _debts[index];
        final newTransactions = List<DebtTransaction>.from(debt.transactions)
          ..add(
            DebtTransaction(
              id: DateTime.now().toString(),
              amount: amount,
              currency: debt.currency,
              date: DateTime.now(),
            ),
          );

        final newPaidAmount = debt.paidAmount + amount;
        final isSettled = newPaidAmount >= debt.totalAmount;

        _debts[index] = debt.copyWith(
          paidAmount: newPaidAmount,
          transactions: newTransactions,
          isSettled: isSettled,
        );

        if (updateWallet) {
          // سداد دين "علي" -> خصم من المحفظة
          // استلام سداد "لي" -> زيادة في المحفظة
          final walletAmount = debt.type == DebtType.liability
              ? -amount
              : amount;
          final note =
              'دفعة ${debt.type == DebtType.liability ? 'لـ' : 'من'} ${debt.personName}';

          _deposits.add(
            WalletTransaction(
              id: DateTime.now().toString(),
              amount: walletAmount,
              date: DateTime.now(),
              note: note,
            ),
          );
        }
        _saveData();
      });
      NotificationService().showSuccess(context, 'تم تسجيل الدفعة');
    }
  }

  // --- Logic Methods: Pricing ---
  void _recordPrice(String name, String category, double price) {
    final index = _priceHistory.indexWhere(
      (p) =>
          p.itemName.toLowerCase() == name.toLowerCase() &&
          p.category == category,
    );

    if (index != -1) {
      _priceHistory[index].lastPrice = price;
      _priceHistory[index].dateRecorded = DateTime.now();
    } else {
      _priceHistory.add(
        PriceHistory(
          itemName: name,
          category: category,
          lastPrice: price,
          dateRecorded: DateTime.now(),
        ),
      );
    }
  }

  double? _getLastPrice(String name, String category) {
    try {
      final priceRecord = _priceHistory.firstWhere(
        (p) =>
            p.itemName.toLowerCase() == name.toLowerCase() &&
            p.category == category,
      );
      return priceRecord.lastPrice > 0 ? priceRecord.lastPrice : null;
    } catch (e) {
      return null;
    }
  }

  // --- Logic Methods: Items ---
  Future<void> _addItem(
    String name,
    String category,
    double price,
    int quantity,
    String note,
    String currency,
  ) async {
    // Haptic Feedback
    HapticFeedback.lightImpact();

    // Analytics removed

    // 1. منطق الميزانية المرنة (Envelope Budgeting Interceptor)
    final double totalCost = price * quantity;
    final double categoryLimit = _budgetService.getLimit(
      category,
      date: DateTime.now(),
    );

    // إذا كان هناك حد للميزانية لهذه الفئة
    if (categoryLimit > 0) {
      // حساب المصروف الحالي لهذه الفئة في هذا الشهر
      final now = DateTime.now();
      final currentSpent = _items
          .where(
            (i) =>
                i.category == category &&
                i.isBought &&
                i.dateBought != null &&
                i.dateBought!.year == now.year &&
                i.dateBought!.month == now.month,
          )
          .fold(0.0, (sum, item) => sum + (item.price * item.quantity));

      final remainingBalance = categoryLimit - currentSpent;

      if (totalCost > remainingBalance) {
        final Map<String, double> sources = {};
        for (var catKey in categories.keys) {
          if (catKey == category) continue;
          final limit = _budgetService.getLimit(catKey, date: DateTime.now());
          if (limit > 0) {
            final spent = _items
                .where(
                  (i) =>
                      i.category == catKey &&
                      i.isBought &&
                      i.dateBought?.month == now.month,
                )
                .fold(0.0, (s, i) => s + (i.price * i.quantity));
            final rem = limit - spent;
            if (rem >= (totalCost - remainingBalance)) {
              sources[catKey] = rem;
            }
          }
        }

        // إظهار حوار إعادة التوزيع
        final sourceCategory = await showDialog<String>(
          context: context,
          builder: (ctx) => ReallocationDialog(
            targetCategoryName: categories[category]['label'],
            requiredAmount: totalCost,
            availableInTarget: remainingBalance,
            availableSources: sources,
            categoriesConfig: categories,
          ),
        );

        if (sourceCategory != null) {
          // تم الموافقة على النقل
          final deficit = totalCost - remainingBalance;
          await _budgetService.transferBudget(
            sourceCategory,
            category,
            deficit,
          );
          if (mounted) {
            NotificationService().showInfo(context, 'تم نقل الميزانية بنجاح');
          }
        } else {
          // تم الإلغاء
          return;
        }
      }
    }

    double currentRate = 0.0;
    bool isBoughtNow = price > 0;

    if (isBoughtNow) {
      currentRate = await CurrencyService().getTodayRate();
    }

    setState(() {
      _items.add(
        ShoppingItem(
          id: DateTime.now().toString(),
          name: name,
          category: category,
          price: price,
          currency: currency,
          quantity: quantity,
          note: note,
          isBought: isBoughtNow,
          dateBought: isBoughtNow ? DateTime.now() : null,
          exchangeRate: currentRate,
        ),
      );
      if (price > 0) _recordPrice(name, category, price);
      _saveData();
    });

    if (!_categoriesService.isItemInCategory(category, name)) {
      await _categoriesService.addItemToCategory(category, name);
    }

    if (!mounted) return;
    NotificationService().showSuccess(context, 'تمت إضافة "$name" إلى القائمة');
  }

  Future<void> _confirmPurchase(
    String itemId,
    double finalPrice,
    int qty,
    String currency,
    String note,
  ) async {
    final confirmIndex = _items.indexWhere((item) => item.id == itemId);
    if (confirmIndex != -1) {
      double currentRate = await CurrencyService().getTodayRate();

      setState(() {
        _items[confirmIndex].price = finalPrice;
        _items[confirmIndex].quantity = qty;
        _items[confirmIndex].currency = currency;
        _items[confirmIndex].note = note;
        _items[confirmIndex].isBought = true;
        _items[confirmIndex].dateBought = DateTime.now();
        _items[confirmIndex].exchangeRate = currentRate;

        if (finalPrice > 0) {
          _recordPrice(
            _items[confirmIndex].name,
            _items[confirmIndex].category,
            finalPrice,
          );
        }
        _saveData();
      });

      if (mounted) {
        NotificationService().showSuccess(
          context,
          '✓ تم شراء "${_items[confirmIndex].name}" وتسجيله',
        );
      }
    }
  }

  Future<void> _toggleStatus(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final wasBought = _items[index].isBought;

      // Haptic Feedback
      HapticFeedback.selectionClick();

      if (!wasBought) {
        // إذا كان العنصر غير مشترى، نظهر نافذة تأكيد الدفع
        await CheckoutItemSheet.show(
          context,
          item: _items[index],
          balancesByCurrency: _walletBalancesByCurrency,
          onConfirm: _confirmPurchase,
        );
      } else {
        // إذا كان تم شراؤه مسبقاً والمستخدم يريد التراجع السريع عنه (إلغاء الشراء)
        setState(() {
          _items[index].isBought = false;
          _items[index].dateBought = null;
          _items[index].exchangeRate = 0.0;
          _saveData();
        });
      }
    }
  }

  Future<void> _editItem(
    String id,
    String name,
    String category,
    double price,
    int quantity,
    String note,
    String currency,
  ) async {
    final index = _items.indexWhere((element) => element.id == id);
    if (index != -1) {
      setState(() {
        _items[index]
          ..name = name
          ..category = category
          ..price = price
          ..currency = currency
          ..quantity = quantity
          ..note = note;

        if (price > 0) _recordPrice(name, category, price);
        _saveData();
      });

      if (!_categoriesService.isItemInCategory(category, name)) {
        await _categoriesService.addItemToCategory(category, name);
      }

      if (!mounted) return;
      NotificationService().showSuccess(context, 'تم تعديل "$name" بنجاح');
    }
  }

  void _deleteItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      setState(() {
        _lastDeletedItem = _items[index];
        _items.removeAt(index);
        _saveData();
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف "${_lastDeletedItem!.name}"'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'تراجع',
            textColor: Colors.white,
            onPressed: () {
              if (_lastDeletedItem != null) {
                setState(() {
                  _items.insert(index, _lastDeletedItem!);
                  _saveData();
                });
              }
            },
          ),
        ),
      );
    }
  }

  // --- UI Presentation Methods ---
  void _showAddBalanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddBalanceDialog(
        onAdd: (amount, note, {String currency = 'SYP'}) =>
            _addDeposit(amount, note, currency: currency),
      ),
    );
  }

  void _showCurrencyConversionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CurrencyConversionDialog(
        balancesByCurrency: _walletBalancesByCurrency,
        onConvert:
            ({
              required fromCurrency,
              required toCurrency,
              required amount,
              required rate,
              required note,
            }) {
              _convertCurrency(
                fromCurrency: fromCurrency,
                toCurrency: toCurrency,
                amount: amount,
                rate: rate,
                note: note,
              );
            },
      ),
    );
  }

  void _showEditLastDepositDialog() {
    if (_deposits.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => EditDepositDialog(
        transaction: _deposits.last,
        onEdit: (amount, note) {
          _editLastDeposit(amount, note);
          _showDepositsHistory();
        },
      ),
    );
  }

  void _showDepositsHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DepositsHistorySheet(
        deposits: _deposits,
        onEditLast: () {
          Navigator.pop(ctx);
          _showEditLastDepositDialog();
        },
      ),
    );
  }

  Future<void> _showAddItemSheet([ShoppingItem? item]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddItemSheet(
        onAdd: (name, cat, price, qty, note, currency) async {
          if (item != null) {
            await _editItem(item.id, name, cat, price, qty, note, currency);
          } else {
            await _addItem(name, cat, price, qty, note, currency);
          }
        },
        categories: categories,
        suggestedItems: suggestedItems,
        existingItem: item,
        balancesByCurrency: _walletBalancesByCurrency,
        getLastPrice: _getLastPrice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      drawer: AppDrawer(
        onHistoryTap: () {
          context.pushSlideFade(
            ShoppingHistoryScreen(items: _items, categories: categories),
          );
        },
        items: _items,
        categories: categories,
        onHomeTap: () => setState(() => _currentIndex = 0),
        onSettingsTap: () async {
          // حساب المصروف الحالي لكل فئة لهذا الشهر لتمريره للإعدادات
          final now = DateTime.now();
          final Map<String, double> currentSpending = {};
          for (var item in _items) {
            if (item.isBought &&
                item.dateBought != null &&
                item.dateBought!.year == now.year &&
                item.dateBought!.month == now.month) {
              currentSpending[item.category] =
                  (currentSpending[item.category] ?? 0) +
                  (item.price * item.quantity);
            }
          }

          final newLimit = await context.pushSlideFade(
            SettingsPage(
              currentThreshold: _lowBalanceThreshold,
              currentSpending: currentSpending,
              allItems: _items,
              currentBalance: _currentBalance,
              currentUserName: _userName,
            ),
          );
          if (newLimit != null) {
            setState(() => _lowBalanceThreshold = newLimit);
          }

          await _loadData();
        },
        onVaultTap: () {
          context.pushSlideFade(
            SmartVaultScreen(
              vaultBalancesByCurrency: _vaultBalancesByCurrency,
              transactions: _vaultTransactions,
              onDeposit:
                  (
                    amount,
                    note, {
                    String currency = 'SYP',
                    bool deductFromWallet = true,
                  }) => _manualDepositToVault(
                    amount,
                    note,
                    currency: currency,
                    deductFromWallet: deductFromWallet,
                  ),
              onWithdraw:
                  (
                    amount,
                    note, {
                    String fromCurrency = 'SYP',
                    String? toCurrency,
                    double? conversionRate,
                  }) => _manualWithdrawFromVault(
                    amount,
                    note,
                    fromCurrency: fromCurrency,
                    toCurrency: toCurrency,
                    conversionRate: conversionRate,
                  ),
              isAutoSaveEnabled: _isAutoSaveEnabled,
              isAutoSavePercent: _isAutoSavePercent,
              autoSaveValue: _autoSaveValue,
              onSaveSettings: (enabled, isPercent, val) {
                setState(() {
                  _isAutoSaveEnabled = enabled;
                  _isAutoSavePercent = isPercent;
                  _autoSaveValue = val;
                  _saveData();
                });
              },
            ),
          );
        },
        onGoalsTap: () async {
          await context.pushSlideFade(
            GoalsScreen(balancesByCurrency: _totalAvailableBalanceByCurrency),
          );
          _loadData();
        },
        onDebtsTap: () {
          context.pushSlideFade(
            DebtManagerScreen(
              debts: _debts,
              onAddDebt: _addDebt,
              onAddPayment: _addDebtPayment,
              walletBalancesByCurrency: _walletBalancesByCurrency,
              vaultBalancesByCurrency: _vaultBalancesByCurrency,
              onWithdrawFromVault: (amount, note, {currency = 'SYP'}) =>
                  _manualWithdrawFromVault(
                    amount,
                    note,
                    fromCurrency: currency,
                  ),
            ),
          );
        },
        onSideBalanceTap: () {
          context.pushSlideFade(
            SideBalanceScreen(
              transactions: _sideBalanceTransactions,
              onTransaction: _handleSideBalanceTransaction,
              onEditTransaction: _editSideBalanceTransaction,
              onDeleteTransaction: _deleteSideBalanceTransaction,
              onTransferToWallet: _transferFromSideBalanceToWallet,
            ),
          );
        },
        onBillsTap: () {
          context.pushSlideFade(const BillsManagerScreen());
        },
        onAnalyticsTap: () {
          context.pushSlideFade(
            AnalyticsScreen(
              walletBalancesByCurrency: _walletBalancesByCurrency,
              vaultBalancesByCurrency: _vaultBalancesByCurrency,
              debts: _debts,
              items: _items,
              deposits: _deposits,
              sideBalanceTransactions: _sideBalanceTransactions,
              categories: categories,
            ),
          );
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  height: 350,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - value)),
                              child: Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Builder(
                                builder: (innerContext) {
                                  return CustomAppBar(
                                    onHistoryPressed: _showDepositsHistory,
                                    userName: _userName,
                                    onNameTap: _showNameEntryDialog,
                                    onMenuPressed: () {
                                      Scaffold.of(innerContext).openDrawer();
                                    },
                                    onInfoPressed: () {
                                      AppInfoDialog.show(
                                        context,
                                        title:
                                            'المحفظة الذكية (Multi-Currency)',
                                        description:
                                            'مركز التحكم المالي الخاص بك، حيث يتم دمج أرصدتك الحالية مع المبالغ المدورة من الأشهر السابقة بكل دقة لكل عملة.',
                                        features: [
                                          {
                                            'title': 'الرصيد المتاح الكلي',
                                            'description':
                                                'الرصيد المتاح (Total Available) هو مجموع "الرصيد المدور" + "رصيد الشهر الحالي"، وهو ما تملكه فعلياً لكل عملة.',
                                            'icon': Icons
                                                .account_balance_wallet_rounded,
                                            'color': AppColors.primary,
                                          },
                                          {
                                            'title': 'تنبيه العملة السورية',
                                            'description':
                                                'يظهر اللون الأحمر للتحذير بناءً على رصيدك بـ SYP فقط، لضمان إدارة ميزانية المعيشة الأساسية بدقة.',
                                            'icon': Icons.warning_amber_rounded,
                                            'color': AppColors.danger,
                                          },
                                          {
                                            'title': 'إضافة سريعة',
                                            'description':
                                                'زر الـ (+) يدعم الإضافة بكل العملات مع جلب السعر الأخير تلقائياً لكل مادة لتسهيل التدوين.',
                                            'icon': Icons.add_task_rounded,
                                            'color': Colors.amber,
                                          },
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 5),
                              CurrencyHeaderWidget(
                                onConvertTap: _showCurrencyConversionDialog,
                              ),
                              const SizedBox(height: 10),
                              if (_currentIndex == 0)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: FlippableWalletCard(
                                    lowBalanceThreshold: _lowBalanceThreshold,
                                    currentBalanceByCurrency:
                                        _totalAvailableBalanceByCurrency,
                                    totalDepositsByCurrency:
                                        _currentCycleDepositsByCurrency,
                                    totalSpentByCurrency:
                                        _currentCycleSpentByCurrency,
                                    rolloverBalanceByCurrency:
                                        _rolloverBalanceByCurrency,
                                    onAddBalance: _showAddBalanceDialog,
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  switchInCurve: Curves.easeInOut,
                                  switchOutCurve: Curves.easeInOut,
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.05),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _currentIndex == 0
                                      ? _buildHomeView()
                                      : _buildAnalyticsView(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showAddItemSheet();
              },
              tooltip: 'إضافة عنصر',
              backgroundColor: AppColors.accent,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 30,
                color: Colors.white,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onIndexChanged: (index) {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
          }
        },
      ),
    );
  }

  Widget _buildHomeView() {
    final now = DateTime.now();
    // قائمة QuickStats تحتاج كل العناصر لحساب الـ Pending Count وغيرها المشتراة اليوم
    final quickStatsItems = _items.where((item) {
      if (!item.isBought) return true; // قيد الانتظار مطلوب للإحصائيات
      if (item.dateBought == null) return false;
      return item.dateBought!.year == now.year &&
          item.dateBought!.month == now.month &&
          item.dateBought!.day == now.day;
    }).toList();

    // قائمة ShoppingListView الآن تعرض فقط المشتريات الفعلية لليوم (تم شراءها)
    final boughtTodayItems = quickStatsItems.where((i) => i.isBought).toList();

    return Column(
      key: const ValueKey('HomeView'),
      children: [
        QuickStats(
          items: quickStatsItems,
          onPendingTap: () {
            context.pushSlideFade(
              NeedsListScreen(
                items: _items,
                categories: categories,
                suggestedItems: suggestedItems,
                onDelete: _deleteItem,
                onAddQuick: (name, cat) => _addItem(name, cat, 0, 1, '', 'SYP'),
                balancesByCurrency: _walletBalancesByCurrency,
                onConfirmCheckout: _confirmPurchase,
                onEdit: (item) => _showAddItemSheet(item),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ShoppingListView(
            items: boughtTodayItems,
            categories: categories,
            onDelete: _deleteItem,
            onToggle: _toggleStatus,
            onEdit: _showAddItemSheet,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsView() {
    return Column(
      key: const ValueKey('AnalyticsView'),
      children: [
        Expanded(
          child: AnalyticsView(items: _items, categories: categories),
        ),
      ],
    );
  }
}
