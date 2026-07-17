import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../config/app_typography.dart';
import '../../../config/app_dimensions.dart';
import 'package:intl/intl.dart';
import '../../../config/app_spacing.dart';
import 'animated_button.dart';

class CustomAppBar extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback? onInfoPressed;
  final String? userName;
  final VoidCallback? onNameTap;

  const CustomAppBar({
    super.key,
    required this.onMenuPressed,
    required this.onHistoryPressed,
    this.onInfoPressed,
    this.userName,
    this.onNameTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'أهلاً بك';
    return 'مساء الخير';
  }

  String _getArabicDate() {
    final now = DateTime.now();
    return DateFormat('EEEE، d MMMM', 'ar').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: AppDimensions.durationVerySlow),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  // 1. زر القائمة
                  AnimatedIconButton(
                    icon: Icons.grid_view_rounded,
                    onPressed: onMenuPressed,
                    color: Colors.white,
                    size: 24,
                    tooltip: 'القائمة',
                  ),

                  SizedBox(width: AppSpacing.sm),

                  // 2. النصوص والتلويح والتاريخ
                  Expanded(
                    child: InkWell(
                      onTap: onNameTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const _WavingHand(),
                              ],
                            ),
                            Text(
                              _getArabicDate(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            (userName != null && userName!.isNotEmpty)
                                ? Text(
                                    userName!,
                                    style: AppTypography.h5.copyWith(
                                      color: Colors.white,
                                      fontWeight: AppTypography.bold,
                                      fontSize: 18,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Row(
                                    children: [
                                      Text(
                                        "إضغط لإضافة اسمك",
                                        style: AppTypography.body1.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.edit_note_rounded,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. زر المعلومات
                  if (onInfoPressed != null) ...[
                    AnimatedIconButton(
                      icon: Icons.info_outline_rounded,
                      onPressed: onInfoPressed,
                      color: Colors.white,
                      size: 24,
                      tooltip: 'معلومات الصفحة',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],

                  // 5. زر السجل
                  AnimatedIconButton(
                    icon: Icons.history_rounded,
                    onPressed: onHistoryPressed,
                    color: Colors.white,
                    size: 24,
                    tooltip: 'السجل',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// ويدجت التلويح باليد (كما هي، فهي ممتازة)
// ---------------------------------------------------------
class _WavingHand extends StatefulWidget {
  const _WavingHand();

  @override
  State<_WavingHand> createState() => _WavingHandState();
}

class _WavingHandState extends State<_WavingHand>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: AppDimensions.durationMedium),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: -0.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _playAnimation();
  }

  Future<void> _playAnimation() async {
    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // تأخير بسيط لبدء الحركة
      for (int i = 0; i < 3; i++) {
        await _controller.forward();
        await _controller.reverse();
      }
      _controller.animateTo(0);
    } catch (e) {
      return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * math.pi,
          alignment: Alignment.bottomRight,
          child: child,
        );
      },
      child: const Text('👋', style: TextStyle(fontSize: 18)),
    );
  }
}
