import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade_ledger/core/router/app_router.dart';
import 'package:kade_ledger/main.dart';

void main() {
  testWidgets('Home screen builds and displays title and placeholder text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: KadeLedgerApp()));
    await tester.pumpAndSettle();

    expect(find.byType(HomePlaceholderScreen), findsOneWidget);
    expect(find.text(HomePlaceholderScreen.appTitle), findsOneWidget);
    expect(find.text(HomePlaceholderScreen.welcomeMessage), findsOneWidget);
  });
}
