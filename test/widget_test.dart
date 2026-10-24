
import 'package:flutter_test/flutter_test.dart';
import 'package:tutur/main.dart';

void main() {
  testWidgets('TuturApp menampilkan halaman utama', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TuturApp());

    expect(find.text('Tutur'), findsOneWidget);
    expect(find.text('SIAP'), findsOneWidget);
    expect(find.text('Tahan layar,\nlalu bicara.'), findsOneWidget);
  });
}
