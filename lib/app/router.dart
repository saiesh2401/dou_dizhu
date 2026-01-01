import 'package:go_router/go_router.dart';

import '../features/menu/menu_screen.dart';
import '../features/game/presentation/game_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'menu',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/game',
      name: 'game',
      builder: (context, state) => const GameScreen(),
    ),
  ],
);
