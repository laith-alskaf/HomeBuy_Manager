import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../utils/formatters.dart';

class CurrencyConversionDialog extends StatefulWidget {
  final Map<String, double> balancesByCurrency;
  final Function({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    required double rate,
    required String note,
  }) onConvert;

  const CurrencyConversionDialog({
    super.key,
    required this.balancesByCurrency,
    required this.onConvert,
  });

  @override
  State<CurrencyConversionDialog> createState() => _CurrencyConversionDialogState();
}

class _CurrencyConversionDialogState extends State<CurrencyConversionDialog> {
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _noteController = TextEditingController();

  String _fromCurrency = 'SYP';
  String _toCurrency = 'USD';

  static const List<String> _currencies = ['SYP', 'USD', 'EUR', 'SAR', 'AED'];

  static const Map<String, String> _currencySymbols = {
    'SYP': 'ل.س',
    'USD': '\$',
    'EUR': '€',
    'SAR': 'ر.س',
    'AED': 'د.إ',
  };

  @override
  void initState() {
    super.initState();
    // Default config: from the first currency that has a balance (if any)
    final activeCurrencies = widget.balancesByCurrency.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
    
    if (activeCurrencies.isNotEmpty) {
      _fromCurrency = activeCurrencies.first;
      _toCurrency = _fromCurrency == 'SYP' ? 'USD' : 'SYP';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fromSymbol = _currencySymbols[_fromCurrency] ?? _fromCurrency;
    final toSymbol = _currencySymbols[_toCurrency] ?? _toCurrency;

    final availableBalance = widget.balancesByCurrency[_fromCurrency] ?? 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.currency_exchange_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'تصريف العملات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),

              // --- From & To Currencies ---
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _fromCurrency,
                      decoration: InputDecoration(
                        labelText: 'من عملة',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _currencies.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _fromCurrency = val);
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: _swapCurrencies,
                    icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _toCurrency,
                      decoration: InputDecoration(
                        labelText: 'إلى عملة',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _currencies.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _toCurrency = val);
                      },
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'الرصيد المتاح: ${formatCompactCurrency(availableBalance)} $fromSymbol',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ),

              // --- Amount to convert ---
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'المبلغ المراد تصريفه',
                  suffixText: fromSymbol,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              // --- Exchange Rate ---
              TextField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'سعر الصرف (1 $fromSymbol = ? $toSymbol)',
                  hintText: 'مثال: إذا كان 1\$ = 15000 ل.س نضع 15000',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              // --- Note ---
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 25),

              // --- Action Buttons ---
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        foregroundColor: Colors.grey,
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_fromCurrency == _toCurrency) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('العملتان متطابقتان')),
                          );
                          return;
                        }
                        final amount = parseFormattedNumber(_amountController.text);
                        final rateStr = _rateController.text.replaceAll(',', '.');
                        final rate = double.tryParse(rateStr) ?? 0.0;

                        if (amount <= 0 || rate <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('الرجاء إدخال قيم صحيحة')),
                          );
                          return;
                        }

                        if (amount > availableBalance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('الرصيد المتاح غير كافٍ بـ $_fromCurrency')),
                          );
                          return;
                        }

                        widget.onConvert(
                          fromCurrency: _fromCurrency,
                          toCurrency: _toCurrency,
                          amount: amount,
                          rate: rate,
                          note: _noteController.text,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'تأكيد التصريف',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
