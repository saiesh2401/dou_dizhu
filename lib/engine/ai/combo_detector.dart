import '../card_model.dart';
import '../hand_type.dart';
import '../hand_analyzer.dart';

/// Represents a possible combo that can be played
class Combo {
  final List<CardModel> cards;
  final HandAnalysis analysis;

  const Combo({required this.cards, required this.analysis});

  HandType get type => analysis.type;
  int get compareValue => analysis.compareValue;
  int get length => cards.length;

  @override
  String toString() => 'Combo(${type.name}, ${cards.length} cards)';
}

/// Detects all possible legal combos in a hand
class ComboDetector {
  /// Find all possible combos that can be played from this hand
  static List<Combo> findAllCombos(List<CardModel> hand) {
    final combos = <Combo>[];

    // Singles
    combos.addAll(_findAllSingles(hand));

    // Pairs
    combos.addAll(_findAllPairs(hand));

    // Triples
    combos.addAll(_findAllTriples(hand));

    // Triple + Single
    combos.addAll(_findAllTripleWithSingle(hand));

    // Triple + Pair
    combos.addAll(_findAllTripleWithPair(hand));

    // Straights (5-12 length)
    combos.addAll(_findAllStraights(hand));

    // Consecutive Pairs (3-10 pairs)
    combos.addAll(_findAllConsecutivePairs(hand));

    // Airplanes (2-6 triples)
    combos.addAll(_findAllAirplanes(hand));

    // Airplane + Singles
    combos.addAll(_findAllAirplaneWithSingles(hand));

    // Airplane + Pairs
    combos.addAll(_findAllAirplaneWithPairs(hand));

    // Quad + Singles
    combos.addAll(_findAllQuadWithSingles(hand));

    // Quad + Pairs
    combos.addAll(_findAllQuadWithPairs(hand));

    // Bombs
    combos.addAll(_findAllBombs(hand));

    // Rocket
    final rocket = _findRocket(hand);
    if (rocket != null) combos.add(rocket);

    return combos;
  }

  /// Find all combos that can beat a given hand
  static List<Combo> findBeatingCombos(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final allCombos = findAllCombos(hand);

    return allCombos.where((combo) {
      // Check if this combo can beat the last played hand
      return _canBeat(combo.analysis, lastPlayed);
    }).toList();
  }

  /// Check if current can beat previous (simplified from HandComparator)
  static bool _canBeat(HandAnalysis current, HandAnalysis previous) {
    if (current.type == HandType.rocket) return true;

    if (current.type == HandType.bomb) {
      if (previous.type == HandType.rocket) return false;
      if (previous.type == HandType.bomb) {
        return current.compareValue > previous.compareValue;
      }
      return true;
    }

    if (previous.type == HandType.bomb || previous.type == HandType.rocket) {
      return false;
    }

    if (current.type != previous.type) return false;

    // For sequences, must match length
    if (current.type == HandType.straight ||
        current.type == HandType.consecutivePairs ||
        current.type == HandType.airplane ||
        current.type == HandType.airplaneWithSingles ||
        current.type == HandType.airplaneWithPairs) {
      if (current.length != previous.length) return false;
      return current.baseRank > previous.baseRank;
    }

    return current.compareValue > previous.compareValue;
  }

  // === Individual combo finders ===

  static List<Combo> _findAllSingles(List<CardModel> hand) {
    return hand.map((card) {
      final analysis = HandAnalyzer.analyzeHand([card]);
      return Combo(cards: [card], analysis: analysis);
    }).toList();
  }

  static List<Combo> _findAllPairs(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    for (final cards in rankCounts.values) {
      if (cards.length >= 2) {
        final pair = cards.take(2).toList();
        final analysis = HandAnalyzer.analyzeHand(pair);
        combos.add(Combo(cards: pair, analysis: analysis));
      }
    }

    return combos;
  }

  static List<Combo> _findAllTriples(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    for (final cards in rankCounts.values) {
      if (cards.length >= 3) {
        final triple = cards.take(3).toList();
        final analysis = HandAnalyzer.analyzeHand(triple);
        combos.add(Combo(cards: triple, analysis: analysis));
      }
    }

    return combos;
  }

  static List<Combo> _findAllTripleWithSingle(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final tripleRanks = rankCounts.keys
        .where((r) => rankCounts[r]!.length >= 3)
        .toList();

    for (final tripleRank in tripleRanks) {
      final triple = rankCounts[tripleRank]!.take(3).toList();

      // Try each possible single as kicker
      for (final kickerRank in rankCounts.keys) {
        if (kickerRank != tripleRank && rankCounts[kickerRank]!.isNotEmpty) {
          final kicker = [rankCounts[kickerRank]!.first];
          final combo = [...triple, ...kicker];
          final analysis = HandAnalyzer.analyzeHand(combo);
          if (analysis.isValid) {
            combos.add(Combo(cards: combo, analysis: analysis));
          }
        }
      }
    }

    return combos;
  }

