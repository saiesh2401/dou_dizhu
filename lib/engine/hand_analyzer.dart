import 'card_model.dart';
import 'hand_type.dart';

class HandAnalyzer {
  /// Analyze a list of cards and determine the hand type
  static HandAnalysis analyzeHand(List<CardModel> cards) {
    if (cards.isEmpty) return HandAnalysis.invalid;

    final powers = cards.map((c) => c.power).toList()..sort();
    final count = cards.length;

    // Count occurrences of each rank
    final rankCounts = <int, int>{};
    for (final power in powers) {
      rankCounts[power] = (rankCounts[power] ?? 0) + 1;
    }

    final uniqueRanks = rankCounts.keys.toList()..sort();
    final counts = rankCounts.values.toList()..sort();

    // Single
    if (count == 1) {
      return HandAnalysis(type: HandType.single, primaryCards: [powers[0]]);
    }

    // Pair
    if (count == 2 && counts[0] == 2) {
      return HandAnalysis(type: HandType.pair, primaryCards: [powers[0]]);
    }

    // Rocket (both jokers)
    if (count == 2 && powers.contains(16) && powers.contains(17)) {
      return HandAnalysis(type: HandType.rocket, primaryCards: [16, 17]);
    }

    // Triple
    if (count == 3 && counts[0] == 3) {
      return HandAnalysis(type: HandType.triple, primaryCards: [powers[0]]);
    }

    // Triple with single (3+1)
    if (count == 4 && counts.contains(3) && counts.contains(1)) {
      final triple = uniqueRanks.firstWhere((r) => rankCounts[r] == 3);
      final single = uniqueRanks.firstWhere((r) => rankCounts[r] == 1);
      return HandAnalysis(
        type: HandType.tripleWithSingle,
        primaryCards: [triple],
        kickerCards: [single],
      );
    }

    // Bomb (4 of a kind)
    if (count == 4 && counts[0] == 4) {
      return HandAnalysis(type: HandType.bomb, primaryCards: [powers[0]]);
    }

    // Triple with pair (3+2)
    if (count == 5 && counts.contains(3) && counts.contains(2)) {
      final triple = uniqueRanks.firstWhere((r) => rankCounts[r] == 3);
      final pair = uniqueRanks.firstWhere((r) => rankCounts[r] == 2);
      return HandAnalysis(
        type: HandType.tripleWithPair,
        primaryCards: [triple],
        kickerCards: [pair],
      );
    }

    // Straight (5+ consecutive cards, no 2s or jokers)
    if (count >= 5 && _isStraight(uniqueRanks, count)) {
      return HandAnalysis(
        type: HandType.straight,
        primaryCards: uniqueRanks,
        length: count,
        baseRank: uniqueRanks.first,
      );
    }

    // Consecutive pairs (3+ pairs)
    if (count >= 6 && count % 2 == 0) {
      final pairAnalysis = _analyzeConsecutivePairs(rankCounts, uniqueRanks);
      if (pairAnalysis != null) return pairAnalysis;
    }

    // Airplane (2+ consecutive triples)
    if (count >= 6 && count % 3 == 0) {
      final airplaneAnalysis = _analyzeAirplane(rankCounts, uniqueRanks, count);
      if (airplaneAnalysis != null) return airplaneAnalysis;
    }

    // Quad with singles (4+1+1)
    if (count == 6) {
      final quadAnalysis = _analyzeQuadWithSingles(rankCounts, uniqueRanks);
      if (quadAnalysis != null) return quadAnalysis;
    }

    // Quad with pairs (4+2+2)
    if (count == 8) {
      final quadPairAnalysis = _analyzeQuadWithPairs(rankCounts, uniqueRanks);
      if (quadPairAnalysis != null) return quadPairAnalysis;
    }

    // Airplane with kickers
    if (count >= 8) {
      final airplaneKickerAnalysis = _analyzeAirplaneWithKickers(
        rankCounts,
        uniqueRanks,
        count,
      );
      if (airplaneKickerAnalysis != null) return airplaneKickerAnalysis;
    }

    return HandAnalysis.invalid;
  }

  /// Check if ranks form a straight (consecutive, no 2s or jokers)
  static bool _isStraight(List<int> ranks, int expectedLength) {
    if (ranks.length != expectedLength) return false;
    if (ranks.any((r) => r >= 15)) return false; // No 2s or jokers in straights

    for (int i = 1; i < ranks.length; i++) {
      if (ranks[i] != ranks[i - 1] + 1) return false;
    }
    return true;
  }

