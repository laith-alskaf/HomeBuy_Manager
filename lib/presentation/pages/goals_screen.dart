import 'package:flutter/material.dart';
import '../../data/models/savings_goal.dart';
import '../../data/models/wallet_transaction.dart';
import '../../data/services/local_storage_service.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../utils/formatters.dart';
import '../widgets/common/app_info_dialog.dart';

class GoalsScreen extends StatefulWidget {
  final Map<String, double> balancesByCurrency;

  const GoalsScreen({super.key, required this.balancesByCurrency});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final LocalStorageService _storageService = LocalStorageService();

  List<SavingsGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _goals = await _storageService.loadSavingsGoals();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGoals() async {
    await _storageService.saveSavingsGoals(_goals);
    setState(() {});
  }

  String _currencySymbol(String c) {
    switch (c) {
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
        return c;
    }
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCurrency = 'SYP';
    int selectedColor = Colors.teal.value;

    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.orange,
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة هدف جديد'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الهدف (مثال: سيارة جديدة)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'المبلغ المستهدف',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixText: _currencySymbol(selectedCurrency),
                  ),
                ),
                const SizedBox(height: 15),
                // اختيار العملة
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'عملة الهدف',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.payments_rounded),
                  ),
                  items: ['SYP', 'USD', 'EUR', 'AED', 'SAR']
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('$c (${_currencySymbol(c)})'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedCurrency = val!);
                  },
                ),
                const SizedBox(height: 15),
                const Text(
                  'اختر لون الهدف:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: colors.map((c) {
                    final isSelected = selectedColor == c.value;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedColor = c.value),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  amountController.text.isEmpty)
                return;
              final amount = double.tryParse(amountController.text) ?? 0.0;

              final newGoal = SavingsGoal(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                targetAmount: amount,
                currency: selectedCurrency,
                colorValue: selectedColor,
                iconName: 'savings',
              );

              _goals.add(newGoal);
              await _saveGoals();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'إنشاء الهدف',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFundsDialog(SavingsGoal goal) {
    final amountController = TextEditingController();
    bool deductFromWallet = true;
    final double available = widget.balancesByCurrency[goal.currency] ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تمويل: ${goal.name}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'المبلغ المضاف',
                    suffixText: _currencySymbol(goal.currency),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'خصم المبلغ من محفظتي المتاحة',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'رصيدك المتاح (${goal.currency}): ${formatCompactCurrency(available)}',
                    ),
                    value: deductFromWallet,
                    onChanged: (val) {
                      setDialogState(() => deductFromWallet = val ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(goal.colorValue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) return;

              if (deductFromWallet && amount > available) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرصيد في المحفظة غير كافٍ!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Update Goal
              final index = _goals.indexWhere((g) => g.id == goal.id);
              if (index != -1) {
                _goals[index] = _goals[index].copyWith(
                  currentAmount: _goals[index].currentAmount + amount,
                );
                await _saveGoals();

                if (deductFromWallet) {
                  // Deduct from wallet using WalletTransaction
                  final transactions = await _storageService
                      .loadWalletTransactions();
                  transactions.add(
                    WalletTransaction(
                      id: DateTime.now().toString(),
                      amount: -amount,
                      currency: goal.currency,
                      date: DateTime.now(),
                      note: 'تمويل هدف: ${goal.name}',
                    ),
                  );
                  await _storageService.saveWalletTransactions(transactions);
                }

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تمت إضافة ${formatCompactCurrency(amount)} ${_currencySymbol(goal.currency)} بنجاح لـ ${goal.name}',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'إضافة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteGoal(SavingsGoal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الهدف'),
        content: Text(
          'هل تريد المؤكد حذف هدف "${goal.name}"؟\nملاحظة: هذا لن يعيد الأموال لمحفظتك، بل يحذف الهدف البصري فقط.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _goals.removeWhere((g) => g.id == goal.id);
      await _saveGoals();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'حصّالة الأهداف',
          style: AppTypography.h5.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              AppInfoDialog.show(
                context,
                title: 'حصّالة الأهداف (Savings Goals)',
                description:
                    'لتحفيز ثقافة الادخار، صممنا لك هذه الحصّالات لتتبع أحلامك وطموحاتك المالية كسيارة جديدة أو جهاز أحلامك.',
                features: [
                  {
                    'title': 'التمويل من المحفظة',
                    'description':
                        'عند الإضافة للهدف، يمكنك اختيار سحب المبلغ مباشرة من رصيدك المتاح، لتكون ميزانيتك دقيقة دائماً.',
                    'icon': Icons.account_balance_wallet_rounded,
                    'color': AppColors.primary,
                  },
                  {
                    'title': 'التقدم البصري',
                    'description':
                        'تتفاعل الدائرة باللون الذهبي البراق وتكتمل مع تحقيقك للهدف بشكل مُرضي جداً.',
                    'icon': Icons.incomplete_circle_rounded,
                    'color': Colors.amber,
                  },
                  {
                    'title': 'حذف مرن',
                    'description':
                        'اضغط مطولاً على أي هدف لحذفه، وحذفه لن يؤثر على أموالك ومحفظتك إطلاقاً، فهو أداة تحفيزية فقط.',
                    'icon': Icons.delete_sweep_rounded,
                    'color': AppColors.danger,
                  },
                ],
              );
            },
          ),
        ],
      ),
      body: _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.track_changes_rounded,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'لا توجد أهداف للادخار حالياً',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ضع هدفاً وابدأ بتجميع الأموال له!',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final progress = goal.progressPercentage;
                final isCompleted = progress >= 1.0;
                final goalColor = Color(goal.colorValue);

                return InkWell(
                  onTap: () => isCompleted ? null : _showAddFundsDialog(goal),
                  onLongPress: () => _deleteGoal(goal),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, goalColor.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: goalColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isCompleted
                            ? Colors.amber.withOpacity(0.8)
                            : goalColor.withOpacity(0.2),
                        width: isCompleted ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 8,
                                backgroundColor: goalColor.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCompleted ? Colors.amber : goalColor,
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Icon(
                              isCompleted
                                  ? Icons.emoji_events_rounded
                                  : Icons.savings_outlined,
                              color: isCompleted ? Colors.amber : goalColor,
                              size: 35,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          goal.name,
                          style: AppTypography.body1Medium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${formatCompactCurrency(goal.currentAmount)} / ${formatCompactCurrency(goal.targetAmount)} ${_currencySymbol(goal.currency)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isCompleted
                                ? Colors.amber.shade700
                                : goalColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'هدف جديد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
