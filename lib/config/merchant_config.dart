/// Konfigurasi merchant untuk koneksi ke backend SmartPay.
///
/// Ganti [baseUrl] dan [apiKey] sesuai dengan proyek yang digunakan.
/// Kelas ini menggunakan pola singleton agar konfigurasi konsisten
/// di seluruh aplikasi.
class MerchantConfig {
  MerchantConfig._internal();

  static final MerchantConfig _instance = MerchantConfig._internal();

  /// Singleton instance
  static MerchantConfig get instance => _instance;

  /// Base URL backend (Gunakan IP komputer agar HP bisa mengaksesnya via WiFi)
  String baseUrl = 'http://192.168.100.10:3000';

  /// API Key untuk otentikasi ke backend
  String apiKey = 'api-keysmartpay-test123';
}
