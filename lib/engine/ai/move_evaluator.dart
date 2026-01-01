import '../hand_type.dart';
import 'hand_evaluator.dart';
import 'combo_detector.dart';

/// Game context needed for strategic decisions
class GameContext {
  final int playerIndex;
  final int? landlordIndex;
  final int? lastPlayedBy;
  final List<int> opponentHandSizes;
  final int passCount;
  final int totalCards;

  const GameContext({
    required this.playerIndex,
    this.landlordIndex,
    this.lastPlayedBy,
    required this.opponentHandSizes,
    this.passCount = 0,
    required this.totalCards,
  });

  bool get isLandlord => landlordIndex != null && playerIndex == landlordIndex;

  bool get isTeammate {
    if (landlordIndex == null || lastPlayedBy == null) return false;
    // Both are farmers (not landlord)
    return playerIndex != landlordIndex && lastPlayedBy != landlordIndex;
  }

  int get minOpponentCards => opponentHandSizes.isEmpty
      ? 99
      : opponentHandSizes.reduce((a, b) => a < b ? a : b);

  bool get opponentNearWin => minOpponentCards <= 3;

  GamePhase get phase {
    if (totalCards >= 12) return GamePhase.early;
    if (totalCards >= 6) return GamePhase.mid;
    return GamePhase.late;
  }
}

enum GamePhase { early, mid, late }

/// Evaluates and scores moves based on expert principles
class MoveEvaluator {
  /// Score a move based on all expert principles
  static double scoreMove(
    Combo move,
    HandEvaluation beforeHand,
    HandEvaluation afterHand,
    GameContext context,
  ) {
    double score = 0;

    // 1. Structure Preservation Score (-100 to 0)
    score += _scoreStructurePreservation(move, beforeHand, afterHand);

    // 2. Trash Single Reduction Score (0 to +50)
    score += _scoreTrashSingleReduction(move, beforeHand, afterHand);

    // 3. Initiative Value Score (-30 to +80)
    score += _scoreInitiativeValue(move, afterHand, context);

    // 4. Control Card Discipline Score (-80 to +20)
    score += _scoreControlDiscipline(move, beforeHand, context);

    // 5. Exit Plan Improvement Score (0 to +60)
    score += _scoreExitPlanImprovement(beforeHand, afterHand);

    // 6. Minimum Winning Response Bonus (0 to +30)
    score += _scoreMinimumResponse(move);

    // Apply stage-based multipliers
    score = _applyStageMultipliers(score, context.phase, move.type);

    return score;
  }

  /// Score structure preservation (Principle 1)
  /// Penalize breaking valuable cores
  static double _scoreStructurePreservation(
    Combo move,
    HandEvaluation beforeHand,
    HandEvaluation afterHand,
  ) {
    double penalty = 0;

    // Get ranks used in this move
    final usedRanks = move.cards.map((c) => c.power).toSet();

    // Check if we broke any straight cores
    for (final core in beforeHand.straightCores) {
      final ranksUsed = core.ranks.where((r) => usedRanks.contains(r)).length;
      if (ranksUsed > 0 && ranksUsed < core.length) {
        // Broke a straight core (didn't play it whole)
        penalty -= 50 * (core.length / 12); // Longer straights = worse penalty
      }
    }

    // Check if we broke consecutive pairs cores
    for (final core in beforeHand.consecPairsCores) {
      final ranksUsed = core.ranks.where((r) => usedRanks.contains(r)).length;
      if (ranksUsed > 0 && ranksUsed < core.pairCount) {
        penalty -= 40 * (core.pairCount / 10);
      }
    }

    // Check if we broke airplane cores
    for (final core in beforeHand.airplaneCores) {
      final ranksUsed = core.ranks.where((r) => usedRanks.contains(r)).length;
      if (ranksUsed > 0 && ranksUsed < core.tripleCount) {
        penalty -= 60 * (core.tripleCount / 6);
      }
    }

    // Penalize splitting pairs unnecessarily
    for (final pairRank in beforeHand.pairs) {
      if (usedRanks.contains(pairRank)) {
        final cardsUsed = move.cards.where((c) => c.power == pairRank).length;
        if (cardsUsed == 1) {
          // Split a pair to play a single
          penalty -= 20;
        }
      }
    }

    return penalty;
  }

  /// Score trash single reduction (Principle 2)
  /// Reward getting rid of trash singles
  static double _scoreTrashSingleReduction(
    Combo move,
    HandEvaluation beforeHand,
    HandEvaluation afterHand,
  ) {
    double score = 0;

    final trashBefore = beforeHand.trashSingles.length;
    final trashAfter = afterHand.trashSingles.length;
    final trashReduced = trashBefore - trashAfter;

    if (trashReduced > 0) {
      // Reward using trash singles
      score += trashReduced * 30;
    }

    // Bonus for using trash singles as attachments
    if (move.type == HandType.tripleWithSingle ||
        move.type == HandType.airplaneWithSingles) {
      final usedRanks = move.cards.map((c) => c.power).toSet();
      final trashUsed = beforeHand.trashSingles
          .where((r) => usedRanks.contains(r))
          .length;
      score += trashUsed * 10;
    }

    // Reward playing straights that include trash ranks
    if (move.type == HandType.straight) {
      final usedRanks = move.cards.map((c) => c.power).toSet();
      final trashInStraight = beforeHand.trashSingles
          .where((r) => usedRanks.contains(r))
          .length;
      score += trashInStraight * 20;
    }

    return score;
  }

