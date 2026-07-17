import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // --- UI Notifications (Snackbars) ---
  void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.green);
  }

  void showError(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.redAccent);
  }

  void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.blueAccent);
  }

  void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.orangeAccent);
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
