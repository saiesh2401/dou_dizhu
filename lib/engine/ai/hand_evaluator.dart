import '../card_model.dart';

/// Represents a straight core (consecutive cards) worth preserving
class StraightCore {
  final int startRank;
  final int length;
  final List<int> ranks;

  const StraightCore({
    required this.startRank,
    required this.length,
    required this.ranks,
  });

  int get endRank => startRank + length - 1;
  int get value => length * 10; // Longer straights are more valuable

  bool containsRank(int rank) => ranks.contains(rank);
}

/// Represents consecutive pairs worth preserving
class ConsecutivePairsCore {
  final int startRank;
  final int pairCount;
  final List<int> ranks;

  const ConsecutivePairsCore({
    required this.startRank,
    required this.pairCount,
    required this.ranks,
  });

  int get value => pairCount * 15;
  bool containsRank(int rank) => ranks.contains(rank);
}

/// Represents airplane core (consecutive triples) worth preserving
class AirplaneCore {
  final int startRank;
  final int tripleCount;
  final List<int> ranks;

  const AirplaneCore({
    required this.startRank,
    required this.tripleCount,
    required this.ranks,
  });

  int get value => tripleCount * 20;
  bool containsRank(int rank) => ranks.contains(rank);
}

/// Comprehensive evaluation of a hand's structure
class HandEvaluation {
  // Basic counts by rank
  final Map<int, int> rankCounts;
  final Map<int, List<CardModel>> cardsByRank;

  // Categorized cards
  final List<int> singles; // Ranks that appear once
  final List<int> pairs; // Ranks that appear twice
  final List<int> triples; // Ranks that appear 3 times
  final List<int> quads; // Ranks that appear 4 times

  // Valuable structures (cores)
  final List<StraightCore> straightCores;
  final List<ConsecutivePairsCore> consecPairsCores;
  final List<AirplaneCore> airplaneCores;

  // Strategic metrics
  final List<int> trashSingles; // Singles 3-10 not in straights
  final List<int> controlCards; // A(14), 2(15), SmallJoker(16), BigJoker(17)
  final int controlCardCount;
  final bool hasBomb;
  final bool hasRocket;

  // Exit planning
  final int totalCards;
  final int minTurnsToEmpty;

  const HandEvaluation({
    required this.rankCounts,
    required this.cardsByRank,
    required this.singles,
    required this.pairs,
    required this.triples,
    required this.quads,
    required this.straightCores,
    required this.consecPairsCores,
    required this.airplaneCores,
    required this.trashSingles,
    required this.controlCards,
    required this.controlCardCount,
    required this.hasBomb,
    required this.hasRocket,
    required this.totalCards,
    required this.minTurnsToEmpty,
  });

  /// Get all ranks that are part of any core structure
  Set<int> getCoreRanks() {
    final coreRanks = <int>{};
    for (final core in straightCores) {
      coreRanks.addAll(core.ranks);
    }
    for (final core in consecPairsCores) {
      coreRanks.addAll(core.ranks);
    }
    for (final core in airplaneCores) {
      coreRanks.addAll(core.ranks);
    }
    return coreRanks;
  }

  /// Check if a rank is part of a core structure
  bool isPartOfCore(int rank) {
    return straightCores.any((c) => c.containsRank(rank)) ||
        consecPairsCores.any((c) => c.containsRank(rank)) ||
        airplaneCores.any((c) => c.containsRank(rank));
  }

  /// Get quality score for this hand (higher = better structure)
  double get qualityScore {
    double score = 0;

    // Reward valuable cores
    for (final core in straightCores) {
      score += core.value;
    }
    for (final core in consecPairsCores) {
      score += core.value;
    }
    for (final core in airplaneCores) {
      score += core.value;
    }

    // Penalize trash singles
    score -= trashSingles.length * 5;

    // Reward control cards
    score += controlCardCount * 10;

    // Reward bombs and rockets
    if (hasBomb) score += 30;
    if (hasRocket) score += 50;

    return score;
  }
}

