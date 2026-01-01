import 'dart:ui';
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

          // Top bar with game info - Glassmorphism
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => context.go('/'),
                        ),
                        if (state.landlordIndex != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              state.landlordIndex == 0
                                  ? 'You are Landlord'
                                  : 'You are Farmer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                shadows: [
                                  Shadow(color: Colors.black45, blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => ref
                              .read(gameControllerProvider.notifier)
                              .newGame(),
                        ),
                      ],
                    ),
                  ),
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: state.canPass
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8B4513,
                                  ).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: state.canPass
                            ? () => ref
                                  .read(gameControllerProvider.notifier)
                                  .passTurn()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey.shade800,
                          elevation: 0,
                        ),
                        child: const Text(
                          'Pass',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: state.canPlay
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: state.canPlay
                            ? () => ref
                                  .read(gameControllerProvider.notifier)
                                  .playSelected()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: const Color(0xFF0A4D2E),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey.shade800,
                          elevation: 0,
                        ),
                        child: const Text(
                          'Play',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Turn indicator - Glassmorphism
          if (state.phase == GamePhase.playing)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: state.isPlayerTurn
                              ? const Color(0xFFFFD700)
                              : Colors.white.withOpacity(0.4),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: state.isPlayerTurn
                                ? const Color(0xFFFFD700).withOpacity(0.4)
                                : Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        state.isPlayerTurn
                            ? 'Your Turn'
                            : 'Player ${state.currentTurn + 1}\'s Turn',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
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
                          _getGameOverMessage(state),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _didPlayerWin(state)
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

  /// Determine if the player won based on team affiliation
  bool _didPlayerWin(GameState state) {
    if (state.winnerIndex == null || state.landlordIndex == null) return false;

    final isPlayerLandlord = state.landlordIndex == 0;
    final isWinnerLandlord = state.winnerIndex == state.landlordIndex;

    // Player wins if they're on the winning team
    return isPlayerLandlord == isWinnerLandlord;
  }

  /// Get the appropriate game over message
  String _getGameOverMessage(GameState state) {
    if (_didPlayerWin(state)) {
      return state.winnerIndex == 0 ? 'You Win! 🎉' : 'Your Team Wins! 🎉';
    } else {
      return 'You Lose';
    }
  }
}