  static List<Combo> _findAllTripleWithPair(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final tripleRanks = rankCounts.keys
        .where((r) => rankCounts[r]!.length >= 3)
        .toList();

    for (final tripleRank in tripleRanks) {
      final triple = rankCounts[tripleRank]!.take(3).toList();

      // Try each possible pair as kicker
      for (final kickerRank in rankCounts.keys) {
        if (kickerRank != tripleRank && rankCounts[kickerRank]!.length >= 2) {
          final pair = rankCounts[kickerRank]!.take(2).toList();
          final combo = [...triple, ...pair];
          final analysis = HandAnalyzer.analyzeHand(combo);
          if (analysis.isValid) {
            combos.add(Combo(cards: combo, analysis: analysis));
          }
        }
      }
    }

    return combos;
  }

  static List<Combo> _findAllStraights(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      if (card.power < 15) {
        // No 2s or jokers in straights
        rankCounts.putIfAbsent(card.power, () => []).add(card);
      }
    }

    final availableRanks = rankCounts.keys.toList()..sort();

    // Try all straight lengths (5-12)
    for (int length = 5; length <= 12; length++) {
      for (int i = 0; i <= availableRanks.length - length; i++) {
        final startRank = availableRanks[i];
        final straight = <CardModel>[];
        bool valid = true;

        for (int j = 0; j < length; j++) {
          final neededRank = startRank + j;
          if (rankCounts.containsKey(neededRank)) {
            straight.add(rankCounts[neededRank]!.first);
          } else {
            valid = false;
            break;
          }
        }

        if (valid && straight.length == length) {
          final analysis = HandAnalyzer.analyzeHand(straight);
          if (analysis.isValid) {
            combos.add(Combo(cards: straight, analysis: analysis));
          }
        }
      }
    }

