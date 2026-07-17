import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_dimensions.dart';
import '../../config/app_spacing.dart';
import '../widgets/common/animated_button.dart';

class OnboardingFeature {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final List<String> highlights;

  OnboardingFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.highlights,
  });
}

class LandingScreen extends StatefulWidget {
  final VoidCallback onStart;

  const LandingScreen({super.key, required this.onStart});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  int _currentPage = 0;

  final List<OnboardingFeature> features = [
    OnboardingFeature(
      title: '💳 إدارة المحفظة المتعددة العملات',
      description: 'تحكم كامل بأموالك بكل العملات (ل.س، \$، والمزيد)',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AppColors.primary,
      highlights: [
        'دعم كامل للعملات العالمية',
        'عرض الرصيد المتاح بدقة (مدور + جاري)',
        'تحويل فوري وسلس بين العملات',
        'تتبع تضخم مصروفك اليومي',
      ],
    ),
    OnboardingFeature(
      title: '📅 الالتزامات والدورة المالية',
      description: 'نظم فواتيرك واشتراكاتك بدقة واحترافية',
      icon: Icons.receipt_long_rounded,
      iconColor: AppColors.warning,
      highlights: [
        'دعم التوقيت (شهري، أسبوعي، يومي)',
        'دفع فوري بضغطة واحدة من المحفظة',
        'تنبيهات ذكية عند اقتراب السداد',
        'مزامنة مع رصيد الدورة الحالية',
      ],
    ),
    OnboardingFeature(
      title: '🎯 حصّالة الأهداف الذكية',
      description: 'خطط لأحلامك بكل العملات وحققها',
      icon: Icons.track_changes_rounded,
      iconColor: Colors.amber,
      highlights: [
        'تمويل الأهداف مباشرة من المحفظة',
        'دعم العملات المختلفة لكل هدف',
        'مؤشر تقدم بصري ذهبي باهر',
        'ملمس وتفاعلات بصرية مميزة',
      ],
    ),
    OnboardingFeature(
      title: '💼 رصيد الاستثمار الجانبي',
      description: 'اعزل أموالك الحرة عن استهلاكك اليومي',
      icon: Icons.currency_exchange_rounded,
      iconColor: Colors.purple,
      highlights: [
        'دعم الدولار والعملات الأجنبية',
        'تحويل مباشر من وإلى المحفظة',
        'سجل حركات مستقل ومنفصل',
        'مثالي للمدخرات طويلة الأمد',
      ],
    ),
    OnboardingFeature(
      title: '🏦 الخزنة (Smart Vault)',
      description: 'وفر تلقائياً مع كل إيداع تقوم به',
      icon: Icons.security_rounded,
      iconColor: AppColors.success,
      highlights: [
        'ادخار آلي بنسبة مئوية أو مبلغ ثابت',
        'دعم تعدد العملات داخل الخزنة',
        'عزل الأموال لتجنب الإنفاق العشوائي',
        'سجل معاملات دقيق وشفاف',
      ],
    ),
    OnboardingFeature(
      title: '📈 التحليلات والخرائط الحرارية',
      description: 'افهم نمط إنفاقك من خلال لغة الأرقام',
      icon: Icons.pie_chart_rounded,
      iconColor: AppColors.accent,
      highlights: [
        'حساب صافي الثروة الشامل للعملات',
        'خرائط حرارية للإنفاق اليومي',
        'تقارير بصرية ملونة بالدرجات',
        'تنبؤات مالية مبنية على سلوكك',
      ],
    ),
    OnboardingFeature(
      title: '🛍️ أرشيف المشتريات المتقدم',
      description: 'اعثر على أي مصروف مهما كان قديماً',
      icon: Icons.travel_explore_rounded,
      iconColor: Colors.teal,
      highlights: [
        'فلترة دقيقة حسب التاريخ والفئة',
        'رسوم بيانية لنتائج البحث',
        'أرشفة تلقائية لكل دوراتك المالية',
        'أداء سريع جداً مع البيانات الضخمة',
      ],
    ),
    OnboardingFeature(
      title: '💡 أدلة المساعدة في كل مكان',
      description: 'لن تضل طريقك أبداً مع رادار المصروف',
      icon: Icons.info_outline_rounded,
      iconColor: Colors.blueAccent,
      highlights: [
        'شرح تفصيلي لكل واجهة بمجرد الضغط',
        'نصائح مالية مدمجة لتحسين الادخار',
        'دليل شامل لميزات تعدد العملات',
        'دعم دائم وتفاعلي للمستخدم',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: AppDimensions.durationMedium),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < features.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: AppDimensions.durationMedium),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onStart();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: AppDimensions.durationMedium),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: widget.onStart,
                    child: Text(
                      'تخطي',
                      style: AppTypography.button.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      _fadeController.reset();
                      _fadeController.forward();
                    });
                  },
                  itemCount: features.length,
                  itemBuilder: (context, index) {
                    return _buildFeaturePage(features[index]);
                  },
                ),
              ),
              _buildIndicatorAndButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePage(OnboardingFeature feature) {
    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(feature.icon, size: 60, color: feature.iconColor),
            ),
            SizedBox(height: AppSpacing.xxl),
            Text(
              feature.title,
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(
                color: Colors.white,
                fontWeight: AppTypography.bold,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              feature.description,
              textAlign: TextAlign.center,
              style: AppTypography.subtitle1.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: feature.highlights.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String highlight = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: idx < feature.highlights.length - 1 ? 12 : 0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            highlight,
                            style: AppTypography.body2Medium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorAndButtons() {
    bool isLastPage = _currentPage == features.length - 1;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              features.length,
              (index) => Container(
                width: index == _currentPage ? 28 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: index == _currentPage
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: AnimatedButton(
                    onPressed: _goToPreviousPage,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 20),
                        SizedBox(width: AppSpacing.xs),
                        Text('السابق', style: AppTypography.button),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnimatedButton(
                  onPressed: _goToNextPage,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.lg,
                  ),
                  elevation: AppDimensions.elevationMD,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastPage ? 'ابدأ الآن' : 'التالي',
                        style: AppTypography.button.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Icon(
                        isLastPage
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '${_currentPage + 1} من ${features.length}',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
