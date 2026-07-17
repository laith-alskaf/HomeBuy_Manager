import 'package:flutter/material.dart';

class IconMapping {
  static const Map<String, IconData> icons = {
    'eco': Icons.eco_rounded,
    'egg': Icons.egg_rounded,
    'kitchen': Icons.kitchen_rounded,
    'restaurant': Icons.restaurant_menu_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'home': Icons.home_rounded,
    'clothing': Icons.checkroom_rounded,
    'health': Icons.medical_services_rounded,
    'transport': Icons.directions_car_rounded,
    'bills': Icons.receipt_long_rounded,
    'education': Icons.school_rounded,
    'personal': Icons.face_rounded,
    'other': Icons.shopping_bag_rounded,
    'offer': Icons.local_offer_outlined,
    'category': Icons.category_rounded,
    'star': Icons.star_rounded,
    'favorite': Icons.favorite_rounded,
    'work': Icons.work_rounded,
    'payments': Icons.payments_rounded,
    'bank': Icons.account_balance_rounded,
    'safety': Icons.health_and_safety_rounded,
    'fitness': Icons.fitness_center_rounded,
    'food': Icons.fastfood_rounded,
    'coffee': Icons.coffee_rounded,
    'pets': Icons.pets_rounded,
    'electric': Icons.electric_car_rounded,
    'build': Icons.build_rounded,
    'key': Icons.vpn_key_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
  };

  static String getIconId(IconData icon) {
    for (var entry in icons.entries) {
      if (entry.value.codePoint == icon.codePoint) {
        return entry.key;
      }
    }
    return 'category'; // Default
  }

  static IconData getIconData(String id) {
    return icons[id] ?? Icons.category_rounded;
  }
}
