import 'package:url_launcher/url_launcher.dart';

class PhoneLauncher {
  const PhoneLauncher._();

  static bool hasNumber(String? mobileNumber) {
    return _digitsOnly(mobileNumber).isNotEmpty;
  }

  static Future<bool> call(String? mobileNumber) async {
    final digits = _digitsOnly(mobileNumber);
    if (digits.isEmpty) {
      return false;
    }

    return launchUrl(
      Uri(scheme: 'tel', path: digits),
      mode: LaunchMode.externalApplication,
    );
  }

  static String _digitsOnly(String? value) {
    return value?.replaceAll(RegExp(r'[^0-9+]'), '').trim() ?? '';
  }
}
