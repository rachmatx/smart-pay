import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_pay/config/app_theme.dart';
import 'package:smart_pay/config/merchant_config.dart';
import 'package:smart_pay/screens/profile_screen.dart';
import 'package:smart_pay/services/payment_service.dart';
import 'package:smart_pay/services/server_probe.dart';

class MemoryStore implements ServerSettingsStore {
  String? value;
  bool failWrite = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    if (failWrite) throw StateError('native storage unavailable');
    value = next;
  }
}

class ProbeFake extends ServerProbe {
  int calls = 0;
  ServerSettings? seen;
  @override
  Future<String> check(ServerSettings candidate) async {
    calls++;
    seen = candidate;
    return 'Terhubung • API key cocok • Mode simulasi';
  }
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'supports HTTPS and normalizes local HTTP; rejects credentials, paths and public cleartext',
    () {
      expect(
        normalizeServerUrl(' https://pay.example.com/ '),
        'https://pay.example.com',
      );
      for (final host in [
        '192.168.1.10',
        '10.0.2.2',
        '172.16.0.2',
        '172.31.2.1',
        'localhost',
        '127.0.0.1',
        '[::1]',
      ]) {
        expect(normalizeServerUrl('http://$host:3000/'), 'http://$host:3000');
      }
      for (final url in [
        'ftp://192.168.1.1',
        'http://example.com',
        'http://8.8.8.8',
        'http://172.32.0.1',
        'http://0.0.0.0:3000',
        'http://192.168.999.1',
        'https://user:key@example.com',
        'https://example.com/api/transactions',
        'https://example.com?key=x',
        'https://example.com#x',
        '192.168.1.10:3000',
        'http://192.168.1.10:70000',
      ]) {
        expect(
          () => normalizeServerUrl(url),
          throwsFormatException,
          reason: url,
        );
      }
      expect(
        () => ServerSettings.validated('https://example.com', 'a\nb'),
        throwsFormatException,
      );
    },
  );
  test(
    'settings survive restart and API key is absent from defaults',
    () async {
      final store = MemoryStore();
      final config = MerchantConfig(store: store);
      expect(config.settings.configured, isFalse);
      await config.save(
        ServerSettings.validated(
          'http://192.168.1.10:3000/',
          'fixture-merchant',
        ),
      );
      final restarted = MerchantConfig(store: store);
      await restarted.load();
      expect(restarted.settings.baseUrl, 'http://192.168.1.10:3000');
      expect(restarted.settings.apiKey, 'fixture-merchant');
      expect(restarted.loadError, isNull);
    },
  );
  test(
    'failed storage write leaves server, key and request revision intact',
    () async {
      final store = MemoryStore();
      final config = MerchantConfig(store: store);
      await config.save(
        const ServerSettings(baseUrl: 'https://a.example.com', apiKey: 'key-a'),
      );
      final revision = config.revision;
      store.failWrite = true;
      await expectLater(
        config.save(
          const ServerSettings(
            baseUrl: 'https://b.example.com',
            apiKey: 'key-b',
          ),
        ),
        throwsStateError,
      );
      expect(config.settings.baseUrl, 'https://a.example.com');
      expect(config.settings.apiKey, 'key-a');
      expect(config.revision, revision);
    },
  );
  test(
    'corrupt persisted configuration never activates a merchant credential',
    () async {
      final store = MemoryStore()..value = '{broken';
      final config = MerchantConfig(store: store);
      await config.load();
      expect(config.settings.configured, isFalse);
      expect(config.loadError, isNotNull);
    },
  );
  test(
    'payment service uses selected origin and current merchant key',
    () async {
      final config = MerchantConfig(store: MemoryStore());
      await config.save(
        const ServerSettings(
          baseUrl: 'http://192.168.1.10:3000',
          apiKey: 'fixture-merchant',
        ),
      );
      final client = MockClient((r) async {
        expect(
          r.url.toString(),
          'http://192.168.1.10:3000/api/transactions/fixture-id/status',
        );
        expect(r.headers['X-Api-Key'], 'fixture-merchant');
        expect(r.followRedirects, isFalse);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'fixture-id',
              'amount': 35000,
              'method': 'QRIS',
              'status': 'PENDING',
            },
          }),
          200,
        );
      });
      final tx = await PaymentService(
        config: config,
        client: client,
      ).checkStatus(transactionId: 'fixture-id');
      expect(tx.amount, 35000);
    },
  );
  test(
    'old payment screen cannot submit to another server or merchant',
    () async {
      final config = MerchantConfig(store: MemoryStore());
      await config.save(
        const ServerSettings(baseUrl: 'https://a.example.com', apiKey: 'key-a'),
      );
      var calls = 0;
      final service = PaymentService(
        config: config,
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      await config.save(
        const ServerSettings(baseUrl: 'https://b.example.com', apiKey: 'key-b'),
      );
      await expectLater(
        service.processPayment(transactionId: 'old-id'),
        throwsA(isA<PaymentConnectionException>()),
      );
      expect(calls, 0);
    },
  );
  test('late history from previous server is discarded', () async {
    final config = MerchantConfig(store: MemoryStore());
    await config.save(
      const ServerSettings(baseUrl: 'https://a.example.com', apiKey: 'key-a'),
    );
    final gate = Completer<http.Response>();
    final entered = Completer<void>();
    final service = PaymentService(
      config: config,
      client: MockClient((_) {
        entered.complete();
        return gate.future;
      }),
    );
    final future = service.fetchTransactionHistory();
    final expectation = expectLater(
      future,
      throwsA(isA<PaymentConnectionException>()),
    );
    await entered.future;
    await config.save(
      const ServerSettings(baseUrl: 'https://b.example.com', apiKey: 'key-b'),
    );
    gate.complete(http.Response('{"success":true,"data":[]}', 200));
    await expectation;
  });
  test(
    'connection check is read-only and sends key only after valid health',
    () async {
      final calls = <http.Request>[];
      final probe = ServerProbe(
        client: MockClient((r) async {
          calls.add(r);
          expect(r.method, 'GET');
          expect(r.followRedirects, isFalse);
          if (r.url.path == '/health') {
            expect(r.headers.containsKey('X-Api-Key'), isFalse);
            return http.Response('{"status":"OK","mode":"SIMULATION"}', 200);
          }
          expect(r.headers['X-Api-Key'], 'fixture-key');
          return http.Response('{"success":true,"data":[]}', 200);
        }),
      );
      expect(
        await probe.check(
          const ServerSettings(
            baseUrl: 'https://pay.example.com',
            apiKey: 'fixture-key',
          ),
        ),
        contains('Mode simulasi'),
      );
      expect(calls.length, 2);
    },
  );
  test('wrong health or redirect never receives the key', () async {
    for (final status in [200, 302]) {
      var calls = 0;
      final probe = ServerProbe(
        client: MockClient((r) async {
          calls++;
          expect(r.headers.containsKey('X-Api-Key'), isFalse);
          return http.Response(
            '{"status":"WRONG"}',
            status,
            headers: {'location': 'https://elsewhere.example.com'},
          );
        }),
      );
      await expectLater(
        probe.check(
          const ServerSettings(
            baseUrl: 'https://pay.example.com',
            apiKey: 'fixture-key',
          ),
        ),
        throwsA(isA<PaymentConnectionException>()),
      );
      expect(calls, 1);
    }
  });
  test(
    'incorrect merchant key gives a useful error without echoing credentials',
    () async {
      final probe = ServerProbe(
        client: MockClient(
          (r) async => r.url.path == '/health'
              ? http.Response('{"status":"OK"}', 200)
              : http.Response('fixture-secret-key must never appear', 403),
        ),
      );
      try {
        await probe.check(
          const ServerSettings(
            baseUrl: 'https://pay.example.com',
            apiKey: 'fixture-secret-key',
          ),
        );
        fail('Should reject key');
      } on PaymentConnectionException catch (e) {
        expect(e.message, contains('API key tidak cocok'));
        expect(e.message, isNot(contains('fixture-secret-key')));
      }
    },
  );
  testWidgets(
    'Saya can probe a draft without saving then save with confirmation',
    (tester) async {
      final store = MemoryStore();
      final config = MerchantConfig(store: store);
      final probe = ProbeFake();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProfileScreen(config: config, probe: probe),
        ),
      );
      await reveal(tester, find.byKey(const Key('server-address')));
      await tester.enterText(
        find.byKey(const Key('server-address')),
        'http://192.168.1.10:3000',
      );
      await reveal(tester, find.byKey(const Key('merchant-key')));
      await tester.enterText(
        find.byKey(const Key('merchant-key')),
        'fixture-key',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('merchant-key')),
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isTrue,
      );
      await reveal(tester, find.text('Uji koneksi'));
      await tester.tap(find.text('Uji koneksi'));
      await tester.pumpAndSettle();
      expect(probe.calls, 1);
      expect(store.value, isNull);
      expect(find.textContaining('Mode simulasi'), findsOneWidget);
      await reveal(tester, find.text('Simpan konfigurasi'));
      await tester.tap(find.text('Simpan konfigurasi'));
      await tester.pumpAndSettle();
      expect(find.text('Gunakan konfigurasi ini?'), findsOneWidget);
      await tester.tap(find.text('Simpan server'));
      await tester.pumpAndSettle();
      expect(config.settings.baseUrl, 'http://192.168.1.10:3000');
      expect(store.value, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'save does not require online server; cancellation and storage errors keep old server',
    (tester) async {
      final store = MemoryStore();
      final config = MerchantConfig(store: store);
      final probe = ProbeFake();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProfileScreen(config: config, probe: probe),
        ),
      );
      await reveal(tester, find.byKey(const Key('merchant-key')));
      await tester.enterText(
        find.byKey(const Key('merchant-key')),
        'fixture-key',
      );
      await reveal(tester, find.text('Simpan konfigurasi'));
      await tester.tap(find.text('Simpan konfigurasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kembali'));
      await tester.pumpAndSettle();
      expect(store.value, isNull);
      expect(probe.calls, 0);
      store.failWrite = true;
      await tester.tap(find.text('Simpan konfigurasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan server'));
      await tester.pumpAndSettle();
      expect(find.textContaining('belum tersimpan'), findsOneWidget);
      expect(config.settings.configured, isFalse);
      expect(probe.calls, 0);
    },
  );
  testWidgets('Saya fits narrow screen with large text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    final config = MerchantConfig(store: MemoryStore());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.8)),
          child: child!,
        ),
        home: ProfileScreen(config: config),
      ),
    );
    await reveal(tester, find.byKey(const Key('server-address')));
    await tester.enterText(
      find.byKey(const Key('server-address')),
      'https://pay.example.com/api/transactions',
    );
    await reveal(tester, find.byKey(const Key('merchant-key')));
    await tester.enterText(
      find.byKey(const Key('merchant-key')),
      'fixture-key',
    );
    await reveal(tester, find.text('Simpan konfigurasi'));
    await tester.tap(find.text('Simpan konfigurasi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gunakan alamat lengkap'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
