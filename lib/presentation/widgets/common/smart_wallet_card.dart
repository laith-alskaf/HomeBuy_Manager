import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_dimensions.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../utils/formatters.dart';
import 'animated_counter.dart';
import 'animated_button.dart';

class SmartWalletCard extends StatelessWidget {
  final double currentBalance;
  final double totalDeposits;
  final double totalSpent;
  final double rolloverBalance;
  final double lowBalanceThreshold;
  final VoidCallback onAddBalance;
  final String activeCurrency;
  final List<String> availableCurrencies;
  final ValueChanged<String>? onCurrencyChanged;

  const SmartWalletCard({
    super.key,
    required this.currentBalance,
    required this.totalDeposits,
    required this.totalSpent,
    required this.rolloverBalance,
    required this.lowBalanceThreshold,
    required this.onAddBalance,
    required this.activeCurrency,
    required this.availableCurrencies,
    this.onCurrencyChanged,
  });

  String _currencySymbol(String c) {
    switch (c) {
      case 'SYP': return 'ل.س';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'SAR': return 'ر.س';
      case 'AED': return 'د.إ';
      default: return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    // بناءً على طلب المستخدم: التحقق من الرصيد واللون الأحمر يظهر فقط للعملة السورية (SYP)
    final bool isSYP = activeCurrency == 'SYP';
    final bool isLowBalance = isSYP && currentBalance <= lowBalanceThreshold;
    final bool isCritical = isSYP && currentBalance <= 0;

    final List<Color> cardGradient = isCritical || isLowBalance
        ? [AppColors.danger, AppColors.danger700]
        : [AppColors.primary, AppColors.secondary];

    final double spendingPercentage =
        totalDeposits > 0 ? (totalSpent / totalDeposits).clamp(0.0, 1.0) : 0.0;

    final symbol = _currencySymbol(activeCurrency);

    return Container(
      height: AppDimensions.cardHeightLG,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: cardGradient.last.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -30,
            top: -30,
            child: _DecorativeCircle(size: 150, opacity: 0.1),
          ),
          const Positioned(
            bottom: -50,
            left: -20,
            child: _DecorativeCircle(size: 200, opacity: 0.1),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // الصف العلوي: العنوان وزر الإضافة ومبدل العملات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'الرصيد المتاح',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                              if (availableCurrencies.length > 1 && onCurrencyChanged != null) ...[
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    final idx = availableCurrencies.indexOf(activeCurrency);
                                    final next = availableCurrencies[(idx + 1) % availableCurrencies.length];
                                    onCurrencyChanged!(next);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          activeCurrency,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ]
                            ],
                          ),
                          SizedBox(height: AppSpacing.xs),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: AnimatedCurrencyCounter(
                              key: ValueKey('main_balance_$activeCurrency'),
                              value: currentBalance,
                              currencySymbol: symbol,
                              textStyle: AppTypography.h2.copyWith(
                                color: Colors.white,
                                fontWeight: AppTypography.bold,
                              ),
                              symbolStyle: AppTypography.h5.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              duration: const Duration(milliseconds: 1000),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildAddButton(),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLowBalance
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isLowBalance ? 'رصيد منخفض' : 'وضع مالي مستقر',
                            style:
                                const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (rolloverBalance > 0)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.savings_rounded,
                              color: Colors.black87,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'مدور: ${formatCompactCurrency(rolloverBalance)} $symbol',
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'المصروف: ${formatCompactCurrency(totalSpent)} $symbol',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12),
                          ),
                        ),
                        Text(
                          '${(spendingPercentage * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeOut,
                          widthFactor: spendingPercentage,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 6,
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return AnimatedIconButton(
      icon: Icons.add_rounded,
      onPressed: onAddBalance,
      color: Colors.white,
      size: 28,
      tooltip: 'إضافة رصيد',
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorativeCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}
