import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/remote_config_service.dart';
import '../../services/firebase_notification_service.dart';
import '../dialogs/update_dialog.dart';
import '../dialogs/announcement_dialog.dart';
import '../dialogs/survey_dialog.dart';

class UpdateHelper extends StatefulWidget {
  final Widget child;

  const UpdateHelper({super.key, required this.child});

  @override
  State<UpdateHelper> createState() => _UpdateHelperState();
}

class _UpdateHelperState extends State<UpdateHelper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check for updates and announcements after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCheck();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh config and check when app is resumed
      RemoteConfigService().fetchAndActivate().then((_) {
        if (mounted) _initCheck();
      });
    }
  }

  Future<void> _initCheck() async {
    final updateShown = await _checkVersion();
    if (updateShown) return;

    final announcementShown = await _checkAnnouncement();
    if (announcementShown) return;

    await _checkSurvey();
  }

  Future<bool> _checkVersion() async {
    final remoteConfig = RemoteConfigService();
    final latestVersion = remoteConfig.latestAppVersion;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (_isUpdateAvailable(currentVersion, latestVersion)) {
      if (mounted) {
        final isForced = remoteConfig.forceUpdate;

        showDialog(
          context: context,
          barrierDismissible: !isForced,
          builder: (context) => UpdateDialog(
            version: latestVersion,
            downloadUrl: FirebaseNotificationService.updateUrl,
            isForceUpdate: isForced,
            newFeatures: remoteConfig.newFeatures,
          ),
        );
        return true;
      }
    }
    return false;
  }

  Future<bool> _checkAnnouncement() async {
    final remoteConfig = RemoteConfigService();
    final data = remoteConfig.announcement;

    if (data != null && data['active'] == true) {
      final id = data['id'] ?? '';
      if (id.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      final seenId = prefs.getString('last_announcement_id');

      if (seenId != id) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AnnouncementDialog(
              id: id,
              title: data['title'] ?? '',
              message: data['message'] ?? '',
              actionText: data['action_text'] ?? data['actionText'],
              actionUrl: data['action_url'] ?? data['actionUrl'],
              type: data['type'] ?? 'info',
            ),
          );
          // Mark as seen
          await prefs.setString('last_announcement_id', id);
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _checkSurvey() async {
    final remoteConfig = RemoteConfigService();
    final data = remoteConfig.survey;

    if (data != null && data['active'] == true) {
      final id = data['id'] ?? '';
      if (id.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final seenId = prefs.getString('last_survey_id');

      if (seenId != id) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => SurveyDialog(
              id: id,
              question: data['question'] ?? '',
              option1Text: data['option1_text'] ?? 'نعم',
              option2Text: data['option2_text'] ?? 'لا',
            ),
          );
          // Mark as seen
          await prefs.setString('last_survey_id', id);
        }
      }
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    try {
      final cleanCurrent = current.split('+')[0];
      final cleanLatest = latest.split('+')[0];

      List<int> currentParts = cleanCurrent.split('.').map(int.parse).toList();
      List<int> latestParts = cleanLatest.split('.').map(int.parse).toList();

      int length = latestParts.length > currentParts.length
          ? latestParts.length
          : currentParts.length;

      for (int i = 0; i < length; i++) {
        int v1 = i < currentParts.length ? currentParts[i] : 0;
        int v2 = i < latestParts.length ? latestParts[i] : 0;
        if (v2 > v1) return true;
        if (v2 < v1) return false;
      }
      return false;
    } catch (e) {
      return latest != current;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
