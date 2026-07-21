import 'package:flutter_test/flutter_test.dart';
import 'package:kplayerf/main.dart';

void main() {
  testWidgets('muestra la interfaz del reproductor', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('KPlayerF'), findsOneWidget);
    expect(find.text('Seleccionar vídeo'), findsOneWidget);
  });
}
