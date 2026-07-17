import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../services/backup_service.dart';
import '../../services/notification_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isAutoBackupEnabled = false;
  List<FileSystemEntity> _autoBackups = [];
  DateTime? _lastBackupDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final backups = await _backupService.getAutoBackups();

    setState(() {
      _isAutoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
      _autoBackups = backups;

      final lastMillis = prefs.getInt('last_auto_backup_time');
      if (lastMillis != null) {
        _lastBackupDate = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      } else if (backups.isNotEmpty) {
        _lastBackupDate = backups.first.statSync().modified;
      }
    });
  }

  Future<void> _toggleAutoBackup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', value);
    setState(() => _isAutoBackupEnabled = value);

    if (value) {
      // محاولة إجراء نسخ فوري إذا تم التفعيل
      await _backupService.performAutoBackupIfNeeded();
      _loadData();
    }
  }

  Future<void> _handleRestore(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: const Text(
          'سيتم استبدال البيانات الحالية بالبيانات الموجودة في النسخة الاحتياطية. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _backupService.restoreFromAutoBackup(file);
      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          NotificationService().showSuccess(
            context,
            'تمت استعادة البيانات بنجاح. يرجى إعادة تشغيل التطبيق لتطبيق التغييرات بالكامل.',
          );
        } else {
          NotificationService().showError(context, 'فشلت عملية الاستعادة');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'النسخ الاحتياطي والأمان',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. بطاقة الحالة
                _buildStatusCard(),
                const SizedBox(height: 25),

                // 2. قسم الأتمتة
                const Text(
                  'الأتمتة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    value: _isAutoBackupEnabled,
                    onChanged: _toggleAutoBackup,
                    activeColor: AppColors.success,
                    title: const Text(
                      'نسخ احتياطي تلقائي يومي',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'سيقوم التطبيق بحفظ نسخة داخلية في جهازك مرة يومياً عند الفتح',
                      style: TextStyle(fontSize: 12),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.autorenew_rounded,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // 3. الإجراءات اليدوية
                const Text(
                  'إجراءات يدوية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.upload_file_rounded,
                        label: 'تصدير نسخة',
                        color: AppColors.primary,
                        onTap: () => _backupService.exportBackup(),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.download_rounded,
                        label: 'استيراد نسخة',
                        color: Colors.orange,
                        onTap: () async {
                          setState(() => _isLoading = true);
                          final success = await _backupService.importBackup();
                          setState(() => _isLoading = false);
                          if (mounted) {
                            if (success) {
                              NotificationService().showSuccess(
                                context,
                                'تم الاستيراد بنجاح',
                              );
                            } else {
                              NotificationService().showError(
                                context,
                                'فشل الاستيراد أو تم الإلغاء',
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 4. سجل النسخ التلقائية
                if (_autoBackups.isNotEmpty) ...[
                  const Text(
                    'سجل النسخ التلقائية (محلي)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _autoBackups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final file = _autoBackups[index] as File;
                      final date = file.statSync().modified;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.history,
                            color: Colors.grey,
                          ),
                          title: Text(
                            DateFormat('yyyy/MM/dd  hh:mm a').format(date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: TextButton(
                            onPressed: () => _handleRestore(file),
                            child: const Text('استعادة'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStatusCard() {
    final isProtected = _isAutoBackupEnabled;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProtected
              ? [Colors.green.shade600, Colors.green.shade400]
              : [Colors.grey.shade700, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isProtected ? Colors.green : Colors.grey).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isProtected ? Icons.check_circle_outline : Icons.security_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isProtected ? 'بياناتك محمية' : 'النسخ التلقائي متوقف',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _lastBackupDate != null
                    ? 'آخر نسخة: ${DateFormat('MM/dd hh:mm a').format(_lastBackupDate!)}'
                    : 'لا توجد نسخ سابقة',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}
