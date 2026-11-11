// Opt-in: disposable loopback simulator only; no operational merchant or callback.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pay/config/merchant_config.dart';
import 'package:smart_pay/services/payment_service.dart';
import 'package:smart_pay/services/server_probe.dart';
import '../test/server_settings_test.dart' show MemoryStore;

void main() {
  testWidgets('real local Payment API: probe, lookup and simulator payment', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final base = Platform.environment['SMARTPAY_TEST_URL'] ?? '';
      final key = Platform.environment['SMARTPAY_TEST_KEY'] ?? '';
      if (Uri.tryParse(base)?.host != '127.0.0.1' || key.isEmpty) {
        fail('Disposable loopback fixture required.');
      }
      final old = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        final settings = ServerSettings.validated(base, key);
        expect(await ServerProbe().check(settings), contains('Mode simulasi'));
        final config = MerchantConfig(store: MemoryStore());
        await config.save(settings);
        final service = PaymentService(config: config);
        final invoice = await service.createTransaction(
          amount: 35000,
          method: 'QRIS',
          customerRef: 'SMARTPAY-LOCAL-FIXTURE',
        );
        expect(invoice.status, 'PENDING');
        expect(
          (await service.checkStatus(
            transactionId: invoice.transactionId,
          )).amount,
          35000,
        );
        expect(
          (await service.processPayment(
            transactionId: invoice.transactionId,
          )).status,
          'SUCCESS',
        );
        expect((await service.fetchTransactionHistory()).length, 1);
        await expectLater(
          ServerProbe().check(
            ServerSettings(baseUrl: base, apiKey: 'wrong-fixture-key'),
          ),
          throwsA(
            isA<PaymentConnectionException>().having(
              (e) => e.message,
              'message',
              contains('API key tidak cocok'),
            ),
          ),
        );
        await config.save(
          const ServerSettings(
            baseUrl: 'https://other.example.com',
            apiKey: 'other-fixture',
          ),
        );
        await expectLater(
          service.processPayment(transactionId: invoice.transactionId),
          throwsA(
            isA<PaymentConnectionException>().having(
              (e) => e.message,
              'message',
              contains('Server sudah berubah'),
            ),
          ),
        );
      } finally {
        HttpOverrides.global = old;
      }
    });
  });
}
