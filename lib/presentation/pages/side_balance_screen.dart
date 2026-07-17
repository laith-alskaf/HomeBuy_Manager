import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../data/models/side_balance_transaction.dart';
import '../../utils/formatters.dart';
import '../widgets/common/animated_counter.dart';
import '../widgets/common/app_info_dialog.dart';

class SideBalanceScreen extends StatefulWidget {
  final List<SideBalanceTransaction> transactions;
  final Function(double, String, String, SideBalanceType) onTransaction;
  final Function(
    SideBalanceTransaction,
    double,
    String,
    String,
    SideBalanceType,
  )?
  onEditTransaction;
  final Function(String)? onDeleteTransaction;
  final Function(double, String, String)? onTransferToWallet;

  const SideBalanceScreen({
    super.key,
    required this.transactions,
    required this.onTransaction,
    this.onEditTransaction,
    this.onDeleteTransaction,
    this.onTransferToWallet,
  });

  @override
  State<SideBalanceScreen> createState() => _SideBalanceScreenState();
}

class _SideBalanceScreenState extends State<SideBalanceScreen> {
  String _searchQuery = '';

  // تجميع الأرصدة حسب العملة
  Map<String, double> get _balancesByCurrency {
    final Map<String, double> balances = {};
    for (var t in widget.transactions) {
      if (!balances.containsKey(t.currency)) {
        balances[t.currency] = 0.0;
      }
      if (t.type == SideBalanceType.deposit) {
        balances[t.currency] = balances[t.currency]! + t.amount;
      } else {
        balances[t.currency] = balances[t.currency]! - t.amount;
      }
    }
    return balances;
  }

