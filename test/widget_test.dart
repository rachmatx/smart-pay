import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_pay/config/merchant_config.dart';
import 'package:smart_pay/main.dart';
import 'package:smart_pay/screens/profile_screen.dart';

void main() {
  testWidgets('first launch opens server configuration in Saya', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartPayApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('server-address')), findsOneWidget);
    expect(find.text('Konfigurasi server'), findsOneWidget);
    expect(find.text('Belum dikonfigurasi'), findsOneWidget);
    expect(find.text('Saya'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'changing server clears old navigation and opens saved settings',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await http.runWithClient(
        () async {
          final config = MerchantConfig.instance;
          await config.save(
            const ServerSettings(
              baseUrl: 'https://a.example.com',
              apiKey: 'key-a',
            ),
          );
          await tester.pumpWidget(const SmartPayApp());
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(ProfileScreen));
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Old server flow')),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Old server flow'), findsOneWidget);
          await config.save(
            const ServerSettings(
              baseUrl: 'http://192.168.1.10:3000',
              apiKey: 'key-b',
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Old server flow'), findsNothing);
          expect(find.text('Konfigurasi server'), findsOneWidget);
          expect(find.text('Jaringan lokal'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        () => MockClient(
          (_) async => http.Response('{"success":true,"data":[]}', 200),
        ),
      );
    },
  );
  testWidgets('Saya tab remains usable at 320px and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const SmartPayApp());
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Konfigurasi server'),
          160,
          scrollable: find
              .descendant(
                of: find.byType(ProfileScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Konfigurasi server'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      () => MockClient(
        (_) async => http.Response('{"success":true,"data":[]}', 200),
      ),
    );
  });
}
