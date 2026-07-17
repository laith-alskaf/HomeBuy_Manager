import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../services/currency_service.dart';
import '../../../utils/formatters.dart';

class CurrencyHeaderWidget extends StatefulWidget {
  final VoidCallback? onConvertTap;

  const CurrencyHeaderWidget({super.key, this.onConvertTap});

  @override
  State<CurrencyHeaderWidget> createState() => _CurrencyHeaderWidgetState();
}

class _CurrencyHeaderWidgetState extends State<CurrencyHeaderWidget> {
  double _rate = 0.0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchRate();
  }

  Future<void> _fetchRate() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final rate = await CurrencyService().getTodayRate();

    if (mounted) {
      setState(() {
        _rate = rate;
        _isLoading = false;
        _hasError = rate == 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _hasError
          ? _fetchRate
          : null, // إعادة المحاولة عند الضغط في حال الخطأ
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: _hasError ? AppColors.danger.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _hasError
                ? AppColors.danger.withOpacity(0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hasError
                    ? Colors.white
                    : AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.success,
                      ),
                    )
                  : Icon(
                      _hasError
                          ? Icons.refresh_rounded
                          : Icons.currency_exchange,
                      color: _hasError ? AppColors.danger : AppColors.success,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سعر الصرف اليوم',
                  style: TextStyle(
                    fontSize: 10,
                    color: _hasError ? AppColors.danger : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isLoading
                      ? 'جاري التحديث...'
                      : _hasError
                      ? '0\$ (اضغط للتحديث)'
                      : '1 \$ = ${formatCurrency(_rate)} ل.س',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _hasError ? AppColors.danger : AppColors.textDark,
                  ),
                ),
              ],
            ),
            if (widget.onConvertTap != null) ...[
              const Spacer(),
              Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: widget.onConvertTap,
                  tooltip: 'تصريف أرصدة المحفظة',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