  void _showTransactionDialog({required bool isDeposit}) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCurrency = 'USD';
    final List<String> currencies = ['USD', 'EUR', 'SYP', 'SAR', 'AED'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              isDeposit ? 'إيداع رصيد جانبي' : 'سحب رصيد جانبي',
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: InputDecoration(
                      labelText: 'العملة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    items: currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setStateDialog(() => selectedCurrency = val);
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      suffixText: selectedCurrency,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'ملاحظة (اختياري)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
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
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (amount > 0) {
                    final type = isDeposit
                        ? SideBalanceType.deposit
                        : SideBalanceType.withdraw;

                    // التحقق من أن الرصيد يكفي في حالة السحب
                    if (type == SideBalanceType.withdraw) {
                      final currentBal =
                          _balancesByCurrency[selectedCurrency] ?? 0.0;
                      if (amount > currentBal) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('الرصيد غير كافٍ لهذه العملة'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    widget.onTransaction(
                      amount,
                      selectedCurrency,
                      noteController.text,
                      type,
                    );
                    setState(() {});
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDeposit
                      ? AppColors.success
                      : AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('تنفيذ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteTransaction(SideBalanceTransaction t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف هذه الحركة؟ قد يؤثر ذلك على أرصدتك الحالية.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (t.type == SideBalanceType.deposit) {
                final currentBal = _balancesByCurrency[t.currency] ?? 0.0;
                if (currentBal - t.amount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'لا يمكن التراجع عن هذا الإيداع لأن الرصيد سيصبح سالباً',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(ctx);
                  return;
                }
              }
              if (widget.onDeleteTransaction != null) {
                widget.onDeleteTransaction!(t.id);

                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(SideBalanceTransaction t) {
    if (widget.onEditTransaction == null) return;

    final amountController = TextEditingController(text: t.amount.toString());
    final noteController = TextEditingController(text: t.note);
    String selectedCurrency = t.currency;
    final List<String> currencies = ['USD', 'EUR', 'SYP', 'SAR', 'AED'];
    bool isDeposit = t.type == SideBalanceType.deposit;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'تعديل الحركة',
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text(
                            'إيداع',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: true,
                          groupValue: isDeposit,
                          onChanged: (val) =>
                              setStateDialog(() => isDeposit = val!),
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.success,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text(
                            'سحب',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: false,
                          groupValue: isDeposit,
                          onChanged: (val) =>
                              setStateDialog(() => isDeposit = val!),
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: InputDecoration(
                      labelText: 'العملة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    items: currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setStateDialog(() => selectedCurrency = val);
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      suffixText: selectedCurrency,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'ملاحظة (اختياري)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
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
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (amount > 0) {
                    final newType = isDeposit
                        ? SideBalanceType.deposit
                        : SideBalanceType.withdraw;

                    // Validation for withdraw editing or changing from deposit to withdraw
                    double currentBal =
                        _balancesByCurrency[selectedCurrency] ?? 0.0;

                    // Calculate what the balance WOULD be if we remove the OLD transaction
                    if (t.currency == selectedCurrency) {
                      if (t.type == SideBalanceType.deposit) {
                        currentBal -= t.amount;
                      } else {
                        currentBal += t.amount;
                      }
                    }

                    // Check if new transaction makes it invalid
                    if (newType == SideBalanceType.withdraw) {
                      if (amount > currentBal) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'الرصيد غير كافٍ لهذه العملة بعد التعديل',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    } else if (newType == SideBalanceType.deposit) {
                      // Even for deposit, if we removed the OLD deposit and balance became negative...
                      if (currentBal + amount < 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'لا يمكن تقليل هذا الإيداع، الرصيد سيصبح سالباً',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    widget.onEditTransaction!(
                      t,
                      amount,
                      selectedCurrency,
                      noteController.text,
                      newType,
                    );
                    setState(() {});
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('التعديلات'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balances = _balancesByCurrency;
    // التأكد من وجود عملات لعرضها، وإلا نعرض USD كافتراضي بصفر
    if (balances.isEmpty) balances['USD'] = 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'الرصيد الجانبي',
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
                title: 'الرصيد الجانبي (Side Balance)',
                description:
                    'محفظتك الاستثمارية المستقلة، المصممة لعزل مدخراتك وأرصدتك بالعملات المختلفة عن استهلاكك اليومي.',
                features: [
                  {
                    'title': 'تعدد العملات',
                    'description':
                        'ادعم مدخراتك بكل العملات (USD, EUR, SYP, etc) في مكان واحد منظم ومحمي.',
                    'icon': Icons.currency_exchange_rounded,
                    'color': AppColors.primary,
                  },
                  {
                    'description':
                        'تعمل كمحفظة منفصلة كلياً عن محفظة المصروف الرئيسية، مفيدة للمبالغ الكبيرة والأعمال الحرة.',
                    'icon': Icons.bar_chart_rounded,
                    'color': AppColors.success,
                  },
                  {
                    'title': 'إدارة وتحكم مرن',
                    'description':
                        'تراجع أو عدّل أي عملية بنقرة على القائمة الجانبية لكل حركة، التطبيق يمنع الأرصدة السالبة تلقائياً.',
                    'icon': Icons.edit_note_rounded,
                    'color': Colors.blueGrey,
                  },
                  {
                    'title': 'البحث الفوري الذكي',
                    'description':
                        'ابحث عن أي عملية سابقة بمجرد كتابة العملة أو جزء من الملاحظة في شريط البحث.',
                    'icon': Icons.search_rounded,
                    'color': Colors.teal,
                  },
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'محفظتك الاستثمارية / الجانبية',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: balances.length,
                    itemBuilder: (context, index) {
                      final currency = balances.keys.elementAt(index);
                      final amount = balances[currency]!;
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(left: 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currency,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            AnimatedCurrencyCounter(
                              value: amount,
                              currencySymbol: '',
                              textStyle: AppTypography.h2.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showTransactionDialog(isDeposit: true),
                        icon: const Icon(Icons.arrow_upward_rounded),
                        label: const Text('إيداع'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showTransactionDialog(isDeposit: false),
                        icon: const Icon(Icons.arrow_downward_rounded),
                        label: const Text('سحب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'البحث في العمليات (حسب العملة، الملاحظة)...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: widget.transactions.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد حركات سابقة',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final filteredList = widget.transactions
                          .where((t) {
                            final query = _searchQuery.toLowerCase();
                            return t.note.toLowerCase().contains(query) ||
                                t.currency.toLowerCase().contains(query) ||
                                t.amount.toString().contains(query);
                          })
                          .toList()
                          .reversed
                          .toList();

                      if (filteredList.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد نتائج مطابقة للبحث',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final t = filteredList[index];
                          final isDeposit = t.type == SideBalanceType.deposit;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDeposit
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.danger.withOpacity(0.1),
                                child: Icon(
                                  isDeposit
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: isDeposit
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                              title: Text(
                                t.note.isNotEmpty
                                    ? t.note
                                    : (isDeposit ? 'إيداع رصيد' : 'سحب رصيد'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${t.date.year}/${t.date.month}/${t.date.day}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${isDeposit ? '+' : '-'}${formatCompactCurrency(t.amount)} ${t.currency}',
                                    style: TextStyle(
                                      color: isDeposit
                                          ? AppColors.success
                                          : AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      color: Colors.grey,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditTransactionDialog(t);
                                      } else if (value == 'delete') {
                                        _confirmDeleteTransaction(t);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.edit_rounded,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'تعديل',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.delete_rounded,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'حذف',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
