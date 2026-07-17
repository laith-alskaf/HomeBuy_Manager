import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  static const String _budgetKey = 'monthly_category_budgets';

  // تخزين الحدود: Key = "yyyy-MM", Value = Map<CategoryID, Limit>
  Map<String, Map<String, double>> _monthlyBudgets = {};

  factory BudgetService() => _instance;
  BudgetService._internal();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_budgetKey);
    if (data != null) {
      try {
        Map<String, dynamic> decoded = jsonDecode(data);
        _monthlyBudgets = decoded.map((monthKey, categoryMap) {
          final Map<String, dynamic> catMapDyn = categoryMap as Map<String, dynamic>;
          final Map<String, double> catMapDouble = catMapDyn.map((k, v) => MapEntry(k, (v as num).toDouble()));
          return MapEntry(monthKey, catMapDouble);
        });
      } catch (e) {
        _monthlyBudgets = {};
      }
    }
  }

  String _getMonthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

  /// جلب حد الميزانية لشهر معين
  double getLimit(String categoryId, {DateTime? date}) {
    final key = _getMonthKey(date ?? DateTime.now());
    return _monthlyBudgets[key]?[categoryId] ?? 0.0;
  }

  /// جلب آخر ميزانية تم تعيينها لهذه الفئة (من الشهر الحالي أو أشهر سابقة)
  /// يستخدم هذا لتعبئة الحقول تلقائياً
  double getLatestBudgetForCategory(String categoryId) {
    // 1. التحقق من الشهر الحالي
    final currentKey = _getMonthKey(DateTime.now());
    // التحقق من وجود المفتاح بدلاً من القيمة > 0 لضمان عرض القيمة الصحيحة حتى لو أصبحت 0
    if (_monthlyBudgets[currentKey]?.containsKey(categoryId) ?? false) {
      return _monthlyBudgets[currentKey]![categoryId]!;
    }

    // 2. البحث في الأشهر السابقة (ترتيب تنازلي)
    final sortedKeys = _monthlyBudgets.keys.toList()..sort((a, b) => b.compareTo(a));
    for (var key in sortedKeys) {
      if ((_monthlyBudgets[key]?[categoryId] ?? 0) > 0) {
        return _monthlyBudgets[key]![categoryId]!;
      }
    }
    return 0.0;
  }

  Future<void> setLimit(String categoryId, double amount, {DateTime? date}) async {
    final key = _getMonthKey(date ?? DateTime.now());
    if (!_monthlyBudgets.containsKey(key)) {
      _monthlyBudgets[key] = {};
    }
    _monthlyBudgets[key]![categoryId] = amount;
    await _saveData();
  }

  /// نقل ميزانية من فئة لأخرى
  Future<void> transferBudget(String fromCategory, String toCategory, double amount) async {
    final now = DateTime.now();
    final fromLimit = getLimit(fromCategory, date: now);
    final toLimit = getLimit(toCategory, date: now);

    await setLimit(fromCategory, (fromLimit - amount).clamp(0.0, double.infinity), date: now);
    await setLimit(toCategory, toLimit + amount, date: now);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_budgetKey, jsonEncode(_monthlyBudgets));
  }
}