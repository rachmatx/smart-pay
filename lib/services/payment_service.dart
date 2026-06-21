import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/merchant_config.dart';
import '../models/transaction.dart';

/// Service untuk semua pemanggilan API pembayaran.
///
/// Semua HTTP call dikumpulkan di sini agar tidak ada logika jaringan
/// yang masuk ke dalam screen/UI.
class PaymentService {
  final MerchantConfig _config = MerchantConfig.instance;

  /// Header default untuk setiap request
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Api-Key': _config.apiKey,
      };

  /// Membuat transaksi baru di backend.
  ///
  /// Endpoint: POST /api/transactions
  /// Body: { amount, method, customer_ref? }
  /// method harus 'QRIS' atau 'BANK_TRANSFER'
  /// Response: { success, data: { transaction_id, amount, method, payment_detail, expired_at, status } }
  Future<TransactionModel> createTransaction({
    required double amount,
    required String method,
    String? customerRef,
  }) async {
    final url = Uri.parse('${_config.baseUrl}/api/transactions');

    try {
      final body = <String, dynamic>{
        'amount': amount,
        'method': method,
      };
      if (customerRef != null && customerRef.isNotEmpty) {
        body['customer_ref'] = customerRef;
      }

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Response dibungkus { success, data: { ... } }
        return TransactionModel.fromJson(decoded['data']);
      } else {
        final error = decoded['error'] ?? 'Unknown error';
        throw Exception('Gagal membuat transaksi: $error');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Koneksi ke server gagal: $e');
    }
  }

  /// Memproses pembayaran untuk transaksi yang sudah ada.
  ///
  /// Endpoint: POST /api/transactions/:id/pay
  /// Tidak perlu body — method sudah ditentukan saat create.
  /// Response: { success, data: { transaction_id, status, amount, method, paid_at } }
  Future<TransactionModel> processPayment({
    required String transactionId,
  }) async {
    final url =
        Uri.parse('${_config.baseUrl}/api/transactions/$transactionId/pay');

    try {
      final response = await http.post(url, headers: _headers);
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return TransactionModel.fromJson(decoded['data']);
      } else {
        final error = decoded['error'] ?? 'Unknown error';
        throw Exception('Gagal memproses pembayaran: $error');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Koneksi ke server gagal: $e');
    }
  }

  /// Mengecek status transaksi terkini.
  ///
  /// Endpoint: GET /api/transactions/:id/status
  /// Response: { success, data: { id, amount, method, status, paid_at, expired_at } }
  Future<TransactionModel> checkStatus({
    required String transactionId,
  }) async {
    final url = Uri.parse(
        '${_config.baseUrl}/api/transactions/$transactionId/status');

    try {
      final response = await http.get(url, headers: _headers);
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return TransactionModel.fromJson(decoded['data']);
      } else {
        final error = decoded['error'] ?? 'Unknown error';
        throw Exception('Gagal mengecek status: $error');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Koneksi ke server gagal: $e');
    }
  }
}
