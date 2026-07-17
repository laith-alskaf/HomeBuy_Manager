import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

// Config
import 'config/app_theme.dart';

// Services
import 'services/categories_service.dart';
import 'services/backup_service.dart';
import 'services/remote_config_service.dart';
import 'services/firebase_notification_service.dart';

// Presentation
import 'presentation/pages/home_page.dart';
import 'presentation/pages/landing_screen.dart';
import 'presentation/widgets/update_helper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize date formatting for Arabic
    await initializeDateFormatting('ar', null);

    // 1. Initialize Firebase with specific options for reliability
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. تشغيل الخدمات الجانبية في الخلفية دون تعطيل الإقلاع (Non-Blocking)
    Future.microtask(() async {
      try {
        await Future.wait([
          FirebaseNotificationService().initialize(),
          RemoteConfigService().initialize(),
          PackageInfo.fromPlatform(),
        ]);
      } catch (e) {
        debugPrint('Background Services Error: $e');
      }
    });

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
    );
  } catch (e) {
    debugPrint('CRITICAL STARTUP ERROR: $e');
  } finally {
    // ALWAYS run the app, even if some initializations fail
    runApp(const ShoppingApp());
  }
}

class ShoppingApp extends StatefulWidget {
  const ShoppingApp({super.key});

  @override
  State<ShoppingApp> createState() => _ShoppingAppState();
}

class _ShoppingAppState extends State<ShoppingApp> {
  late final Future<bool> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp();
  }

  Future<bool> _initializeApp() async {
    try {
      // تحميل الأقسام الضرورية للواجهة
      await CategoriesService().initialize();

      // تشغيل النسخ الاحتياطي في الخلفية دون تأخير دخول المستخدم
      Future.microtask(() {
        BackupService().performAutoBackupIfNeeded().catchError((e) {
          debugPrint("Auto Backup Error: $e");
        });
      });

      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name') ?? '';
      if (savedName.isNotEmpty) {
        // Analytics removed
      }
      return prefs.getBool('has_seen_landing') ?? false;
    } catch (e) {
      debugPrint("Initialization Error: $e");
      return false;
    }
  }

  Future<void> _completeOnboarding(BuildContext validContext) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_landing', true);

    if (!mounted) return;

    // Use a direct state update if we were on the same navigator,
    // but since we want a transition, pushReplacement is fine.
    Navigator.of(validContext).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رادار المصروف',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'SY')],
      locale: const Locale('ar', 'SY'),
      theme: AppTheme.lightTheme,
      home: FutureBuilder<bool>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildSplashScreenBody();
          }

          final hasSeenLanding = snapshot.data ?? false;

          if (hasSeenLanding) {
            return const UpdateHelper(child: HomePage());
          } else {
            return Builder(
              builder: (innerContext) {
                return LandingScreen(
                  onStart: () => _completeOnboarding(innerContext),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildSplashScreenBody() {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: const Icon(
                Icons.shopping_cart_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white.withOpacity(0.9),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
