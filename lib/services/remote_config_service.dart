import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults({
        'min_app_version': '1.0.0',
        'latest_app_version': '1.0.0',
        'force_update': false,
        'new_features': '[]',
        'announcement_json':
            '{"active": false, "id": "", "title": "", "message": "", "type": "info"}',
        'survey_json':
            '{"active": false, "id": "", "question": "", "option1_text": "", "option2_text": ""}',
      });

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 10)
              : const Duration(hours: 1),
        ),
      );

      await fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config Initialization Error: $e');
    }
  }

  Future<bool> fetchAndActivate() async {
    try {
      final success = await _remoteConfig.fetchAndActivate();
      if (success) {
        debugPrint('Remote Config: Fetched and Activated successfully');
      } else {
        debugPrint('Remote Config: Use cached values (no server changes)');
      }
      return success;
    } catch (e) {
      debugPrint('Remote Config Fetch Error: $e');
      
      // Attempt generic retry after 2 seconds if it's an internal error
      if (e.toString().contains('internal')) {
        await Future.delayed(const Duration(seconds: 2));
        try {
          return await _remoteConfig.fetchAndActivate();
        } catch (retryError) {
          debugPrint('Remote Config Retry Failed: $retryError');
        }
      }
      return false;
    }
  }

  Future<String?> forceFetchAndActivate() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: Duration.zero,
        ),
      );

      // Ignoring return value of fetchAndActivate because false only means
      // no changes, not necessarily a failure.
      await _remoteConfig.fetchAndActivate();

      // Reset settings back to default after force fetch
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 10)
              : const Duration(hours: 1),
        ),
      );

      return null;
    } catch (e, stackTrace) {
      debugPrint('Remote Config Force Fetch Error: $e');
      debugPrint('Stack Trace: $stackTrace');

      // Return a user-friendly error message if it's a known error
      if (e.toString().contains('network_error')) {
        return 'عذراً، تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت.';
      }
      return 'حدث خطأ غير متوقع: ${e.toString()}';
    }
  }

  String get minAppVersion => _remoteConfig.getString('min_app_version');
  String get latestAppVersion => _remoteConfig.getString('latest_app_version');
  bool get forceUpdate => _remoteConfig.getBool('force_update');

  List<String> get newFeatures {
    try {
      final jsonStr = _remoteConfig.getString('new_features');
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error parsing new_features JSON: $e');
      return [];
    }
  }

  Map<String, dynamic>? get announcement {
    try {
      final jsonStr = _remoteConfig.getString('announcement_json');
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded['active'] == true ? decoded : null;
    } catch (e) {
      debugPrint('Error parsing announcement_json: $e');
      return null;
    }
  }

  Map<String, dynamic>? get survey {
    try {
      final jsonStr = _remoteConfig.getString('survey_json');
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded['active'] == true ? decoded : null;
    } catch (e) {
      debugPrint('Error parsing survey_json: $e');
      return null;
    }
  }
}
