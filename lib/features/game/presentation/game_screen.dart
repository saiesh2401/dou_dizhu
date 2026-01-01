import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../engine/game_state.dart';
import '../state/game_providers.dart';
import '../../../game/dou_dizhu_game.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final DouDizhuGame flameGame;

  @override
  void initState() {
    super.initState();

    // Create Flame game with callbacks
    flameGame = DouDizhuGame(
      readGameState: () => ref.read(gameControllerProvider),
      onCardTapped: (cardId) =>
          ref.read(gameControllerProvider.notifier).toggleSelect(cardId),
    );

    // Start a new game after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameControllerProvider.notifier).newGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);

    // Listen for state changes and update Flame game
    ref.listen(gameControllerProvider, (prev, next) {
      flameGame.onStateChanged(next);

      // Show UI messages
      final msg = next.uiMessage;
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 2),
            backgroundColor: msg.contains('win') ? Colors.green : Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Flame game
          GameWidget(game: flameGame),

          // Top bar with game info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.go('/'),
                    ),
                    if (state.landlordIndex != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          state.landlordIndex == 0
                              ? 'You are Landlord'
                              : 'You are Farmer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () =>
                          ref.read(gameControllerProvider.notifier).newGame(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom HUD with action buttons
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: state.canPass
                          ? () => ref
                                .read(gameControllerProvider.notifier)
                                .passTurn()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade700,
                      ),
                      child: const Text(
                        'Pass',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: state.canPlay
                          ? () => ref
                                .read(gameControllerProvider.notifier)
                                .playSelected()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF0A4D2E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade700,
                      ),
                      child: const Text(
                        'Play',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Turn indicator
          if (state.phase == GamePhase.playing)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: state.isPlayerTurn
                          ? const Color(0xFFFFD700)
                          : Colors.white54,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    state.isPlayerTurn
                        ? 'Your Turn'
                        : 'Player ${state.currentTurn + 1}\'s Turn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Game over overlay
          if (state.phase == GamePhase.gameOver)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.winnerIndex == 0 ? 'You Win! 🎉' : 'You Lose',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: state.winnerIndex == 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(gameControllerProvider.notifier)
                              .newGame(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: const Color(0xFF0A4D2E),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Play Again',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
