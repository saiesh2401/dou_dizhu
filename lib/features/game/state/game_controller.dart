import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../engine/game_state.dart';
import '../../../engine/deck.dart';
import '../../../engine/ai/ai_easy.dart';

class GameController extends Notifier<GameState> {
  @override
  GameState build() {
    return GameState.initial();
  }

  /// Start a new game
  void newGame() {
    final deck = Deck.standard54()..shuffle();
    final deal = deck.deal3Players();

    // For MVP, automatically make player 1 the landlord
    state = state.startNewRound(deal);

    // Auto-bid: player 1 becomes landlord
    Future.delayed(const Duration(milliseconds: 500), () {
      state = state.processBid(1, BidAction.call);

      // Start AI turn processing
      _processAiTurns();
    });
  }

  /// Toggle card selection for player 0
  void toggleSelect(String cardId) {
    if (state.currentTurn != 0 || state.phase != GamePhase.playing) return;
    state = state.toggleSelect(cardId);
  }

  /// Player attempts to play selected cards
  void playSelected() {
    if (state.currentTurn != 0) return;

    final result = state.tryPlaySelected();

    if (result.isOk && result.nextState != null) {
      state = result.nextState!;

      // Check if game is over
      if (state.phase == GamePhase.gameOver) {
        return;
      }

      // Process AI turns
      Future.delayed(const Duration(milliseconds: 500), _processAiTurns);
    } else if (result.errorMessage != null) {
      state = state.withUiMessage(result.errorMessage!);
      // Clear message after showing
      Future.delayed(const Duration(seconds: 2), () {
        if (state.uiMessage == result.errorMessage) {
          state = state.copyWith(uiMessage: '');
        }
      });
    }
  }

  /// Player passes turn
  void passTurn() {
    if (state.currentTurn != 0) return;

    state = state.passTurn();

    // Process AI turns
    Future.delayed(const Duration(milliseconds: 500), _processAiTurns);
  }

  /// Process AI turns (players 1 and 2)
  void _processAiTurns() {
    if (state.phase != GamePhase.playing) return;
    if (state.currentTurn == 0) return; // Player's turn

    // AI makes a move
    final aiPlayerIndex = state.currentTurn;
    final aiHand = state.playerHands[aiPlayerIndex];

    final aiMove = AiEasy.findMove(aiHand, state.lastPlayedHand);

    if (aiMove != null) {
      // AI plays cards
      state = state.aiPlay(aiPlayerIndex, aiMove);

      // Check if game is over
      if (state.phase == GamePhase.gameOver) {
        return;
      }

      // Continue processing AI turns if next player is also AI
      if (state.currentTurn != 0) {
        Future.delayed(const Duration(milliseconds: 800), _processAiTurns);
      }
    } else {
      // AI passes
      state = state.passTurn();

      // Continue processing AI turns if next player is also AI
      if (state.currentTurn != 0) {
        Future.delayed(const Duration(milliseconds: 800), _processAiTurns);
      }
    }
  }

  /// Reset game
  void resetGame() {
    state = GameState.initial();
  }
}
