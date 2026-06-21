import 'package:flutter_test/flutter_test.dart';

import 'package:smart_pay/main.dart';

void main() {
  testWidgets('SmartPay app renders correctly', (WidgetTester tester) async {
    // Bangun aplikasi dan trigger frame pertama
    await tester.pumpWidget(const SmartPayApp());

    // Verifikasi bahwa judul SmartPay muncul
    expect(find.text('SmartPay'), findsOneWidget);

    // Verifikasi bahwa form buat transaksi muncul
    expect(find.text('Buat Transaksi Baru'), findsOneWidget);
  });
}
