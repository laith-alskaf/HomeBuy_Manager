import 'package:homebuy_manager/data/models/debt_record.dart';
import 'package:homebuy_manager/data/models/shopping_item.dart';
import 'package:homebuy_manager/data/models/wallet_transaction.dart';
import 'package:homebuy_manager/data/models/side_balance_transaction.dart';
import 'package:homebuy_manager/services/budget_service.dart';

class ProcessedAnalyticsReport {
  // Liquidity
  final double rolloverBalance;
  final double newIncome;
  final double totalAvailable;

  // Net Worth
  final double netWorth;
  final double totalAssets;
  final double sideBalance;

  // Expenses
  final Map<String, double> expenseDistribution;
  final Map<int, double> spendingHeatmap;

  // Budget
  final List<BudgetSaturation> budgetSaturation;

  // Insights
  final String financialInsight;

  // Cash Flow
  final double totalIncome;
  final double totalExpenses;
  final double vaultSavings;
  final double netCashFlow;

  ProcessedAnalyticsReport({
    required this.rolloverBalance,
    required this.newIncome,
    required this.totalAvailable,
    required this.netWorth,
    required this.totalAssets,
    required this.sideBalance,
    required this.expenseDistribution,
    required this.spendingHeatmap,
    required this.budgetSaturation,
    required this.financialInsight,
    required this.totalIncome,
    required this.totalExpenses,
    required this.vaultSavings,
    required this.netCashFlow,
  });
}

class BudgetSaturation {
  final String categoryId;
  final double limit;
  final double spent;
  double get progress => (limit > 0) ? (spent / limit) : 0.0;

  BudgetSaturation({
    required this.categoryId,
    required this.limit,
    required this.spent,
  });
}

class AnalyticsProcessor {
  final List<WalletTransaction> allDeposits;
  final List<ShoppingItem> allItems;
  final List<DebtRecord> allDebts;
  final List<SideBalanceTransaction> allSideBalanceTransactions;
  final Map<String, double> vaultBalancesByCurrency;
  final BudgetService budgetService;
  final String targetCurrency;

  AnalyticsProcessor({
    required this.allDeposits,
    required this.allItems,
    required this.allDebts,
    required this.allSideBalanceTransactions,
    required this.vaultBalancesByCurrency,
    required this.budgetService,
    required this.targetCurrency,
  });

