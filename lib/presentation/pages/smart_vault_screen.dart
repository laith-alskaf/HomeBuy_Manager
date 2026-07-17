import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homebuy_manager/presentation/pages/vault_history_screen.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../config/app_dimensions.dart';
import '../../data/models/vault_transaction.dart';
import '../../utils/formatters.dart';
import '../widgets/common/animated_button.dart';
import '../widgets/common/animated_counter.dart';
import '../utils/page_transitions.dart';
import '../widgets/common/app_info_dialog.dart';

class SmartVaultScreen extends StatefulWidget {
  final Map<String, double> vaultBalancesByCurrency;
  final List<VaultTransaction> transactions;
  final bool Function(double, String, {String currency, bool deductFromWallet})
  onDeposit;
  final bool Function(
    double,
    String, {
    String fromCurrency,
    String? toCurrency,
    double? conversionRate,
  })
  onWithdraw;
  final bool isAutoSaveEnabled;
  final bool isAutoSavePercent;
  final double autoSaveValue;
  final Function(bool, bool, double) onSaveSettings;

  /// للتوافقية: يستخدم في الشريط العلوي ويمثل رصيد SYP
  double get vaultBalance => vaultBalancesByCurrency['SYP'] ?? 0.0;

  const SmartVaultScreen({
    super.key,
    required this.vaultBalancesByCurrency,
    required this.transactions,
    required this.onDeposit,
    required this.onWithdraw,
    required this.isAutoSaveEnabled,
    required this.isAutoSavePercent,
    required this.autoSaveValue,
    required this.onSaveSettings,
  });

  @override
  State<SmartVaultScreen> createState() => _SmartVaultScreenState();
}

