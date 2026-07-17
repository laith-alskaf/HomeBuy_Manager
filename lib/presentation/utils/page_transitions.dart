import 'package:flutter/material.dart';

/// انتقالات مخصصة بين الصفحات لجعل التطبيق أكثر سلاسة واحترافية
class PageTransitions {
  /// Slide from Right (الانزلاق من اليمين)
  static Route slideFromRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Slide from Left (الانزلاق من اليسار)
  static Route slideFromLeft(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Slide from Bottom (الانزلاق من الأسفل)
  static Route slideFromBottom(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Fade Transition (التلاشي)
  static Route fade(Widget page, {int durationMs = 400}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: durationMs),
    );
  }

  /// Scale Transition (التكبير)
  static Route scale(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;

        var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Slide + Fade (مزيج من الانزلاق والتلاشي)
  static Route slideFade(Widget page, {Offset begin = const Offset(0.3, 0.0)}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;

        var slideTween = Tween(begin: begin, end: Offset.zero).chain(
          CurveTween(curve: curve),
        );

        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

/// Extension methods لتسهيل الاستخدام
extension NavigatorExtensions on BuildContext {
  /// Push with slide from right
  Future<dynamic> pushSlideRight(Widget page) {
    return Navigator.of(this).push(
      PageTransitions.slideFromRight(page),
    );
  }

  /// Push with slide from left
  Future<dynamic> pushSlideLeft(Widget page) {
    return Navigator.of(this).push(
      PageTransitions.slideFromLeft(page),
    );
  }

  /// Push with slide from bottom
  Future<dynamic> pushSlideBottom(Widget page) {
    return Navigator.of(this).push(
      PageTransitions.slideFromBottom(page),
    );
  }

  /// Push with fade
  Future<dynamic> pushFade(Widget page, {int durationMs = 400}) {
    return Navigator.of(this).push(
      PageTransitions.fade(page, durationMs: durationMs),
    );
  }

  /// Push with scale
  Future<dynamic> pushScale(Widget page) {
    return Navigator.of(this).push(
      PageTransitions.scale(page),
    );
  }

  /// Push with slide + fade
  Future<dynamic> pushSlideFade(Widget page) {
    return Navigator.of(this).push(
      PageTransitions.slideFade(page),
    );
  }
}
