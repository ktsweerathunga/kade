import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePlaceholderScreen(),
      ),
    ],
  );
});

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  static const String appTitle = 'Kade Ledger';
  static const String welcomeMessage = 'Kade Ledger — Ready for Phase 1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appTitle)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(welcomeMessage, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
