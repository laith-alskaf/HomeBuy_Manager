import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_item.dart';
import '../models/wallet_transaction.dart';
import '../models/price_history.dart';
import '../models/vault_transaction.dart';
import '../models/debt_record.dart';
import '../models/side_balance_transaction.dart';
import '../models/fixed_bill.dart';
import '../models/savings_goal.dart';

class LocalStorageService {
  static const String _shoppingListKey = 'shopping_list';
  static const String _walletDepositsKey = 'wallet_deposits';
  static const String _priceHistoryKey = 'price_history';
  static const String _vaultTransactionsKey = 'vault_transactions';
  static const String _debtsKey = 'debts_records';
  static const String _sideBalanceKey = 'side_balance_transactions';
  static const String _fixedBillsKey = 'fixed_bills';
  static const String _savingsGoalsKey = 'savings_goals';

  Future<void> saveShoppingList(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toMap()).toList());
    await prefs.setString(_shoppingListKey, encoded);
  }

  Future<List<ShoppingItem>> loadShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsString = prefs.getString(_shoppingListKey);

    if (itemsString == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(itemsString);
    return decoded.map((e) => ShoppingItem.fromMap(e)).toList();
  }

  Future<void> saveWalletTransactions(
    List<WalletTransaction> transactions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(transactions.map((e) => e.toMap()).toList());
    await prefs.setString(_walletDepositsKey, encoded);
  }

  Future<List<WalletTransaction>> loadWalletTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsString = prefs.getString(_walletDepositsKey);

    if (transactionsString == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(transactionsString);
    return decoded.map((e) => WalletTransaction.fromMap(e)).toList();
  }

  Future<void> savePriceHistory(List<PriceHistory> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history.map((e) => e.toMap()).toList());
    await prefs.setString(_priceHistoryKey, encoded);
  }

  Future<List<PriceHistory>> loadPriceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_priceHistoryKey);

    if (historyString == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(historyString);
    return decoded.map((e) => PriceHistory.fromMap(e)).toList();
  }

  // --- Vault Methods ---
  Future<void> saveVaultTransactions(
    List<VaultTransaction> transactions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(transactions.map((e) => e.toMap()).toList());
    await prefs.setString(_vaultTransactionsKey, encoded);
  }

  Future<List<VaultTransaction>> loadVaultTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_vaultTransactionsKey);
    if (data == null) return [];
    return (jsonDecode(data) as List)
        .map((e) => VaultTransaction.fromMap(e))
        .toList();
  }

  // --- Debt Methods ---
  Future<void> saveDebts(List<DebtRecord> debts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(debts.map((e) => e.toMap()).toList());
    await prefs.setString(_debtsKey, encoded);
  }

  Future<List<DebtRecord>> loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_debtsKey);
    if (data == null) return [];
    return (jsonDecode(data) as List)
        .map((e) => DebtRecord.fromMap(e))
        .toList();
  }

  // --- Side Balance Methods ---
  Future<void> saveSideBalanceTransactions(
    List<SideBalanceTransaction> transactions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(transactions.map((e) => e.toMap()).toList());
    await prefs.setString(_sideBalanceKey, encoded);
  }

  Future<List<SideBalanceTransaction>> loadSideBalanceTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_sideBalanceKey);
    if (data == null) return [];
    return (jsonDecode(data) as List)
        .map((e) => SideBalanceTransaction.fromMap(e))
        .toList();
  }

  // --- Fixed Bills Methods ---
  Future<void> saveFixedBills(List<FixedBill> bills) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(bills.map((e) => e.toMap()).toList());
    await prefs.setString(_fixedBillsKey, encoded);
  }

  Future<List<FixedBill>> loadFixedBills() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_fixedBillsKey);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((e) => FixedBill.fromMap(e)).toList();
  }

  // --- Savings Goals Methods ---
  Future<void> saveSavingsGoals(List<SavingsGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(goals.map((e) => e.toMap()).toList());
    await prefs.setString(_savingsGoalsKey, encoded);
  }

  Future<List<SavingsGoal>> loadSavingsGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_savingsGoalsKey);
    if (data == null) return [];
    return (jsonDecode(data) as List)
        .map((e) => SavingsGoal.fromMap(e))
        .toList();
  }
}
