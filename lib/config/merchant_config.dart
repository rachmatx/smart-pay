import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServerSettings {
  const ServerSettings({required this.baseUrl, required this.apiKey});
  static const defaultUrl =
      'https://payment-api-production-ba66.up.railway.app';
  final String baseUrl, apiKey;
  bool get configured => apiKey.isNotEmpty;
  bool get local => isLocalHost(Uri.parse(baseUrl).host);
  factory ServerSettings.validated(String address, String key) {
    final url = normalizeServerUrl(address);
    final value = key.trim();
    if (value.isEmpty ||
        value.length > 512 ||
        RegExp(r'[\x00-\x20\x7f]').hasMatch(value)) {
      throw const FormatException(
        'Isi API key merchant yang valid, tanpa spasi atau baris baru.',
      );
    }
    return ServerSettings(baseUrl: url, apiKey: value);
  }
}

bool isLocalHost(String host) {
  if (host == 'localhost' || host == '::1') return true;
  final parts = host.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((n) => n == null || n < 0 || n > 255)) {
    return false;
  }
  return parts[0] == 10 ||
      parts[0] == 127 ||
      (parts[0] == 192 && parts[1] == 168) ||
      (parts[0] == 172 && parts[1]! >= 16 && parts[1]! <= 31);
}

String normalizeServerUrl(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/')) {
    throw const FormatException(
      'Gunakan alamat lengkap, tanpa /api/transactions, akun, atau parameter.',
    );
  }
  try {
    if (uri.port < 1 || uri.port > 65535) throw const FormatException();
  } on FormatException {
    throw const FormatException('Port server harus antara 1 dan 65535.');
  }
  if (uri.scheme == 'http' && !isLocalHost(uri.host)) {
    throw const FormatException(
      'Gunakan HTTPS untuk server online. HTTP hanya untuk IP lokal atau localhost.',
    );
  }
  return uri.replace(path: '').toString().replaceFirst(RegExp(r'/$'), '');
}

abstract class ServerSettingsStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureServerSettingsStore implements ServerSettingsStore {
  static const _key = 'smartpay_server_settings_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

class MerchantConfig extends ChangeNotifier {
  MerchantConfig({ServerSettingsStore? store})
    : _store = store ?? SecureServerSettingsStore();
  static final instance = MerchantConfig();
  final ServerSettingsStore _store;
  ServerSettings _settings = const ServerSettings(
    baseUrl: ServerSettings.defaultUrl,
    apiKey: '',
  );
  ServerSettings get settings => _settings;
  int revision = 0;
  String? loadError;
  Future<void> load() async {
    try {
      final raw = await _store.read();
      if (raw != null) {
        final data = jsonDecode(raw);
        if (data is! Map ||
            data['baseUrl'] is! String ||
            data['apiKey'] is! String) {
          throw const FormatException();
        }
        _settings = ServerSettings.validated(
          data['baseUrl'] as String,
          data['apiKey'] as String,
        );
      }
      loadError = null;
    } catch (_) {
      _settings = const ServerSettings(
        baseUrl: ServerSettings.defaultUrl,
        apiKey: '',
      );
      loadError =
          'Pengaturan tersimpan belum dapat dibaca. Isi dan simpan konfigurasi server kembali.';
    }
  }

  Future<void> save(ServerSettings candidate) async {
    final value = ServerSettings.validated(candidate.baseUrl, candidate.apiKey);
    // A failed encrypted write must leave the previous active server intact.
    await _store.write(
      jsonEncode({'baseUrl': value.baseUrl, 'apiKey': value.apiKey}),
    );
    _settings = value;
    loadError = null;
    revision++;
    notifyListeners();
  }
}