    return combos;
  }

  static List<Combo> _findAllConsecutivePairs(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      if (card.power < 15) {
        rankCounts.putIfAbsent(card.power, () => []).add(card);
      }
    }

    final pairRanks =
        rankCounts.keys.where((r) => rankCounts[r]!.length >= 2).toList()
          ..sort();

    // Try all consecutive pair lengths (3-10 pairs)
    for (int pairCount = 3; pairCount <= 10; pairCount++) {
      for (int i = 0; i <= pairRanks.length - pairCount; i++) {
        final startRank = pairRanks[i];
        final consecPairs = <CardModel>[];
        bool valid = true;

        for (int j = 0; j < pairCount; j++) {
          final neededRank = startRank + j;
          if (rankCounts.containsKey(neededRank) &&
              rankCounts[neededRank]!.length >= 2) {
            consecPairs.addAll(rankCounts[neededRank]!.take(2));
          } else {
            valid = false;
            break;
          }
        }

        if (valid && consecPairs.length == pairCount * 2) {
          final analysis = HandAnalyzer.analyzeHand(consecPairs);
          if (analysis.isValid) {
            combos.add(Combo(cards: consecPairs, analysis: analysis));
          }
        }
      }
    }

    return combos;
  }

  static List<Combo> _findAllAirplanes(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      if (card.power < 15) {
        rankCounts.putIfAbsent(card.power, () => []).add(card);
      }
    }

    final tripleRanks =
        rankCounts.keys.where((r) => rankCounts[r]!.length >= 3).toList()
          ..sort();

    // Try all airplane lengths (2-6 triples)
    for (int tripleCount = 2; tripleCount <= 6; tripleCount++) {
      for (int i = 0; i <= tripleRanks.length - tripleCount; i++) {
        final startRank = tripleRanks[i];
        final airplane = <CardModel>[];
        bool valid = true;

        for (int j = 0; j < tripleCount; j++) {
          final neededRank = startRank + j;
          if (rankCounts.containsKey(neededRank) &&
              rankCounts[neededRank]!.length >= 3) {
            airplane.addAll(rankCounts[neededRank]!.take(3));
          } else {
            valid = false;
            break;
          }
        }

        if (valid && airplane.length == tripleCount * 3) {
          final analysis = HandAnalyzer.analyzeHand(airplane);
          if (analysis.isValid) {
            combos.add(Combo(cards: airplane, analysis: analysis));
          }
        }
      }
    }

    return combos;
  }

  static List<Combo> _findAllAirplaneWithSingles(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final tripleRanks =
        rankCounts.keys
            .where((r) => r < 15 && rankCounts[r]!.length >= 3)
            .toList()
          ..sort();

    // Try airplane lengths (2-4 triples typically)
    for (int tripleCount = 2; tripleCount <= 4; tripleCount++) {
      for (int i = 0; i <= tripleRanks.length - tripleCount; i++) {
        final startRank = tripleRanks[i];
        final airplane = <CardModel>[];
        final tripleRanksList = <int>[];
        bool valid = true;

        for (int j = 0; j < tripleCount; j++) {
          final neededRank = startRank + j;
          if (rankCounts.containsKey(neededRank) &&
              rankCounts[neededRank]!.length >= 3) {
            airplane.addAll(rankCounts[neededRank]!.take(3));
            tripleRanksList.add(neededRank);
          } else {
            valid = false;
            break;
          }
        }

        if (!valid) continue;

        // Find kickers (singles)
        final availableKickers = <CardModel>[];
        for (final rank in rankCounts.keys) {
          if (!tripleRanksList.contains(rank)) {
            availableKickers.addAll(rankCounts[rank]!);
          }
        }

        if (availableKickers.length >= tripleCount) {
          final kickers = availableKickers.take(tripleCount).toList();
          final combo = [...airplane, ...kickers];
          final analysis = HandAnalyzer.analyzeHand(combo);
          if (analysis.isValid) {
            combos.add(Combo(cards: combo, analysis: analysis));
          }
        }
      }
    }

    return combos;
  }

  static List<Combo> _findAllAirplaneWithPairs(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final tripleRanks =
        rankCounts.keys
            .where((r) => r < 15 && rankCounts[r]!.length >= 3)
            .toList()
          ..sort();

    for (int tripleCount = 2; tripleCount <= 4; tripleCount++) {
      for (int i = 0; i <= tripleRanks.length - tripleCount; i++) {
        final startRank = tripleRanks[i];
        final airplane = <CardModel>[];
        final tripleRanksList = <int>[];
        bool valid = true;

        for (int j = 0; j < tripleCount; j++) {
          final neededRank = startRank + j;
          if (rankCounts.containsKey(neededRank) &&
              rankCounts[neededRank]!.length >= 3) {
            airplane.addAll(rankCounts[neededRank]!.take(3));
            tripleRanksList.add(neededRank);
          } else {
            valid = false;
            break;
          }
        }

        if (!valid) continue;

        // Find kickers (pairs)
        final availablePairRanks = rankCounts.keys
            .where(
              (r) => !tripleRanksList.contains(r) && rankCounts[r]!.length >= 2,
            )
            .toList();

        if (availablePairRanks.length >= tripleCount) {
          final kickers = <CardModel>[];
          for (int k = 0; k < tripleCount; k++) {
            kickers.addAll(rankCounts[availablePairRanks[k]]!.take(2));
          }

          final combo = [...airplane, ...kickers];
          final analysis = HandAnalyzer.analyzeHand(combo);
          if (analysis.isValid) {
            combos.add(Combo(cards: combo, analysis: analysis));
          }
        }
      }
    }

    return combos;
  }

  static List<Combo> _findAllQuadWithSingles(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final quadRanks = rankCounts.keys
        .where((r) => rankCounts[r]!.length == 4)
        .toList();

    for (final quadRank in quadRanks) {
      final quad = rankCounts[quadRank]!;

      // Find two singles
      final availableKickers = <CardModel>[];
      for (final rank in rankCounts.keys) {
        if (rank != quadRank) {
          availableKickers.addAll(rankCounts[rank]!);
        }
      }

      if (availableKickers.length >= 2) {
        final kickers = availableKickers.take(2).toList();
        final combo = [...quad, ...kickers];
        final analysis = HandAnalyzer.analyzeHand(combo);
        if (analysis.isValid) {
          combos.add(Combo(cards: combo, analysis: analysis));
        }
      }
    }

    return combos;
  }

  static List<Combo> _findAllQuadWithPairs(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final quadRanks = rankCounts.keys
        .where((r) => rankCounts[r]!.length == 4)
        .toList();

    for (final quadRank in quadRanks) {
      final quad = rankCounts[quadRank]!;

      // Find two pairs
      final availablePairRanks = rankCounts.keys
          .where((r) => r != quadRank && rankCounts[r]!.length >= 2)
          .toList();

      if (availablePairRanks.length >= 2) {
        final kickers = <CardModel>[];
        kickers.addAll(rankCounts[availablePairRanks[0]]!.take(2));
        kickers.addAll(rankCounts[availablePairRanks[1]]!.take(2));

        final combo = [...quad, ...kickers];
        final analysis = HandAnalyzer.analyzeHand(combo);
        if (analysis.isValid) {
          combos.add(Combo(cards: combo, analysis: analysis));
        }
      }
    }

    return combos;
  }

  static List<Combo> _findAllBombs(List<CardModel> hand) {
    final combos = <Combo>[];
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    for (final cards in rankCounts.values) {
      if (cards.length == 4) {
        final analysis = HandAnalyzer.analyzeHand(cards);
        combos.add(Combo(cards: cards, analysis: analysis));
      }
    }

    return combos;
  }

  static Combo? _findRocket(List<CardModel> hand) {
    final hasSmallJoker = hand.any((c) => c.power == 16);
    final hasBigJoker = hand.any((c) => c.power == 17);

    if (hasSmallJoker && hasBigJoker) {
      final rocket = [
        hand.firstWhere((c) => c.power == 16),
        hand.firstWhere((c) => c.power == 17),
      ];
      final analysis = HandAnalyzer.analyzeHand(rocket);
      return Combo(cards: rocket, analysis: analysis);
    }

    return null;
  }
}
