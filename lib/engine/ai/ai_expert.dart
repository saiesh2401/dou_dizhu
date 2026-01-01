import 'dart:math';
import '../card_model.dart';
import '../hand_type.dart';
import 'hand_evaluator.dart';
import 'combo_detector.dart';
import 'move_evaluator.dart';

/// Expert-level AI that plays Dou Dizhu using competitive principles
class AiExpert {
  /// Find the best move for the AI player
  static List<CardModel>? findMove(
    List<CardModel> hand,
    HandAnalysis? lastPlayed, {
    int? playerIndex,
    int? landlordIndex,
    int? lastPlayedBy,
    List<int>? opponentHandSizes,
  }) {
    // Create game context
    final context = GameContext(
      playerIndex: playerIndex ?? 1,
      landlordIndex: landlordIndex,
      lastPlayedBy: lastPlayedBy,
      opponentHandSizes: opponentHandSizes ?? [],
      totalCards: hand.length,
    );

    // Evaluate current hand structure
    final handEval = HandEvaluator.evaluate(hand);

    // If no last play, we can lead - choose best opening move
    if (lastPlayed == null) {
      return _findBestOpeningMove(hand, handEval, context);
    }

    // Find all legal moves that can beat last played
    final legalMoves = ComboDetector.findBeatingCombos(hand, lastPlayed);

    if (legalMoves.isEmpty) {
      return null; // Must pass
    }

    // Score each legal move
    final scoredMoves = <_ScoredMove>[];

    for (final move in legalMoves) {
      // Simulate hand after this move
      final cardIds = move.cards.map((c) => c.id).toSet();
      final afterHand = hand.where((c) => !cardIds.contains(c.id)).toList();
      final afterEval = HandEvaluator.evaluate(afterHand);

      // Score this move
      final score = MoveEvaluator.scoreMove(move, handEval, afterEval, context);

      scoredMoves.add(_ScoredMove(move: move, score: score));
    }

    // Also consider passing (strategic passing - Principle 5)
    final passScore = MoveEvaluator.scorePass(handEval, context);
    scoredMoves.add(_ScoredMove(move: null, score: passScore));

    // Sort by score (highest first)
    scoredMoves.sort((a, b) => b.score.compareTo(a.score));

    // Apply expert randomness (Principle 21)
    final bestMove = _selectMoveWithRandomness(scoredMoves);

    return bestMove?.move?.cards;
  }

  /// Find best opening move when AI has the lead
  static List<CardModel> _findBestOpeningMove(
    List<CardModel> hand,
    HandEvaluation handEval,
    GameContext context,
  ) {
    // Find all possible combos
    final allCombos = ComboDetector.findAllCombos(hand);

    // Score each combo
    final scoredMoves = <_ScoredMove>[];

    for (final combo in allCombos) {
      // Simulate hand after this move
      final cardIds = combo.cards.map((c) => c.id).toSet();
      final afterHand = hand.where((c) => !cardIds.contains(c.id)).toList();
      final afterEval = HandEvaluator.evaluate(afterHand);

      // Score this move
      final score = MoveEvaluator.scoreMove(
        combo,
        handEval,
        afterEval,
        context,
      );

      // Bonus for opening with large combos (shed more cards)
      double openingBonus = 0;
      if (combo.type == HandType.straight && combo.length >= 8) {
        openingBonus = 50;
      } else if (combo.type == HandType.consecutivePairs && combo.length >= 6) {
        openingBonus = 40;
      } else if (combo.type == HandType.airplane) {
        openingBonus = 45;
      } else if (combo.type == HandType.tripleWithPair) {
        openingBonus = 25;
      } else if (combo.type == HandType.tripleWithSingle) {
        openingBonus = 20;
      }

      scoredMoves.add(_ScoredMove(move: combo, score: score + openingBonus));
    }

    // Sort by score
    scoredMoves.sort((a, b) => b.score.compareTo(a.score));

    // Select with randomness
    final selected = _selectMoveWithRandomness(scoredMoves);

    // Fallback to lowest single if something went wrong
    return selected?.move?.cards ?? [hand.first];
  }

  /// Select move with expert randomness (Principle 21)
  /// Among top moves within 10% score delta, use softmax sampling
  static _ScoredMove? _selectMoveWithRandomness(List<_ScoredMove> scoredMoves) {
    if (scoredMoves.isEmpty) return null;
    if (scoredMoves.length == 1) return scoredMoves.first;

    final bestScore = scoredMoves.first.score;
    final threshold = bestScore * 0.9;

    // Get top moves within 10% of best
    final topMoves = scoredMoves.where((m) => m.score >= threshold).toList();

    if (topMoves.length == 1) return topMoves.first;

    // Softmax sampling with temperature
    const temperature = 0.3;
    final random = Random();

    // Calculate softmax probabilities
    final expScores = topMoves.map((m) => exp(m.score / temperature)).toList();
    final sumExp = expScores.reduce((a, b) => a + b);
    final probabilities = expScores.map((e) => e / sumExp).toList();

    // Sample based on probabilities
    final rand = random.nextDouble();
    double cumulative = 0;

    for (int i = 0; i < topMoves.length; i++) {
      cumulative += probabilities[i];
      if (rand <= cumulative) {
        return topMoves[i];
      }
    }

    return topMoves.first; // Fallback
  }
}

/// Internal class to hold scored moves
class _ScoredMove {
  final Combo? move; // null for pass
  final double score;

  const _ScoredMove({required this.move, required this.score});

  @override
  String toString() =>
      'ScoredMove(${move?.type.name ?? "PASS"}, score: ${score.toStringAsFixed(1)})';
}