  /// Analyze consecutive pairs (e.g., 334455)
  static HandAnalysis? _analyzeConsecutivePairs(
    Map<int, int> rankCounts,
    List<int> uniqueRanks,
  ) {
    final pairs = uniqueRanks.where((r) => rankCounts[r] == 2).toList();
    if (pairs.length < 3) return null;
    if (pairs.any((r) => r >= 15)) return null; // No 2s or jokers

    // Check if pairs are consecutive
    if (!_isStraight(pairs, pairs.length)) return null;

    return HandAnalysis(
      type: HandType.consecutivePairs,
      primaryCards: pairs,
      length: pairs.length,
      baseRank: pairs.first,
    );
  }

  /// Analyze airplane (2+ consecutive triples)
  static HandAnalysis? _analyzeAirplane(
    Map<int, int> rankCounts,
    List<int> uniqueRanks,
    int totalCount,
  ) {
    final triples = uniqueRanks.where((r) => rankCounts[r] == 3).toList();
    if (triples.length < 2) return null;
    if (triples.any((r) => r >= 15)) return null; // No 2s or jokers

    // Check if triples are consecutive
    if (!_isStraight(triples, triples.length)) return null;

    // Pure airplane (no kickers)
    if (totalCount == triples.length * 3) {
      return HandAnalysis(
        type: HandType.airplane,
        primaryCards: triples,
        length: triples.length,
        baseRank: triples.first,
      );
    }

    return null;
  }

  /// Analyze quad with singles (4+1+1)
  static HandAnalysis? _analyzeQuadWithSingles(
    Map<int, int> rankCounts,
    List<int> uniqueRanks,
  ) {
    final quads = uniqueRanks.where((r) => rankCounts[r] == 4).toList();
    final singles = uniqueRanks.where((r) => rankCounts[r] == 1).toList();

    if (quads.length == 1 && singles.length == 2) {
      return HandAnalysis(
        type: HandType.quadWithSingles,
        primaryCards: [quads[0]],
        kickerCards: singles,
      );
    }
    return null;
  }

  /// Analyze quad with pairs (4+2+2)
  static HandAnalysis? _analyzeQuadWithPairs(
    Map<int, int> rankCounts,
    List<int> uniqueRanks,
  ) {
    final quads = uniqueRanks.where((r) => rankCounts[r] == 4).toList();
    final pairs = uniqueRanks.where((r) => rankCounts[r] == 2).toList();

    if (quads.length == 1 && pairs.length == 2) {
      return HandAnalysis(
        type: HandType.quadWithPairs,
        primaryCards: [quads[0]],
        kickerCards: pairs,
      );
    }
    return null;
  }

  /// Analyze airplane with kickers (singles or pairs)
  static HandAnalysis? _analyzeAirplaneWithKickers(
    Map<int, int> rankCounts,
    List<int> uniqueRanks,
    int totalCount,
  ) {
    final triples = uniqueRanks.where((r) => rankCounts[r] == 3).toList();
    if (triples.length < 2) return null;
    if (triples.any((r) => r >= 15)) return null;

    // Check if triples are consecutive
    if (!_isStraight(triples, triples.length)) return null;

    final tripleCount = triples.length;
    final kickerCount = totalCount - (tripleCount * 3);

    // Airplane with singles
    if (kickerCount == tripleCount) {
      final kickers = <int>[];
      for (final rank in uniqueRanks) {
        if (!triples.contains(rank)) {
          for (int i = 0; i < rankCounts[rank]!; i++) {
            kickers.add(rank);
          }
        }
      }
      if (kickers.length == tripleCount) {
        return HandAnalysis(
          type: HandType.airplaneWithSingles,
          primaryCards: triples,
          kickerCards: kickers,
          length: tripleCount,
          baseRank: triples.first,
        );
      }
    }

    // Airplane with pairs
    if (kickerCount == tripleCount * 2) {
      final pairs = uniqueRanks
          .where((r) => !triples.contains(r) && rankCounts[r] == 2)
          .toList();
      if (pairs.length == tripleCount) {
        return HandAnalysis(
          type: HandType.airplaneWithPairs,
          primaryCards: triples,
          kickerCards: pairs,
          length: tripleCount,
          baseRank: triples.first,
        );
      }
    }

    return null;
  }
}
