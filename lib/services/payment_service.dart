import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/merchant_config.dart';
import '../models/transaction.dart';

class PaymentConnectionException implements Exception {
  const PaymentConnectionException(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<Map<String, dynamic>> requestPaymentJson(
  http.Client client,
  Uri uri, {
  String method = 'GET',
  String? key,
  Object? body,
}) async {
  final request = http.Request(method, uri)..followRedirects = false;
  request.headers['Accept'] = 'application/json';
  if (key != null) request.headers['X-Api-Key'] = key;
  if (body != null) {
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);
  }
  try {
    final response = await (() async {
      final streamed = await client.send(request);
      final bytes = <int>[];
      await for (final chunk in streamed.stream) {
        if (bytes.length + chunk.length > 131072) {
          throw const PaymentConnectionException(
            'Respons server terlalu besar. Periksa alamat Payment API.',
          );
        }
        bytes.addAll(chunk);
      }
      return http.Response.bytes(bytes, streamed.statusCode);
    })().timeout(const Duration(seconds: 10));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const PaymentConnectionException(
        'API key tidak cocok dengan server ini. Periksa konfigurasi di halaman Saya.',
      );
    }
    if (response.statusCode == 404) {
      throw const PaymentConnectionException(
        'Transaksi atau endpoint tidak ditemukan pada server ini. Periksa server dan kode transaksi.',
      );
    }
    if (response.statusCode == 409) {
      throw const PaymentConnectionException(
        'Transaksi sudah diproses atau statusnya berubah. Periksa status sebelum mencoba lagi.',
      );
    }
    if (response.statusCode == 410) {
      throw const PaymentConnectionException(
        'Tagihan sudah kedaluwarsa. Buat tagihan baru dari Sparkleen.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const PaymentConnectionException(
        'Server belum dapat memproses permintaan. Periksa koneksi dan status Payment API.',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  } on PaymentConnectionException {
    rethrow;
  } on TimeoutException {
    throw const PaymentConnectionException(
      'Server tidak merespons. Periksa Wi-Fi, alamat, port, dan firewall laptop.',
    );
  } catch (_) {
    throw const PaymentConnectionException(
      'Tidak dapat membaca Payment API. Periksa alamat server dan koneksi perangkat.',
    );
  }
}

class PaymentService {
  PaymentService({MerchantConfig? config, this._client})
    : _config = config ?? MerchantConfig.instance {
    _settings = _config.settings;
    _revision = _config.revision;
  }
  final MerchantConfig _config;
  final http.Client? _client;
  late final ServerSettings _settings;
  late final int _revision;
  void _checkScope() {
    if (_config.revision != _revision) {
      throw const PaymentConnectionException(
        'Server sudah berubah. Buka kembali transaksi dari server yang aktif.',
      );
    }
    if (!_settings.configured) {
      throw const PaymentConnectionException(
        'Atur alamat server dan API key di halaman Saya terlebih dahulu.',
      );
    }
  }

  Future<dynamic> _request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    _checkScope();
    final client = _client ?? http.Client();
    try {
      final result = await requestPaymentJson(
        client,
        Uri.parse('${_settings.baseUrl}/api/transactions$path'),
        method: method,
        key: _settings.apiKey,
        body: body,
      );
      _checkScope();
      if (result['success'] != true || result['data'] == null) {
        throw const PaymentConnectionException(
          'Respons Payment API belum sesuai. Periksa server yang dipilih.',
        );
      }
      return result['data'];
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<TransactionModel> _transaction(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    final data = await _request(path, method: method, body: body);
    if (data is! Map<String, dynamic>) {
      throw const PaymentConnectionException(
        'Detail transaksi dari server belum sesuai.',
      );
    }
    return TransactionModel.fromJson(data);
  }

  Future<TransactionModel> createTransaction({
    required double amount,
    required String method,
    String? customerRef,
  }) => _transaction(
    '',
    method: 'POST',
    body: {
      'amount': amount,
      'method': method,
      if (customerRef != null && customerRef.isNotEmpty)
        'customer_ref': customerRef,
    },
  );
  Future<TransactionModel> findTransferTarget({
    required double amount,
    required String bankName,
    required String accountNumber,
  }) => _transaction(
    '/find-transfer-target',
    method: 'POST',
    body: {
      'amount': amount,
      'bank_name': bankName,
      'account_number': accountNumber,
    },
  );
  Future<TransactionModel> processPayment({required String transactionId}) =>
      _transaction(
        '/${Uri.encodeComponent(transactionId)}/pay',
        method: 'POST',
      );
  Future<TransactionModel> checkStatus({required String transactionId}) =>
      _transaction('/${Uri.encodeComponent(transactionId)}/status');
  Future<List<TransactionModel>> fetchTransactionHistory() async {
    final data = await _request('');
    if (data is! List) {
      throw const PaymentConnectionException(
        'Riwayat dari server belum sesuai.',
      );
    }
    return data
        .map(
          (row) =>
              TransactionModel.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }
}
