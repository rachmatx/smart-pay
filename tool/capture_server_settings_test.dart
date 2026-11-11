import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pay/config/app_theme.dart';
import 'package:smart_pay/config/merchant_config.dart';
import 'package:smart_pay/screens/profile_screen.dart';
import '../test/server_settings_test.dart' show MemoryStore;

void main() {
  testWidgets('capture server settings with fictional local merchant', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final loader = FontLoader('Roboto');
      final bytes = await File(
        '../.tooling/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      ).readAsBytes();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final config = MerchantConfig(store: MemoryStore());
    await config.save(
      const ServerSettings(
        baseUrl: 'http://192.168.1.10:3000',
        apiKey: 'fixture-merchant-key',
      ),
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: ProfileScreen(config: config),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final name in ['top', 'bottom']) {
      if (name == 'bottom') {
        await tester.scrollUntilVisible(
          find.textContaining('Smart Pay 1.0.1'),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final frame = await boundary.toImage(pixelRatio: 2);
        final data = await frame.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/screenshots/server-settings-$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        frame.dispose();
      });
    }
  });
}