/// Evaluates hand structure and identifies strategic elements
class HandEvaluator {
  /// Analyze a hand and return comprehensive evaluation
  static HandEvaluation evaluate(List<CardModel> hand) {
    // Build rank counts and card mapping
    final rankCounts = <int, int>{};
    final cardsByRank = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts[card.power] = (rankCounts[card.power] ?? 0) + 1;
      cardsByRank.putIfAbsent(card.power, () => []).add(card);
    }

    // Categorize by count
    final singles = <int>[];
    final pairs = <int>[];
    final triples = <int>[];
    final quads = <int>[];

    for (final entry in rankCounts.entries) {
      switch (entry.value) {
        case 1:
          singles.add(entry.key);
          break;
        case 2:
          pairs.add(entry.key);
          break;
        case 3:
          triples.add(entry.key);
          break;
        case 4:
          quads.add(entry.key);
          break;
      }
    }

    // Sort all lists
    singles.sort();
    pairs.sort();
    triples.sort();
    quads.sort();

    // Detect cores
    final straightCores = _detectStraightCores(rankCounts);
    final consecPairsCores = _detectConsecutivePairsCores(pairs);
    final airplaneCores = _detectAirplaneCores(triples);

    // Identify trash singles (3-10 not in straights or cores)
    final coreRanks = <int>{};
    for (final core in straightCores) {
      coreRanks.addAll(core.ranks);
    }

    final trashSingles = singles.where((rank) {
      return rank >= 3 && rank <= 10 && !coreRanks.contains(rank);
    }).toList();

    // Identify control cards (A=14, 2=15, SmallJoker=16, BigJoker=17)
    final controlCards = <int>[];
    for (final rank in rankCounts.keys) {
      if (rank >= 14) {
        // Add each card of this rank
        for (int i = 0; i < rankCounts[rank]!; i++) {
          controlCards.add(rank);
        }
      }
    }
    controlCards.sort();

    // Check for bombs and rocket
    final hasBomb = quads.isNotEmpty;
    final hasRocket = singles.contains(16) && singles.contains(17);

    // Calculate minimum turns to empty (rough estimate)
    final minTurns = _estimateMinTurns(
      hand.length,
      straightCores,
      consecPairsCores,
      airplaneCores,
      singles.length,
      pairs.length,
      triples.length,
    );

