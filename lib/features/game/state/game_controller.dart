import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../engine/game_state.dart';
import '../../../engine/deck.dart';
import '../../../engine/ai/ai_expert.dart';
import '../../../engine/card_model.dart';
import '../../../engine/hand_type.dart';

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

    List<CardModel>? aiMove;

    try {
      aiMove = AiExpert.findMove(
        aiHand,
        state.lastPlayedHand,
        playerIndex: aiPlayerIndex,
        landlordIndex: state.landlordIndex,
        lastPlayedBy: state.lastPlayedBy,
        opponentHandSizes: [
          state.playerHands[0].length,
          state.playerHands[1].length,
          state.playerHands[2].length,
        ],
      );
    } catch (e, stackTrace) {
      // If expert AI fails, use simple fallback
      print('Expert AI error: $e');
      print('Stack trace: $stackTrace');
      aiMove = _findSimpleFallbackMove(aiHand, state.lastPlayedHand);
    }

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

  /// Simple fallback move finder (used if expert AI fails)
  List<CardModel>? _findSimpleFallbackMove(
    List<CardModel> hand,
    HandAnalysis? lastPlayed,
  ) {
    // If no last play, play lowest card
    if (lastPlayed == null) {
      return [hand.first];
    }

    // Try to find any legal move
    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final requiredPower = lastPlayed.compareValue;

    // Try to beat based on type
    switch (lastPlayed.type) {
      case HandType.single:
        for (final card in hand) {
          if (card.power > requiredPower) {
            return [card];
          }
        }
        break;

      case HandType.pair:
        for (final power in rankCounts.keys.toList()..sort()) {
          if (rankCounts[power]!.length >= 2 && power > requiredPower) {
            return rankCounts[power]!.take(2).toList();
          }
        }
        break;

      case HandType.triple:
        for (final power in rankCounts.keys.toList()..sort()) {
          if (rankCounts[power]!.length >= 3 && power > requiredPower) {
            return rankCounts[power]!.take(3).toList();
          }
        }
        break;

      default:
        // For complex types, just pass
        break;
    }

    // No legal move found, return null to pass
    return null;
  }

  /// Reset game
  void resetGame() {
    state = GameState.initial();
  }
}
