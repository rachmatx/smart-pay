import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'config/merchant_config.dart';
import 'screens/main_screen.dart';

/// Titik masuk utama aplikasi SmartPay.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MerchantConfig.instance.load();
  runApp(const SmartPayApp());
}

class SmartPayApp extends StatelessWidget {
  const SmartPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MerchantConfig.instance,
      builder: (context, _) => MaterialApp(
        key: ValueKey(MerchantConfig.instance.revision),
        title: 'SmartPay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: MainScreen(
          initialIndex:
              MerchantConfig.instance.revision > 0 ||
                  !MerchantConfig.instance.settings.configured
              ? 4
              : 0,
        ),
      ),
    );
  }
}