    return HandEvaluation(
      rankCounts: rankCounts,
      cardsByRank: cardsByRank,
      singles: singles,
      pairs: pairs,
      triples: triples,
      quads: quads,
      straightCores: straightCores,
      consecPairsCores: consecPairsCores,
      airplaneCores: airplaneCores,
      trashSingles: trashSingles,
      controlCards: controlCards,
      controlCardCount: controlCards.length,
      hasBomb: hasBomb,
      hasRocket: hasRocket,
      totalCards: hand.length,
      minTurnsToEmpty: minTurns,
    );
  }

  /// Detect all straight cores (5+ consecutive cards, excluding 2s and Jokers)
  static List<StraightCore> _detectStraightCores(Map<int, int> rankCounts) {
    final cores = <StraightCore>[];
    final availableRanks = rankCounts.keys.where((r) => r < 15).toList()
      ..sort();

    // Find all straights of length 5-12
    for (int length = 12; length >= 5; length--) {
      for (int i = 0; i <= availableRanks.length - length; i++) {
        final startRank = availableRanks[i];
        final ranks = <int>[];
        bool isConsecutive = true;

        for (int j = 0; j < length; j++) {
          final expectedRank = startRank + j;
          if (rankCounts.containsKey(expectedRank)) {
            ranks.add(expectedRank);
          } else {
            isConsecutive = false;
            break;
          }
        }

        if (isConsecutive && ranks.length == length) {
          // Check if this core overlaps with existing cores
          final overlaps = cores.any(
            (c) => c.ranks.any((r) => ranks.contains(r)) && c.length >= length,
          );

          if (!overlaps) {
            cores.add(
              StraightCore(startRank: startRank, length: length, ranks: ranks),
            );
          }
        }
      }
    }

    // Sort by value (longer straights first)
    cores.sort((a, b) => b.value.compareTo(a.value));
    return cores;
  }

  /// Detect consecutive pairs cores (3+ consecutive pairs)
  static List<ConsecutivePairsCore> _detectConsecutivePairsCores(
    List<int> pairs,
  ) {
    final cores = <ConsecutivePairsCore>[];
    if (pairs.length < 3) return cores;

    // Find all consecutive sequences in pairs
    for (int length = pairs.length; length >= 3; length--) {
      for (int i = 0; i <= pairs.length - length; i++) {
        final startRank = pairs[i];
        final ranks = <int>[];
        bool isConsecutive = true;

        for (int j = 0; j < length; j++) {
          final expectedRank = startRank + j;
          if (i + j < pairs.length && pairs[i + j] == expectedRank) {
            ranks.add(expectedRank);
          } else {
            isConsecutive = false;
            break;
          }
        }

        if (isConsecutive && ranks.length == length) {
          // Check for overlaps
          final overlaps = cores.any(
            (c) =>
                c.ranks.any((r) => ranks.contains(r)) && c.pairCount >= length,
          );

          if (!overlaps) {
            cores.add(
              ConsecutivePairsCore(
                startRank: startRank,
                pairCount: length,
                ranks: ranks,
              ),
            );
          }
        }
      }
    }

    cores.sort((a, b) => b.value.compareTo(a.value));
    return cores;
  }

  /// Detect airplane cores (2+ consecutive triples)
  static List<AirplaneCore> _detectAirplaneCores(List<int> triples) {
    final cores = <AirplaneCore>[];
    if (triples.length < 2) return cores;

    // Find all consecutive sequences in triples
    for (int length = triples.length; length >= 2; length--) {
      for (int i = 0; i <= triples.length - length; i++) {
        final startRank = triples[i];
        final ranks = <int>[];
        bool isConsecutive = true;

        for (int j = 0; j < length; j++) {
          final expectedRank = startRank + j;
          if (i + j < triples.length && triples[i + j] == expectedRank) {
            ranks.add(expectedRank);
          } else {
            isConsecutive = false;
            break;
          }
        }

        if (isConsecutive && ranks.length == length) {
          final overlaps = cores.any(
            (c) =>
                c.ranks.any((r) => ranks.contains(r)) &&
                c.tripleCount >= length,
          );

          if (!overlaps) {
            cores.add(
              AirplaneCore(
                startRank: startRank,
                tripleCount: length,
                ranks: ranks,
              ),
            );
          }
        }
      }
    }

    cores.sort((a, b) => b.value.compareTo(a.value));
    return cores;
  }

  /// Estimate minimum turns to empty hand (greedy approximation)
  static int _estimateMinTurns(
    int totalCards,
    List<StraightCore> straights,
    List<ConsecutivePairsCore> consecPairs,
    List<AirplaneCore> airplanes,
    int singleCount,
    int pairCount,
    int tripleCount,
  ) {
    int turns = 0;
    int cardsAccountedFor = 0;

    // Count best straight
    if (straights.isNotEmpty) {
      turns++;
      cardsAccountedFor += straights.first.length;
    }

    // Count best consecutive pairs
    if (consecPairs.isNotEmpty) {
      turns++;
      cardsAccountedFor += consecPairs.first.pairCount * 2;
    }

    // Count best airplane
    if (airplanes.isNotEmpty) {
      turns++;
      cardsAccountedFor += airplanes.first.tripleCount * 3;
    }

    // Assume we can attach some singles/pairs to triples
    final attachableSingles = (tripleCount * 1).clamp(0, singleCount);
    final attachablePairs = (tripleCount * 1).clamp(0, pairCount);

    // Triples with attachments
    final triplesWithAttachments =
        (tripleCount - (airplanes.isNotEmpty ? airplanes.first.tripleCount : 0))
            .clamp(0, tripleCount);
    turns += triplesWithAttachments;

    // Remaining pairs
    final remainingPairs = pairCount - attachablePairs;
    turns += remainingPairs;

    // Remaining singles
    final remainingSingles = singleCount - attachableSingles;
    turns += remainingSingles;

    // Handle empty hand case
    if (totalCards == 0) return 0;

    return turns.clamp(1, totalCards);
  }
}