class _SmartVaultScreenState extends State<SmartVaultScreen>
    with SingleTickerProviderStateMixin {
  late bool _isAutoSaveEnabled;
  late bool _isAutoSavePercent;
  late TextEditingController _autoSaveController;
  late Map<String, double> _currentBalances;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  // --- Currency helpers ---
  static const List<String> _currencies = ['SYP', 'USD', 'EUR', 'SAR', 'AED'];
  static const Map<String, String> _currencySymbols = {
    'SYP': 'ل.س',
    'USD': '\$',
    'EUR': '€',
    'SAR': 'ر.س',
    'AED': 'د.إ',
  };

  String _displayCurrency = 'SYP'; // العملة المعروضة في بطاقة الرصيد

  String _sym(String c) => _currencySymbols[c] ?? c;

  @override
  void initState() {
    super.initState();
    _isAutoSaveEnabled = widget.isAutoSaveEnabled;
    _isAutoSavePercent = widget.isAutoSavePercent;
    _autoSaveController = TextEditingController(
      text: widget.autoSaveValue.toStringAsFixed(0),
    );
    _currentBalances = Map.of(widget.vaultBalancesByCurrency);

    // تحديد العملة الافتراضية — أول عملة لها رصيد موجب
    final activeCurrencies = _currentBalances.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
    if (activeCurrencies.isNotEmpty && !activeCurrencies.contains('SYP')) {
      _displayCurrency = activeCurrencies.first;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _autoSaveController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _animateBalanceChange() {
    _animationController.reset();
    _animationController.forward();
  }

  void _animateToggle() {
    _animationController.forward(from: 0.5);
  }

  // --- Dialogs ---

  void _showDepositDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCurrency = 'SYP';
    bool deductFromWallet = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('إيداع في الخزنة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- اختيار العملة ---
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'العملة',
                    prefixIcon: const Icon(Icons.currency_exchange_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _currencies
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('${_sym(c)}  $c'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDlg(() => selectedCurrency = v);
                  },
                ),
                const SizedBox(height: 14),

                // --- المبلغ ---
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    suffixText: _sym(selectedCurrency),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // --- ملاحظة ---
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظة (اختياري)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // --- خصم من المحفظة أم إيداع خارجي ---
                SwitchListTile(
                  title: const Text(
                    'خصم من رصيد المحفظة',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    deductFromWallet
                        ? 'سيُخصم المبلغ من المحفظة'
                        : 'إيداع نقدي مباشر (خارجي)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: deductFromWallet,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setDlg(() => deductFromWallet = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = parseFormattedNumber(amountController.text);
                if (amount > 0) {
                  final success = widget.onDeposit(
                    amount,
                    noteController.text.isEmpty
                        ? 'إيداع في الخزنة'
                        : noteController.text,
                    currency: selectedCurrency,
                    deductFromWallet: deductFromWallet,
                  );

                  if (success) {
                    setState(() {
                      _currentBalances[selectedCurrency] =
                          (_currentBalances[selectedCurrency] ?? 0.0) + amount;
                      _displayCurrency = selectedCurrency;
                    });
                    _animateBalanceChange();
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctx);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('إيداع'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final rateController = TextEditingController();
    String fromCurrency = 'SYP';
    bool withConversion = false;
    String toCurrency = 'USD';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('سحب من الخزنة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- عملة السحب ---
                DropdownButtonFormField<String>(
                  value: fromCurrency,
                  decoration: InputDecoration(
                    labelText: 'العملة المسحوبة',
                    prefixIcon: const Icon(Icons.wallet_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _currencies.map((c) {
                    final bal = _currentBalances[c] ?? 0.0;
                    return DropdownMenuItem(
                      value: c,
                      child: Text(
                        '${_sym(c)}  $c  (${bal.toStringAsFixed(0)})',
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setDlg(() => fromCurrency = v);
                  },
                ),
                const SizedBox(height: 14),

                // --- المبلغ ---
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    suffixText: _sym(fromCurrency),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // --- ملاحظة ---
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظة (اختياري)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // --- سحب مع تحويل ---
                SwitchListTile(
                  title: const Text(
                    'سحب مع تصريف العملة',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    withConversion
                        ? 'سيُحوَّل المبلغ عند الإضافة للمحفظة'
                        : 'سيُضاف بنفس عملة الخزنة',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: withConversion,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setDlg(() => withConversion = v),
                  contentPadding: EdgeInsets.zero,
                ),

                // --- حقول التحويل (تظهر فقط عند تفعيل التبديل) ---
                if (withConversion) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: toCurrency == fromCurrency
                        ? _currencies.firstWhere(
                            (c) => c != fromCurrency,
                            orElse: () => 'USD',
                          )
                        : toCurrency,
                    decoration: InputDecoration(
                      labelText: 'العملة الهدف',
                      prefixIcon: const Icon(Icons.swap_horiz_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _currencies
                        .where((c) => c != fromCurrency)
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text('${_sym(c)}  $c'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDlg(() => toCurrency = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          'سعر الصرف (1 ${_sym(fromCurrency)} = ? ${_sym(toCurrency)})',
                      hintText: 'مثال: 0.00038',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = parseFormattedNumber(amountController.text);
                if (amount <= 0) return;

                final rate = withConversion
                    ? double.tryParse(rateController.text.replaceAll(',', '.'))
                    : null;

                if (withConversion && (rate == null || rate <= 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال سعر صرف صحيح')),
                  );
                  return;
                }

                final success = widget.onWithdraw(
                  amount,
                  noteController.text.isEmpty
                      ? 'سحب من الخزنة'
                      : noteController.text,
                  fromCurrency: fromCurrency,
                  toCurrency: withConversion ? toCurrency : null,
                  conversionRate: rate,
                );

                if (success) {
                  setState(() {
                    final current = _currentBalances[fromCurrency] ?? 0.0;
                    _currentBalances[fromCurrency] = (current - amount).clamp(
                      0,
                      double.infinity,
                    );
                  });
                  _animateBalanceChange();
                  HapticFeedback.heavyImpact();
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('سحب'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الخزنة الذكية',
          style: AppTypography.h5.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              AppInfoDialog.show(
                context,
                title: 'الخزنة الذكية (Smart Vault)',
                description:
                    'الخزنة هي حسابك المعزول للادخار وحفظ الأموال الفائضة بعيداً عن المصروف اليومي، مع دعم كامل للادخار الآلي.',
                features: [
                  {
                    'title': 'الادخار التلقائي',
                    'description':
                        'يمكنك تفعيل الخصم التلقائي عند كل إيداع في المحفظة، سواء كنسبة مئوية (%) أو مبلغ ثابت.',
                    'icon': Icons.auto_awesome_rounded,
                    'color': Colors.amber,
                  },
                  {
                    'title': 'تعدد العملات',
                    'description':
                        'ادخر بأي عملة (USD, SYP, etc). عند السحب يمكنك التحويل بين العملات بسعر صرف لحظي.',
                    'icon': Icons.currency_exchange_rounded,
                    'color': AppColors.primary,
                  },
                  {
                    'title': 'عزل الأموال',
                    'description':
                        'الأموال في الخزنة لا تظهر في رصيد "المحفظة الذكية" لتجنب إنفاقها بالخطأ، مما يعزز ثقافة التوفير.',
                    'icon': Icons.security_rounded,
                    'color': AppColors.success,
                  },
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.pushSlideFade(
              VaultHistoryScreen(transactions: widget.transactions),
            ),
            tooltip: 'سجل الخزنة',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildBalanceCard(),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _buildActionButton(isDeposit: true)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _buildActionButton(isDeposit: false)),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _buildAutomationSettings(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _currentBalances[_displayCurrency] ?? 0.0;
    // العملات التي لها رصيد موجب
    final activeCurrencies = _currentBalances.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.textDark, AppColors.textDark.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            boxShadow: AppColors.mediumShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ScaleTransition(
                    scale: _bounceAnimation,
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white70,
                      size: AppDimensions.iconSM,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'الرصيد المدّخر',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  // مبدّل العملات — يظهر فقط إذا كان هناك أكثر من عملة
                  if (activeCurrencies.length > 1)
                    GestureDetector(
                      onTap: () {
                        final idx = activeCurrencies.indexOf(_displayCurrency);
                        final next =
                            activeCurrencies[(idx + 1) %
                                activeCurrencies.length];
                        setState(() => _displayCurrency = next);
                        _animateBalanceChange();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _displayCurrency,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.swap_horiz_rounded,
                              color: Colors.white70,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: AnimatedCurrencyCounter(
                  key: ValueKey(_displayCurrency),
                  value: balance,
                  currencySymbol: _sym(_displayCurrency),
                  textStyle: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.bold,
                  ),
                  duration: Duration(milliseconds: AppDimensions.durationSlow),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required bool isDeposit}) {
    return AnimatedButton(
      onPressed: () => isDeposit ? _showDepositDialog() : _showWithdrawDialog(),
      backgroundColor: isDeposit ? AppColors.success : AppColors.danger,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      elevation: AppDimensions.elevationSM,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDeposit
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: AppDimensions.iconMD,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            isDeposit ? 'إيداع' : 'سحب',
            style: AppTypography.button.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationSettings() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الادخار الآلي',
            style: AppTypography.h5.copyWith(fontWeight: AppTypography.bold),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'خصم تلقائي من الإيداعات بالليرة السورية',
            style: AppTypography.caption.copyWith(color: AppColors.textLight),
          ),
          Divider(height: AppSpacing.xl),
          SwitchListTile(
            title: Text(
              'تفعيل الادخار الآلي',
              style: AppTypography.body2Medium,
            ),
            value: _isAutoSaveEnabled,
            onChanged: (val) {
              setState(() => _isAutoSaveEnabled = val);
              _animateToggle();
              HapticFeedback.selectionClick();
            },
            activeColor: AppColors.primary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('نسبة %'),
                    value: true,
                    groupValue: _isAutoSavePercent,
                    onChanged: !_isAutoSaveEnabled
                        ? null
                        : (val) => setState(() => _isAutoSavePercent = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('مبلغ ثابت'),
                    value: false,
                    groupValue: _isAutoSavePercent,
                    onChanged: !_isAutoSaveEnabled
                        ? null
                        : (val) => setState(() => _isAutoSavePercent = val!),
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _autoSaveController,
            keyboardType: TextInputType.number,
            enabled: _isAutoSaveEnabled,
            decoration: InputDecoration(
              labelText: 'القيمة',
              suffixText: _isAutoSavePercent ? '%' : 'ل.س',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: () {
                final value = double.tryParse(_autoSaveController.text) ?? 0.0;
                widget.onSaveSettings(
                  _isAutoSaveEnabled,
                  _isAutoSavePercent,
                  value,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم حفظ إعدادات الخزنة',
                      style: AppTypography.body2.copyWith(color: Colors.white),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              elevation: AppDimensions.elevationSM,
              child: Center(
                child: Text(
                  'حفظ الإعدادات',
                  style: AppTypography.button.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