  ProcessedAnalyticsReport process({required String timeFilter}) {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (timeFilter) {
      case 'last_month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'all_time':
        startDate = DateTime(2000);
        break;
      case 'this_month':
      default:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }

    // --- 0. Filter by targetCurrency ---
    final targetDeposits = allDeposits
        .where((t) => t.currency == targetCurrency)
        .toList();
    final targetItems = allItems
        .where((i) => i.currency == targetCurrency)
        .toList();
    final targetDebts = allDebts
        .where((d) => d.currency == targetCurrency)
        .toList();
    final currentVaultBalance = vaultBalancesByCurrency[targetCurrency] ?? 0.0;

    // --- 1. Liquidity Analysis (Rollover Logic) ---
    final priorDeposits = targetDeposits.where(
      (t) => t.date.isBefore(startDate),
    );
    final priorExpenses = targetItems.where(
      (i) => i.isBought && i.dateBought!.isBefore(startDate),
    );

    final rolloverBalance =
        priorDeposits.fold(0.0, (sum, t) => sum + t.amount) -
        priorExpenses.fold(0.0, (sum, i) => sum + (i.price * i.quantity));

    final newIncome = targetDeposits
        .where(
          (t) =>
              t.date.isAfter(startDate) &&
              t.date.isBefore(endDate) &&
              t.amount > 0,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalAvailable = rolloverBalance + newIncome;

    // --- 2. Net Worth ---
    final walletBalance =
        targetDeposits.fold(0.0, (sum, t) => sum + t.amount) -
        targetItems
            .where((i) => i.isBought)
            .fold(0.0, (sum, i) => sum + (i.price * i.quantity));

    final totalAssets = targetDebts
        .where((d) => d.type == DebtType.asset)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
    final totalLiabilities = targetDebts
        .where((d) => d.type == DebtType.liability)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);

    final currentSideBalance = allSideBalanceTransactions
        .where((t) => t.currency == targetCurrency)
        .fold(0.0, (sum, t) => sum + (t.type == SideBalanceType.deposit ? t.amount : -t.amount));

    final netWorth =
        (walletBalance + currentVaultBalance + currentSideBalance + totalAssets) - totalLiabilities;

    // --- 3. Filtered Expenses for Charts ---
    final filteredExpenses = targetItems.where(
      (i) =>
          i.isBought &&
          i.dateBought!.isAfter(startDate) &&
          i.dateBought!.isBefore(endDate),
    );

    // Pie Chart Data
    final Map<String, double> expenseDistribution = {};
    for (var item in filteredExpenses) {
      final cost = item.price * item.quantity;
      expenseDistribution[item.category] =
          (expenseDistribution[item.category] ?? 0) + cost;
    }

    // Heatmap Data
    final Map<int, double> spendingHeatmap = {};
    for (var item in filteredExpenses) {
      final day = item.dateBought!.day;
      final cost = item.price * item.quantity;
      spendingHeatmap[day] = (spendingHeatmap[day] ?? 0) + cost;
    }

    // --- 4. Budget Saturation ---
    final budgetDate = (timeFilter == 'last_month') ? startDate : now;
    final categoryKeys = expenseDistribution.keys;
    final List<BudgetSaturation> budgetSaturation = [];

    for (var catKey in categoryKeys) {
      final limit = budgetService.getLimit(catKey, date: budgetDate);
      if (limit > 0) {
        // We need to calculate spending for the *entire* month of the budget, not just the filtered period
        final monthStartDate = DateTime(budgetDate.year, budgetDate.month, 1);
        final monthEndDate = DateTime(
          budgetDate.year,
          budgetDate.month + 1,
          0,
          23,
          59,
          59,
        );

        final monthlySpent = targetItems
            .where(
              (i) =>
                  i.isBought &&
                  i.category == catKey &&
                  i.dateBought!.isAfter(monthStartDate) &&
                  i.dateBought!.isBefore(monthEndDate),
            )
            .fold(0.0, (sum, i) => sum + (i.price * i.quantity));

        budgetSaturation.add(
          BudgetSaturation(
            categoryId: catKey,
            limit: limit,
            spent: monthlySpent,
          ),
        );
      }
    }
    // Sort by most saturated
    budgetSaturation.sort((a, b) => b.progress.compareTo(a.progress));

    // --- 5. Financial Insights ---
    String insight = "لا توجد بيانات كافية لتقديم نصيحة دقيقة.";
    if (totalAvailable > 0) {
      final totalSpent = filteredExpenses.fold(
        0.0,
        (sum, i) => sum + (i.price * i.quantity),
      );
      final usageRatio = totalSpent / totalAvailable;

      if (usageRatio >= 0.9) {
        insight =
            "تحذير: لقد استهلكت تقريباً كامل رصيدك المتاح (${(usageRatio * 100).toStringAsFixed(0)}%)! يُرجى الانتباه للمصروفات הקادمة.";
      } else if (usageRatio >= 0.7) {
        insight =
            "تنبيه: مصروفك مرتفع نسبياً. استهلكت ${(usageRatio * 100).toStringAsFixed(0)}% من الرصيد.";
      } else if (usageRatio >= 0.4) {
        insight =
            "وضعك المالي مستقر. نسبة الصرف ${(usageRatio * 100).toStringAsFixed(0)}% من الرصيد المتاح.";
      } else if (usageRatio > 0.0) {
        insight =
            "ممتاز! معدل صرفك منخفض جداً (${(usageRatio * 100).toStringAsFixed(0)}%) وميزانيتك في حالة صحية رائعة.";
      } else {
        insight = "تحياتي! لم تقم بأي مصروفات في هذه الفترة.";
      }
    } else if (netWorth < 0) {
      insight =
          "تحذير: صافي ثروتك بالسالب بسبب الديون التي تتجاوز الأصول المتاحة. خطط للسداد قريباً.";
    } else if (totalAvailable == 0 && newIncome == 0 && rolloverBalance == 0) {
      insight = "رصيدك المتاح صفر. قم بإضافة إيداع جديد للبدء بإدارة أموالك.";
    }

    // --- 6. Cash Flow Calculation (In-Period) ---
    final periodIncome = targetDeposits
        .where((t) => t.date.isAfter(startDate) && t.date.isBefore(endDate))
        .fold(0.0, (sum, t) => sum + (t.amount > 0 ? t.amount : 0));
    
    final periodExpenses = filteredExpenses.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
    
    // Vault Savings in period (Net deposits to vault)
    final vaultSavings = vaultBalancesByCurrency[targetCurrency] ?? 0.0; // Simplified to current balance for now, but in a real scenario we'd track period delta.
    // Let's assume net cash flow is income - expenses
    final netCashFlow = periodIncome - periodExpenses;

    return ProcessedAnalyticsReport(
      rolloverBalance: rolloverBalance,
      newIncome: newIncome,
      totalAvailable: totalAvailable,
      netWorth: netWorth,
      totalAssets: totalAssets,
      sideBalance: currentSideBalance,
      expenseDistribution: expenseDistribution,
      spendingHeatmap: spendingHeatmap,
      budgetSaturation: budgetSaturation,
      financialInsight: insight,
      totalIncome: periodIncome,
      totalExpenses: periodExpenses,
      vaultSavings: vaultSavings,
      netCashFlow: netCashFlow,
    );
  }

  static List<MapEntry<String, double>> processPieChartData(
    Map<String, double> distribution,
  ) {
    if (distribution.isEmpty) return [];

    var sortedItems = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedItems.length > 5) {
      final top5 = sortedItems.take(5).toList();
      final othersValue = sortedItems
          .skip(5)
          .fold(0.0, (sum, item) => sum + item.value);

      // التأكد من أن "أخرى" لها قيمة قبل إضافتها
      if (othersValue > 0) {
        return [...top5, MapEntry('other', othersValue)];
      } else {
        return top5;
      }
    }
    return sortedItems;
  }
}
