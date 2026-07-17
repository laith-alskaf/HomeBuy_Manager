import 'dart:convert';
import 'package:homebuy_manager/utils/constants.dart' as constants;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/icon_mapping.dart';

class CategoriesService {
  static final CategoriesService _instance = CategoriesService._internal();

  static const String _categoriesKey = 'custom_categories';
  static const String _suggestedItemsKey = 'custom_suggested_items';

  Map<String, dynamic> _categories = Map.from(constants.categories);

  // FIX: Use List<String>.from(v) to explicitly create a list of strings.
  Map<String, List<String>> _suggestedItems = Map.from(
    constants.suggestedItems.map((k, v) => MapEntry(k, List<String>.from(v))),
  );

  factory CategoriesService() {
    return _instance;
  }

  CategoriesService._internal();

  Future<void> initialize() async {
    await _loadCustomData();
  }

  Future<void> _loadCustomData() async {
    final prefs = await SharedPreferences.getInstance();

    final categoriesJson = prefs.getString(_categoriesKey);
    if (categoriesJson != null) {
      try {
        final decoded = jsonDecode(categoriesJson) as Map<String, dynamic>;
        // دمج الفئات المخصصة المحفوظة مع الفئات الأساسية
        decoded.forEach((key, value) {
          _categories[key] = {
            'label': value['label'],
            'color': Color(value['color']), 
            'icon': IconMapping.getIconData(value['icon']), // Use IconMapping
          };
        });
      } catch (e) {
        _categories = Map.from(constants.categories);
      }
    }

    final suggestedItemsJson = prefs.getString(_suggestedItemsKey);
    if (suggestedItemsJson != null) {
      try {
        final decoded = jsonDecode(suggestedItemsJson) as Map<String, dynamic>;
        _suggestedItems = decoded.map(
          // This part was already correct in your code, but good to double-check
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        );
      } catch (e) {
        // FIX: Apply the same fix here for the fallback case
        _suggestedItems = Map.from(
          constants.suggestedItems.map(
            (k, v) => MapEntry(k, List<String>.from(v)),
          ),
        );
      }
    }
  }

  Future<void> _saveCustomData() async {
    final prefs = await SharedPreferences.getInstance();

    // تصفية وحفظ الفئات المخصصة فقط (التي تبدأ بـ custom_)
    // وتحويل الألوان والأيقونات إلى أرقام قابلة للحفظ في JSON
    final customCategories = Map<String, dynamic>.from(_categories)
      ..removeWhere((key, value) => !key.startsWith('custom_'));

    final encodedCategories = customCategories.map(
      (key, value) => MapEntry(key, {
        'label': value['label'],
        'color': (value['color'] as Color).value, 
        'icon': IconMapping.getIconId(value['icon'] as IconData), // Save as ID
      }),
    );

    await prefs.setString(_categoriesKey, jsonEncode(encodedCategories));

    final suggestedItemsJson = _suggestedItems.map((k, v) => MapEntry(k, v));
    await prefs.setString(_suggestedItemsKey, jsonEncode(suggestedItemsJson));
  }

  Map<String, dynamic> get categories => _categories;
  Map<String, List<String>> get suggestedItems => _suggestedItems;

  Future<void> addItemToCategory(String categoryId, String itemName) async {
    if (!_suggestedItems.containsKey(categoryId)) {
      _suggestedItems[categoryId] = [];
    }

    if (!_suggestedItems[categoryId]!.contains(itemName)) {
      _suggestedItems[categoryId]!.add(itemName);
      await _saveCustomData();
    }
  }

  Future<void> removeItemFromCategory(
    String categoryId,
    String itemName,
  ) async {
    if (_suggestedItems.containsKey(categoryId)) {
      _suggestedItems[categoryId]!.removeWhere((item) => item == itemName);
      await _saveCustomData();
    }
  }

  bool isItemInCategory(String categoryId, String itemName) {
    return _suggestedItems[categoryId]?.contains(itemName) ?? false;
  }

  List<String> getItemsByCategory(String categoryId) {
    return _suggestedItems[categoryId] ?? [];
  }

  void resetToDefault() {
    _categories = Map.from(constants.categories);
    // FIX: Apply the same fix here
    _suggestedItems = Map.from(
      constants.suggestedItems.map((k, v) => MapEntry(k, List<String>.from(v))),
    );
  }

  // إضافة فئة جديدة
  Future<void> addCustomCategory(
    String name,
    Color color,
    IconData icon,
  ) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    _categories[id] = {'label': name, 'color': color, 'icon': icon};
    // تهيئة قائمة مقترحات فارغة لها
    _suggestedItems[id] = [];
    await _saveCustomData();
  }

  // حذف فئة مخصصة
  Future<void> deleteCustomCategory(String id) async {
    if (_categories.containsKey(id)) {
      _categories.remove(id);
      _suggestedItems.remove(id);
      await _saveCustomData();
    }
  }
}
