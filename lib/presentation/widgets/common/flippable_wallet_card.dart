import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_dimensions.dart';
import 'smart_wallet_card.dart';

class FlippableWalletCard extends StatefulWidget {
  final double lowBalanceThreshold;
  final Map<String, double> currentBalanceByCurrency;
  final Map<String, double> totalDepositsByCurrency;
  final Map<String, double> totalSpentByCurrency;
  final Map<String, double> rolloverBalanceByCurrency;
  final VoidCallback onAddBalance;

  const FlippableWalletCard({
    super.key,
    required this.lowBalanceThreshold,
    required this.currentBalanceByCurrency,
    required this.totalDepositsByCurrency,
    required this.totalSpentByCurrency,
    required this.rolloverBalanceByCurrency,
    required this.onAddBalance,
  });

  @override
  State<FlippableWalletCard> createState() => _FlippableWalletCardState();
}

class _FlippableWalletCardState extends State<FlippableWalletCard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _glowController;
  late Animation<double> _flipAnimation;
  late Animation<double> _glowAnimation;
  bool _isFront = true; // true = الغطاء (المخفي)، false = التفاصيل
  
  String _activeCurrency = 'SYP';

  @override
  void initState() {
    super.initState();

    _setDefaultCurrency();

    // Flip Animation
    _flipController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: AppDimensions.durationSlow),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    // Glow Animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }
  
  void _setDefaultCurrency() {
    final activeCurrencies = widget.currentBalanceByCurrency.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
    if (activeCurrencies.isNotEmpty && !activeCurrencies.contains('SYP')) {
      _activeCurrency = activeCurrencies.first;
    }
  }

  @override
  void didUpdateWidget(covariant FlippableWalletCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.currentBalanceByCurrency.containsKey(_activeCurrency) &&
        widget.currentBalanceByCurrency.isNotEmpty) {
      _setDefaultCurrency();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedback.mediumImpact();

    if (_isFront) {
      _flipController.forward();
      _glowController.forward().then((_) => _glowController.reverse());
    } else {
      _flipController.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipAnimation, _glowAnimation]),
        builder: (context, child) {
          final angle = _flipAnimation.value * pi;
          final isUnder90 = angle < pi / 2;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(_glowAnimation.value * 0.6),
                  blurRadius: 30 + (_glowAnimation.value * 20),
                  spreadRadius: _glowAnimation.value * 5,
                ),
              ],
            ),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isUnder90
                  ? _buildCoverFace()
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _buildDetailsFace(),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsFace() {
    final available = widget.currentBalanceByCurrency.keys.toSet()
        ..addAll(widget.totalDepositsByCurrency.keys)
        ..addAll(['SYP']);

    return SmartWalletCard(
      lowBalanceThreshold: widget.lowBalanceThreshold,
      currentBalance: widget.currentBalanceByCurrency[_activeCurrency] ?? 0.0,
      totalDeposits: widget.totalDepositsByCurrency[_activeCurrency] ?? 0.0,
      totalSpent: widget.totalSpentByCurrency[_activeCurrency] ?? 0.0,
      rolloverBalance: widget.rolloverBalanceByCurrency[_activeCurrency] ?? 0.0,
      onAddBalance: widget.onAddBalance,
      activeCurrency: _activeCurrency,
      availableCurrencies: available.toList()..sort(),
      onCurrencyChanged: (currency) {
        setState(() => _activeCurrency = currency);
      },
    );
  }

  Widget _buildCoverFace() {
    return Container(
      height: AppDimensions.cardHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        gradient: LinearGradient(
          colors: [AppColors.primary800, AppColors.primary400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.account_balance_wallet,
                size: 150, color: Colors.white.withOpacity(0.05)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.fingerprint,
                      size: 40, color: Colors.white),
                ),
                const SizedBox(height: 15),
                const Text(
                  'البيانات محمية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'اضغط للكشف عن الرصيد',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
