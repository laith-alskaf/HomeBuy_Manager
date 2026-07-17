import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CurrencyService {
  static const String _apiKey = 'daf5dfc70000fbc9dc22268af882201d1bd9f144';
  static const String _baseUrl =
      'https://api.getgeoapi.com/v2/currency/convert';

  // Singleton Pattern
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  /// جلب سعر الصرف (1 دولار كم يساوي ليرة سورية)
  /// يحاول جلبه من التخزين المحلي أولاً إذا كان لنفس اليوم، وإلا يطلبه من الإنترنت
  Future<double> getTodayRate() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'rate_$today';

    // 1. محاولة القراءة من الكاش (لتقليل استهلاك الـ API)
    if (prefs.containsKey(key)) {
      return prefs.getDouble(key) ?? 0.0;
    }

    // 2. الطلب من الـ API في حال عدم وجود كاش لليوم
    try {
      final uri = Uri.parse(
        '$_baseUrl?api_key=$_apiKey&from=USD&to=SYP&amount=1&format=json',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final rateStr = data['rates']['SYP']['rate'] * 100;
          final rate = double.tryParse(rateStr.toString()) ?? 0.0;

          if (rate > 0) {
            await prefs.setDouble(key, rate); // تخزين السعر لليوم
          }
          return rate;
        }
      }
    } catch (e) {
      // في حال وجود خطأ في الاتصال أو TimeOut نرجع 0
      return 0.0;
    }
    return 0.0;
  }
}
