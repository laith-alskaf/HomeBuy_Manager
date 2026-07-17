import 'package:flutter/material.dart';
import 'package:homebuy_manager/config/app_typography.dart';

/// مكون عرض رقم مع أنيميشن Count-up
/// يستخدم لعرض الأرقام مثل الرصيد والإحصائيات بشكل متحرك
class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle? textStyle;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;
  final Duration? duration;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.textStyle,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.duration,
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration ?? const Duration(milliseconds: 1000),
      curve: curve,
      builder: (context, animatedValue, child) {
        String formattedNumber;
        if (decimalPlaces > 0) {
          formattedNumber = animatedValue.toStringAsFixed(decimalPlaces);
        } else {
          formattedNumber = animatedValue.toInt().toString();
        }

        // إضافة فواصل الآلاف
        formattedNumber = _addThousandsSeparator(formattedNumber);

        return Text(
          '${prefix ?? ''}$formattedNumber${suffix ?? ''}',
          style: textStyle ?? AppTypography.number,
        );
      },
    );
  }

  String _addThousandsSeparator(String number) {
    // فصل الجزء الصحيح عن العشري
    final parts = number.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // إضافة الفواصل للجزء الصحيح
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    return buffer.toString() + decimalPart;
  }
}

/// نسخة مخصصة لعرض العملة (Currency)
class AnimatedCurrencyCounter extends StatelessWidget {
  final double value;
  final String currencySymbol;
  final TextStyle? textStyle;
  final TextStyle? symbolStyle;
  final bool symbolBefore;
  final Duration? duration;

  const AnimatedCurrencyCounter({
    super.key,
    required this.value,
    this.currencySymbol = 'ل.س',
    this.textStyle,
    this.symbolStyle,
    this.symbolBefore = false,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration ?? const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final formattedNumber = animatedValue.toStringAsFixed(0);
        final numberWithSeparator = _addThousandsSeparator(formattedNumber);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (symbolBefore) ...[
              Text(
                currencySymbol,
                style: symbolStyle ?? AppTypography.currency,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              numberWithSeparator,
              style: textStyle ?? AppTypography.numberLarge,
            ),
            if (!symbolBefore) ...[
              const SizedBox(width: 4),
              Text(
                currencySymbol,
                style: symbolStyle ?? AppTypography.currency,
              ),
            ],
          ],
        );
      },
    );
  }

  String _addThousandsSeparator(String number) {
    final buffer = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && (number.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(number[i]);
    }
    return buffer.toString();
  }
}

/// مكون بسيط لعرض نسبة مئوية مع أنيميشن
class AnimatedPercentage extends StatelessWidget {
  final double percentage; // 0-100
  final TextStyle? textStyle;
  final Duration? duration;
  final bool showSign;

  const AnimatedPercentage({
    super.key,
    required this.percentage,
    this.textStyle,
    this.duration,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCounter(
      value: percentage,
      textStyle: textStyle,
      suffix: '%',
      prefix: showSign && percentage > 0 ? '+' : null,
      decimalPlaces: 1,
      duration: duration,
    );
  }
}
