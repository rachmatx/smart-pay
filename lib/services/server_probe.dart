import 'package:http/http.dart' as http;

import '../config/merchant_config.dart';
import 'payment_service.dart';

class ServerProbe {
  ServerProbe({this._client});
  final http.Client? _client;
  Future<String> check(ServerSettings candidate) async {
    final settings = ServerSettings.validated(
      candidate.baseUrl,
      candidate.apiKey,
    );
    final client = _client ?? http.Client();
    try {
      final health = await requestPaymentJson(
        client,
        Uri.parse('${settings.baseUrl}/health'),
      );
      if (health['status'] != 'OK') {
        throw const PaymentConnectionException(
          'Alamat ini belum dikenali sebagai Payment API.',
        );
      }
      final history = await requestPaymentJson(
        client,
        Uri.parse('${settings.baseUrl}/api/transactions'),
        key: settings.apiKey,
      );
      if (history['success'] != true || history['data'] is! List) {
        throw const PaymentConnectionException(
          'Respons merchant belum sesuai dengan Payment API.',
        );
      }
      return health['mode'] == 'SIMULATION'
          ? 'Terhubung • API key cocok • Mode simulasi'
          : 'Terhubung • API key cocok';
    } finally {
      if (_client == null) client.close();
    }
  }
}
