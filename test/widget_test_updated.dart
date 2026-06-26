import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_dhikr/main.dart';

void main() {
  testWidgets('shows bottom navigation with all tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MyApp(data: {'quote': 'سبحان الله', 'source': 'Dhikr'}),
      ),
    );

    expect(find.text('Dhikr'), findsWidgets);
    expect(find.text('Rappels'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
  });
}