  /// Score initiative value (Principle 3)
  /// Value winning tricks that enable good follow-ups
  static double _scoreInitiativeValue(
    Combo move,
    HandEvaluation afterHand,
    GameContext context,
  ) {
    double score = 0;

    // If we can dump a lot of cards after winning, high value
    if (afterHand.straightCores.isNotEmpty) {
      final longestStraight = afterHand.straightCores.first.length;
      if (longestStraight >= 8) {
        score += 80; // Can dump 8+ cards next
      } else if (longestStraight >= 5) {
        score += 40;
      }
    }

    if (afterHand.consecPairsCores.isNotEmpty) {
      final longestPairs = afterHand.consecPairsCores.first.pairCount;
      if (longestPairs >= 5) {
        score += 60;
      } else if (longestPairs >= 3) {
        score += 30;
      }
    }

    if (afterHand.airplaneCores.isNotEmpty) {
      score += 70;
    }

    // If we're left with weak hand after winning, negative value
    if (afterHand.trashSingles.length > 3 && afterHand.controlCardCount == 0) {
      score -= 30;
    }

    return score;
  }

  /// Score control card discipline (Principles 4, 12)
  /// Penalize wasting bombs/2s/Jokers early
  static double _scoreControlDiscipline(
    Combo move,
    HandEvaluation beforeHand,
    GameContext context,
  ) {
    double score = 0;

    // Check if using bombs
    if (move.type == HandType.bomb || move.type == HandType.rocket) {
      if (context.phase == GamePhase.early) {
        // Heavy penalty for bombing early
        score -= 80;
      } else if (context.phase == GamePhase.mid) {
        score -= 40;
      } else {
        // Late game - bombs are okay
        score += 20;
      }

      // Exception: if opponent near win, bombing is justified
      if (context.opponentNearWin) {
        score += 60; // Offset penalty
      }
    }

    // Check if using 2s or Jokers
    final usedRanks = move.cards.map((c) => c.power).toSet();
    final using2s = usedRanks.contains(15);
    final usingJokers = usedRanks.contains(16) || usedRanks.contains(17);

    if (using2s || usingJokers) {
      if (context.phase == GamePhase.early && move.type != HandType.bomb) {
        score -= 40; // Wasting control cards early
      } else if (context.phase == GamePhase.late) {
        score += 10; // Good to use them late
      }
    }

    // Reward saving control for critical moments
    if (beforeHand.controlCardCount > 0 &&
        !using2s &&
        !usingJokers &&
        move.type != HandType.bomb) {
      score += 10;
    }

    return score;
  }

  /// Score exit plan improvement (Principle 7)
  /// Reward moves that reduce turns to empty
  static double _scoreExitPlanImprovement(
    HandEvaluation beforeHand,
    HandEvaluation afterHand,
  ) {
    final turnsBefore = beforeHand.minTurnsToEmpty;
    final turnsAfter = afterHand.minTurnsToEmpty;
    final improvement = turnsBefore - turnsAfter;

    if (improvement > 0) {
      return improvement * 60;
    }

    // Reward maintaining good structure
    if (afterHand.qualityScore > beforeHand.qualityScore * 0.8) {
      return 20;
    }

    return 0;
  }

  /// Score minimum winning response (Principle 15)
  /// Reward beating by smallest margin
  static double _scoreMinimumResponse(Combo move) {
    // This is a relative score - prefer lower power cards
    // when multiple options exist
    if (move.type == HandType.single) {
      // Lower singles are better (when they can beat)
      return (20 - move.compareValue) * 1.5;
    }

    if (move.type == HandType.pair || move.type == HandType.triple) {
      return (20 - move.compareValue) * 1.0;
    }

    // For combos, prefer shorter/smaller ones
    if (move.type == HandType.straight) {
      return (15 - move.length) * 2;
    }

    return 0;
  }

  /// Apply stage-based multipliers (Principle 20)
  static double _applyStageMultipliers(
    double baseScore,
    GamePhase phase,
    HandType moveType,
  ) {
    // These multipliers are applied to specific score components
    // For simplicity, we apply a general adjustment here

    switch (phase) {
      case GamePhase.early:
        // Early: preserve structure, save control
        if (moveType == HandType.bomb || moveType == HandType.rocket) {
          return baseScore * 0.5; // Really avoid bombs early
        }
        return baseScore * 1.2; // Slightly favor conservative plays

      case GamePhase.mid:
        // Mid: balance structure and initiative
        return baseScore * 1.0;

      case GamePhase.late:
        // Late: power dominates, use control cards
        if (moveType == HandType.bomb || moveType == HandType.rocket) {
          return baseScore * 1.5; // Bombs are good late
        }
        return baseScore * 1.3; // Favor aggressive plays
    }
  }

  /// Score a pass move (strategic passing - Principle 5)
  static double scorePass(HandEvaluation currentHand, GameContext context) {
    double score = 0;

    // Passing preserves structure
    score += 20;

    // If teammate played, let them continue
    if (context.isTeammate && currentHand.totalCards > 5) {
      score += 40;
    }

    // If we have weak hand, passing is good
    if (currentHand.trashSingles.length > 4) {
      score += 30;
    }

    // If opponent near win, passing is bad
    if (context.opponentNearWin) {
      score -= 60;
    }

    // If we have strong control, passing is okay
    if (currentHand.controlCardCount >= 3) {
      score += 25;
    }

    return score;
  }
}
