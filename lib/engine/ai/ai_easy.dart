import '../card_model.dart';
import '../hand_type.dart';

/// Advanced AI that plays Dou Dizhu strategically like an experienced player
class AiEasy {
  /// Find a legal move for the AI player
  /// Returns null if AI should pass
  static List<CardModel>? findMove(
    List<CardModel> hand,
    HandAnalysis? lastPlayed, {
    int? playerIndex,
    int? landlordIndex,
    int? lastPlayedBy,
    List<int>? opponentHandSizes,
  }) {
    // If no last play, AI can play anything - choose best opening move
    if (lastPlayed == null) {
      return _findBestOpeningMove(
        hand,
        playerIndex: playerIndex,
        landlordIndex: landlordIndex,
      );
    }

    // Strategic decision: should we pass or play?
    final shouldPass = _shouldStrategicallyPass(
      hand,
      lastPlayed,
      playerIndex: playerIndex,
      landlordIndex: landlordIndex,
      lastPlayedBy: lastPlayedBy,
      opponentHandSizes: opponentHandSizes,
    );

    if (shouldPass) return null;

    // Try to find the best legal move
    final legalMove = _findBestLegalMove(
      hand,
      lastPlayed,
      playerIndex: playerIndex,
      landlordIndex: landlordIndex,
    );

    return legalMove;
  }

  /// Determine if AI should strategically pass even if it can play
  static bool _shouldStrategicallyPass(
    List<CardModel> hand,
    HandAnalysis lastPlayed, {
    int? playerIndex,
    int? landlordIndex,
    int? lastPlayedBy,
    List<int>? opponentHandSizes,
  }) {
    // Never pass if we're about to win (1-3 cards left)
    if (hand.length <= 3) return false;

    // If teammate played (farmers helping each other)
    if (playerIndex != null &&
        landlordIndex != null &&
        lastPlayedBy != null &&
        playerIndex != landlordIndex &&
        lastPlayedBy != landlordIndex &&
        lastPlayedBy != playerIndex) {
      // Teammate played - let them continue unless they have many cards
      if (opponentHandSizes != null && opponentHandSizes[lastPlayedBy] > 8) {
        return false; // Help teammate if they have many cards
      }
      return true; // Otherwise let teammate continue
    }

    // Don't waste bombs on weak plays
    if (lastPlayed.type != HandType.bomb &&
        lastPlayed.type != HandType.rocket) {
      final wouldNeedBomb = _wouldRequireBomb(hand, lastPlayed);
      if (wouldNeedBomb) return true; // Save bombs for later
    }

    // If opponent is about to win (low cards), we must play
    if (opponentHandSizes != null &&
        opponentHandSizes.any((size) => size <= 3)) {
      return false;
    }

    // Pass on high-value singles/pairs to save our good cards
    if ((lastPlayed.type == HandType.single ||
            lastPlayed.type == HandType.pair) &&
        lastPlayed.compareValue >= 14) {
      // High card (Ace or above) - consider passing
      return hand.length > 8; // Pass if we have many cards
    }

    return false;
  }

  /// Check if beating this hand would require using a bomb
  static bool _wouldRequireBomb(List<CardModel> hand, HandAnalysis lastPlayed) {
    // Try to find a non-bomb move
    final normalMove = _findBestLegalMoveWithoutBomb(hand, lastPlayed);
    return normalMove == null;
  }

  /// Find best legal move without using bombs
  static List<CardModel>? _findBestLegalMoveWithoutBomb(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    switch (lastPlayed.type) {
      case HandType.single:
        return _findLowestSingle(hand, lastPlayed);
      case HandType.pair:
        return _findLowestPair(hand, lastPlayed);
      case HandType.triple:
        return _findLowestTriple(hand, lastPlayed);
      case HandType.tripleWithSingle:
        return _findLowestTripleWithSingle(hand, lastPlayed);
      case HandType.tripleWithPair:
        return _findLowestTripleWithPair(hand, lastPlayed);
      case HandType.straight:
        return _findLowestStraight(hand, lastPlayed);
      case HandType.consecutivePairs:
        return _findLowestConsecutivePairs(hand, lastPlayed);
      case HandType.airplane:
        return _findLowestAirplane(hand, lastPlayed);
      case HandType.airplaneWithSingles:
        return _findLowestAirplaneWithSingles(hand, lastPlayed);
      case HandType.airplaneWithPairs:
        return _findLowestAirplaneWithPairs(hand, lastPlayed);
      case HandType.quadWithSingles:
        return _findLowestQuadWithSingles(hand, lastPlayed);
      case HandType.quadWithPairs:
        return _findLowestQuadWithPairs(hand, lastPlayed);
      default:
        return null;
    }
  }

  /// Find the best opening move when AI starts the round
  /// Prioritizes playing multiple cards and getting rid of awkward holdings
  static List<CardModel> _findBestOpeningMove(
    List<CardModel> hand, {
    int? playerIndex,
    int? landlordIndex,
  }) {
    final handStructure = _analyzeHandStructure(hand);

    // If we have very few cards, play the largest combination
    if (hand.length <= 5) {
      return _findLargestCombination(hand) ?? [hand.first];
    }

    // Priority 1: Play straights (gets rid of many cards efficiently)
    final straight = _findOptimalStraight(hand, handStructure);
    if (straight != null && straight.length >= 5) return straight;

    // Priority 2: Consecutive pairs (efficient multi-card play)
    final consecutivePairs = _findOptimalConsecutivePairs(hand, handStructure);
    if (consecutivePairs != null && consecutivePairs.length >= 6) {
      return consecutivePairs;
    }

    // Priority 3: Airplane combinations (very efficient)
    final airplane = _findOptimalAirplane(hand, handStructure);
    if (airplane != null) return airplane;

    // Priority 4: Get rid of awkward triples with kickers
    final tripleWithPair = _findOptimalTripleWithPair(hand, handStructure);
    if (tripleWithPair != null) return tripleWithPair;

    final tripleWithSingle = _findOptimalTripleWithSingle(hand, handStructure);
    if (tripleWithSingle != null) return tripleWithSingle;

    // Priority 5: Lone triples (hard to play later)
    final triple = _findLowestTriple(hand, null);
    if (triple != null) return triple;

    // Priority 6: Pairs (better than singles)
    final pair = _findLowestPair(hand, null);
    if (pair != null) return pair;

    // Priority 7: Single (lowest card)
    return [hand.first];
  }

  /// Analyze hand structure to make better decisions
  static Map<String, dynamic> _analyzeHandStructure(List<CardModel> hand) {
    final rankCounts = <int, int>{};
    for (final card in hand) {
      rankCounts[card.power] = (rankCounts[card.power] ?? 0) + 1;
    }

    final singles = <int>[];
    final pairs = <int>[];
    final triples = <int>[];
    final quads = <int>[];

    for (final entry in rankCounts.entries) {
      if (entry.value == 1) singles.add(entry.key);
      if (entry.value == 2) pairs.add(entry.key);
      if (entry.value == 3) triples.add(entry.key);
      if (entry.value == 4) quads.add(entry.key);
    }

    return {
      'rankCounts': rankCounts,
      'singles': singles..sort(),
      'pairs': pairs..sort(),
      'triples': triples..sort(),
      'quads': quads..sort(),
      'hasBomb': quads.isNotEmpty,
      'hasRocket': singles.contains(16) && singles.contains(17),
    };
  }

  /// Find optimal straight considering hand structure
  static List<CardModel>? _findOptimalStraight(
    List<CardModel> hand,
    Map<String, dynamic> structure,
  ) {
    final rankCounts = structure['rankCounts'] as Map<int, int>;
    final availableRanks = rankCounts.keys.where((r) => r < 15).toList()
      ..sort();

    // Try to find longest straight that doesn't break important pairs/triples
    for (int length = 12; length >= 5; length--) {
      for (int startRank in availableRanks) {
        if (startRank + length > 15) continue;

        bool canFormStraight = true;
        int breaksPairs = 0;
        int breaksTriples = 0;

        for (int i = 0; i < length; i++) {
          final rank = startRank + i;
          if (!rankCounts.containsKey(rank)) {
            canFormStraight = false;
            break;
          }
          if (rankCounts[rank]! >= 2) breaksPairs++;
          if (rankCounts[rank]! >= 3) breaksTriples++;
        }

        // Prefer straights that don't break many pairs/triples
        if (canFormStraight && breaksTriples == 0 && breaksPairs <= 2) {
          final straight = <CardModel>[];
          for (int i = 0; i < length; i++) {
            final rank = startRank + i;
            final card = hand.firstWhere((c) => c.power == rank);
            straight.add(card);
          }
          return straight;
        }
      }
    }

    return null;
  }

  /// Find optimal consecutive pairs
  static List<CardModel>? _findOptimalConsecutivePairs(
    List<CardModel> hand,
    Map<String, dynamic> structure,
  ) {
    final pairs = structure['pairs'] as List<int>;
    if (pairs.length < 3) return null;

    // Find longest consecutive sequence in pairs
    for (int length = pairs.length; length >= 3; length--) {
      for (int i = 0; i <= pairs.length - length; i++) {
        bool isConsecutive = true;
        for (int j = 1; j < length; j++) {
          if (pairs[i + j] != pairs[i + j - 1] + 1) {
            isConsecutive = false;
            break;
          }
        }

        if (isConsecutive) {
          final result = <CardModel>[];
          for (int j = 0; j < length; j++) {
            final rank = pairs[i + j];
            final cards = hand.where((c) => c.power == rank).take(2);
            result.addAll(cards);
          }
          return result;
        }
      }
    }

    return null;
  }

  /// Find optimal airplane
  static List<CardModel>? _findOptimalAirplane(
    List<CardModel> hand,
    Map<String, dynamic> structure,
  ) {
    final triples = structure['triples'] as List<int>;
    if (triples.length < 2) return null;

    // Find consecutive triples
    for (int length = triples.length; length >= 2; length--) {
      for (int i = 0; i <= triples.length - length; i++) {
        bool isConsecutive = true;
        for (int j = 1; j < length; j++) {
          if (triples[i + j] != triples[i + j - 1] + 1) {
            isConsecutive = false;
            break;
          }
        }

        if (isConsecutive) {
          final result = <CardModel>[];
          for (int j = 0; j < length; j++) {
            final rank = triples[i + j];
            final cards = hand.where((c) => c.power == rank).take(3);
            result.addAll(cards);
          }
          return result;
        }
      }
    }

    return null;
  }

  /// Find optimal triple with pair
  static List<CardModel>? _findOptimalTripleWithPair(
    List<CardModel> hand,
    Map<String, dynamic> structure,
  ) {
    final triples = structure['triples'] as List<int>;
    final pairs = structure['pairs'] as List<int>;

    if (triples.isEmpty || pairs.isEmpty) return null;

    // Use lowest triple with lowest pair
    final triple = triples.first;
    final pair = pairs.first;

    final result = <CardModel>[];
    result.addAll(hand.where((c) => c.power == triple).take(3));
    result.addAll(hand.where((c) => c.power == pair).take(2));

    return result;
  }

  /// Find optimal triple with single
  static List<CardModel>? _findOptimalTripleWithSingle(
    List<CardModel> hand,
    Map<String, dynamic> structure,
  ) {
    final triples = structure['triples'] as List<int>;
    final singles = structure['singles'] as List<int>;

    if (triples.isEmpty || singles.isEmpty) return null;

    // Use lowest triple with lowest single
    final triple = triples.first;
    final single = singles.first;

    final result = <CardModel>[];
    result.addAll(hand.where((c) => c.power == triple).take(3));
    result.add(hand.firstWhere((c) => c.power == single));

    return result;
  }

  /// Find largest combination in hand
  static List<CardModel>? _findLargestCombination(List<CardModel> hand) {
    // Try all combination types from largest to smallest
    final straight = _findAnyStraight(hand);
    if (straight != null) return straight;

    final consecutivePairs = _findAnyConsecutivePairs(hand);
    if (consecutivePairs != null) return consecutivePairs;

    final airplane = _findAnyAirplane(hand);
    if (airplane != null) return airplane;

    final tripleWithPair = _findAnyTripleWithPair(hand);
    if (tripleWithPair != null) return tripleWithPair;

    final tripleWithSingle = _findAnyTripleWithSingle(hand);
    if (tripleWithSingle != null) return tripleWithSingle;

    return null;
  }

  /// Find the best legal move that can beat the last played hand
  static List<CardModel>? _findBestLegalMove(
    List<CardModel> hand,
    HandAnalysis lastPlayed, {
    int? playerIndex,
    int? landlordIndex,
  }) {
    // First try to beat with same type (non-bomb)
    final normalMove = _findBestLegalMoveWithoutBomb(hand, lastPlayed);
    if (normalMove != null) return normalMove;

    // Only use bomb if necessary
    if (lastPlayed.type == HandType.bomb ||
        lastPlayed.type == HandType.rocket) {
      return _findLowestBomb(hand, lastPlayed);
    }

    // Consider using bomb only in critical situations
    // For now, use bomb as last resort
    return _findAnyBomb(hand);
  }

  /// Find lowest single that beats the last played single
  static List<CardModel>? _findLowestSingle(
    List<CardModel> hand,
    HandAnalysis? lastPlayed,
  ) {
    if (lastPlayed == null) {
      return [hand.first]; // Play lowest
    }

    final requiredPower = lastPlayed.compareValue;

    for (final card in hand) {
      if (card.power > requiredPower) {
        return [card];
      }
    }

    return null;
  }

  /// Find lowest pair that beats the last played pair
  static List<CardModel>? _findLowestPair(
    List<CardModel> hand,
    HandAnalysis? lastPlayed,
  ) {
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final requiredPower = lastPlayed?.compareValue ?? -1;

    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length >= 2 && power > requiredPower) {
        return rankCounts[power]!.take(2).toList();
      }
    }

    return null;
  }

  /// Find lowest triple that beats the last played triple
  static List<CardModel>? _findLowestTriple(
    List<CardModel> hand,
    HandAnalysis? lastPlayed,
  ) {
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final requiredPower = lastPlayed?.compareValue ?? -1;

    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length >= 3 && power > requiredPower) {
        return rankCounts[power]!.take(3).toList();
      }
    }

    return null;
  }

  /// Find lowest triple with single (3+1)
  static List<CardModel>? _findLowestTripleWithSingle(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredPower = lastPlayed.compareValue;
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    // Find triples that beat the requirement
    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length >= 3 && power > requiredPower) {
        final triple = rankCounts[power]!.take(3).toList();

        // Find lowest single kicker (prefer singles over breaking pairs)
        for (final kickerPower in rankCounts.keys.toList()..sort()) {
          if (kickerPower != power) {
            // Prefer using actual singles
            if (rankCounts[kickerPower]!.length == 1) {
              return [...triple, rankCounts[kickerPower]!.first];
            }
          }
        }

        // If no singles, break a pair
        for (final kickerPower in rankCounts.keys.toList()..sort()) {
          if (kickerPower != power && rankCounts[kickerPower]!.isNotEmpty) {
            return [...triple, rankCounts[kickerPower]!.first];
          }
        }
      }
    }

    return null;
  }

  /// Find lowest triple with pair (3+2)
  static List<CardModel>? _findLowestTripleWithPair(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredPower = lastPlayed.compareValue;
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    // Find triples that beat the requirement
    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length >= 3 && power > requiredPower) {
        final triple = rankCounts[power]!.take(3).toList();

        // Find lowest pair kicker
        for (final kickerPower in rankCounts.keys.toList()..sort()) {
          if (kickerPower != power && rankCounts[kickerPower]!.length >= 2) {
            final pair = rankCounts[kickerPower]!.take(2).toList();
            return [...triple, ...pair];
          }
        }
      }
    }

    return null;
  }

  /// Find lowest straight that beats the last played straight
  static List<CardModel>? _findLowestStraight(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredLength = lastPlayed.length;
    final requiredBase = lastPlayed.baseRank;

    // Get unique ranks in hand (excluding 2s and jokers)
    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      if (card.power < 15) {
        rankCounts.putIfAbsent(card.power, () => []).add(card);
      }
    }

    final availableRanks = rankCounts.keys.toList()..sort();

    // Try to find a straight of the same length starting from a higher rank
    for (int startRank in availableRanks) {
      if (startRank <= requiredBase) continue;

      final straight = <CardModel>[];
      bool valid = true;

      for (int i = 0; i < requiredLength; i++) {
        final neededRank = startRank + i;
        if (rankCounts.containsKey(neededRank)) {
          straight.add(rankCounts[neededRank]!.first);
        } else {
          valid = false;
          break;
        }
      }

      if (valid && straight.length == requiredLength) {
        return straight;
      }
    }

    return null;
  }

  /// Find lowest consecutive pairs
  static List<CardModel>? _findLowestConsecutivePairs(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredLength = lastPlayed.length;
    final requiredBase = lastPlayed.baseRank;

    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      if (card.power < 15) {
        rankCounts.putIfAbsent(card.power, () => []).add(card);
      }
    }

    final availableRanks = rankCounts.keys.toList()..sort();

    for (int startRank in availableRanks) {
      if (startRank <= requiredBase) continue;

      final pairs = <CardModel>[];
      bool valid = true;

      for (int i = 0; i < requiredLength; i++) {
        final neededRank = startRank + i;
        if (rankCounts.containsKey(neededRank) &&
            rankCounts[neededRank]!.length >= 2) {
          pairs.addAll(rankCounts[neededRank]!.take(2));
        } else {
          valid = false;
          break;
        }
      }

      if (valid) return pairs;
    }

    return null;
  }

  /// Find lowest airplane (consecutive triples)
  static List<CardModel>? _findLowestAirplane(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredLength = lastPlayed.length;
    final requiredBase = lastPlayed.baseRank;

    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      if (card.power < 15) {
        rankCounts.putIfAbsent(card.power, () => []).add(card);
      }
    }

    final availableRanks = rankCounts.keys.toList()..sort();

    for (int startRank in availableRanks) {
      if (startRank <= requiredBase) continue;

      final triples = <CardModel>[];
      bool valid = true;

      for (int i = 0; i < requiredLength; i++) {
        final neededRank = startRank + i;
        if (rankCounts.containsKey(neededRank) &&
            rankCounts[neededRank]!.length >= 3) {
          triples.addAll(rankCounts[neededRank]!.take(3));
        } else {
          valid = false;
          break;
        }
      }

      if (valid) return triples;
    }

    return null;
  }

  /// Find lowest airplane with singles
  static List<CardModel>? _findLowestAirplaneWithSingles(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredLength = lastPlayed.length;
    final requiredBase = lastPlayed.baseRank;

    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final availableRanks = rankCounts.keys.where((r) => r < 15).toList()
      ..sort();

    for (int startRank in availableRanks) {
      if (startRank <= requiredBase) continue;

      final triples = <CardModel>[];
      final tripleRanks = <int>[];
      bool valid = true;

      for (int i = 0; i < requiredLength; i++) {
        final neededRank = startRank + i;
        if (rankCounts.containsKey(neededRank) &&
            rankCounts[neededRank]!.length >= 3) {
          triples.addAll(rankCounts[neededRank]!.take(3));
          tripleRanks.add(neededRank);
        } else {
          valid = false;
          break;
        }
      }

      if (!valid) continue;

      // Find kickers (prefer actual singles)
      final kickers = <CardModel>[];
      for (final power in rankCounts.keys.toList()..sort()) {
        if (!tripleRanks.contains(power) && rankCounts[power]!.length == 1) {
          if (kickers.length < requiredLength) {
            kickers.add(rankCounts[power]!.first);
          }
        }
      }

      // If not enough singles, use any cards
      if (kickers.length < requiredLength) {
        for (final power in rankCounts.keys.toList()..sort()) {
          if (!tripleRanks.contains(power)) {
            for (final card in rankCounts[power]!) {
              if (kickers.length < requiredLength && !kickers.contains(card)) {
                kickers.add(card);
              }
            }
          }
        }
      }

      if (kickers.length == requiredLength) {
        return [...triples, ...kickers];
      }
    }

    return null;
  }

  /// Find lowest airplane with pairs
  static List<CardModel>? _findLowestAirplaneWithPairs(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredLength = lastPlayed.length;
    final requiredBase = lastPlayed.baseRank;

    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    final availableRanks = rankCounts.keys.where((r) => r < 15).toList()
      ..sort();

    for (int startRank in availableRanks) {
      if (startRank <= requiredBase) continue;

      final triples = <CardModel>[];
      final tripleRanks = <int>[];
      bool valid = true;

      for (int i = 0; i < requiredLength; i++) {
        final neededRank = startRank + i;
        if (rankCounts.containsKey(neededRank) &&
            rankCounts[neededRank]!.length >= 3) {
          triples.addAll(rankCounts[neededRank]!.take(3));
          tripleRanks.add(neededRank);
        } else {
          valid = false;
          break;
        }
      }

      if (!valid) continue;

      // Find kickers (pairs)
      final kickers = <CardModel>[];
      int pairsFound = 0;
      for (final power in rankCounts.keys.toList()..sort()) {
        if (!tripleRanks.contains(power) && rankCounts[power]!.length >= 2) {
          if (pairsFound < requiredLength) {
            kickers.addAll(rankCounts[power]!.take(2));
            pairsFound++;
          }
        }
      }

      if (pairsFound == requiredLength) {
        return [...triples, ...kickers];
      }
    }

    return null;
  }

  /// Find lowest quad with singles (4+1+1)
  static List<CardModel>? _findLowestQuadWithSingles(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredPower = lastPlayed.compareValue;
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length == 4 && power > requiredPower) {
        final quad = rankCounts[power]!;
        final kickers = <CardModel>[];

        // Prefer actual singles
        for (final kickerPower in rankCounts.keys.toList()..sort()) {
          if (kickerPower != power &&
              rankCounts[kickerPower]!.length == 1 &&
              kickers.length < 2) {
            kickers.add(rankCounts[kickerPower]!.first);
          }
        }

        // Fill with any cards if needed
        if (kickers.length < 2) {
          for (final kickerPower in rankCounts.keys.toList()..sort()) {
            if (kickerPower != power && kickers.length < 2) {
              kickers.add(rankCounts[kickerPower]!.first);
            }
          }
        }

        if (kickers.length == 2) {
          return [...quad, ...kickers];
        }
      }
    }

    return null;
  }

  /// Find lowest quad with pairs (4+2+2)
  static List<CardModel>? _findLowestQuadWithPairs(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredPower = lastPlayed.compareValue;
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length == 4 && power > requiredPower) {
        final quad = rankCounts[power]!;
        final kickers = <CardModel>[];
        int pairsFound = 0;

        for (final kickerPower in rankCounts.keys.toList()..sort()) {
          if (kickerPower != power &&
              rankCounts[kickerPower]!.length >= 2 &&
              pairsFound < 2) {
            kickers.addAll(rankCounts[kickerPower]!.take(2));
            pairsFound++;
          }
        }

        if (pairsFound == 2) {
          return [...quad, ...kickers];
        }
      }
    }

    return null;
  }

  /// Find lowest bomb that beats the last played bomb
  static List<CardModel>? _findLowestBomb(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredPower = lastPlayed.compareValue;
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length == 4 && power > requiredPower) {
        return rankCounts[power]!;
      }
    }

    // Try rocket
    final hasSmallJoker = hand.any((c) => c.power == 16);
    final hasBigJoker = hand.any((c) => c.power == 17);

    if (hasSmallJoker && hasBigJoker) {
      return [
        hand.firstWhere((c) => c.power == 16),
        hand.firstWhere((c) => c.power == 17),
      ];
    }

    return null;
  }

  /// Find any bomb in hand (used as last resort)
  static List<CardModel>? _findAnyBomb(List<CardModel> hand) {
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    // Find lowest bomb
    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length == 4) {
        return rankCounts[power]!;
      }
    }

    // Try rocket
    final hasSmallJoker = hand.any((c) => c.power == 16);
    final hasBigJoker = hand.any((c) => c.power == 17);

    if (hasSmallJoker && hasBigJoker) {
      return [
        hand.firstWhere((c) => c.power == 16),
        hand.firstWhere((c) => c.power == 17),
      ];
    }

    return null;
  }

  // Helper methods to find any valid combination

  static List<CardModel>? _findAnyStraight(List<CardModel> hand) {
    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      if (card.power < 15) {
        rankCounts.putIfAbsent(card.power, () => []).add(card);
      }
    }

    final availableRanks = rankCounts.keys.toList()..sort();

    // Try to find longest straight
    for (int length = 12; length >= 5; length--) {
      for (int startRank in availableRanks) {
        final straight = <CardModel>[];
        bool valid = true;

        for (int i = 0; i < length; i++) {
          final neededRank = startRank + i;
          if (rankCounts.containsKey(neededRank)) {
            straight.add(rankCounts[neededRank]!.first);
          } else {
            valid = false;
            break;
          }
        }

        if (valid && straight.length == length) {
          return straight;
        }
      }
    }

    return null;
  }

  static List<CardModel>? _findAnyConsecutivePairs(List<CardModel> hand) {
    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      if (card.power < 15) {
        rankCounts.putIfAbsent(card.power, () => []).add(card);
      }
    }

    final availableRanks = rankCounts.keys.toList()..sort();

    for (int length = 10; length >= 3; length--) {
      for (int startRank in availableRanks) {
        final pairs = <CardModel>[];
        bool valid = true;

        for (int i = 0; i < length; i++) {
          final neededRank = startRank + i;
          if (rankCounts.containsKey(neededRank) &&
              rankCounts[neededRank]!.length >= 2) {
            pairs.addAll(rankCounts[neededRank]!.take(2));
          } else {
            valid = false;
            break;
          }
        }

        if (valid) return pairs;
      }
    }

    return null;
  }

  static List<CardModel>? _findAnyAirplane(List<CardModel> hand) {
    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      if (card.power < 15) {
        rankCounts.putIfAbsent(card.power, () => []).add(card);
      }
    }

    final availableRanks = rankCounts.keys.toList()..sort();

    for (int length = 6; length >= 2; length--) {
      for (int startRank in availableRanks) {
        final triples = <CardModel>[];
        bool valid = true;

        for (int i = 0; i < length; i++) {
          final neededRank = startRank + i;
          if (rankCounts.containsKey(neededRank) &&
              rankCounts[neededRank]!.length >= 3) {
            triples.addAll(rankCounts[neededRank]!.take(3));
          } else {
            valid = false;
            break;
          }
        }

        if (valid) return triples;
      }
    }

    return null;
  }

  static List<CardModel>? _findAnyTripleWithPair(List<CardModel> hand) {
    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length >= 3) {
        final triple = rankCounts[power]!.take(3).toList();

        for (final pairPower in rankCounts.keys.toList()..sort()) {
          if (pairPower != power && rankCounts[pairPower]!.length >= 2) {
            final pair = rankCounts[pairPower]!.take(2).toList();
            return [...triple, ...pair];
          }
        }
      }
    }

    return null;
  }

  static List<CardModel>? _findAnyTripleWithSingle(List<CardModel> hand) {
    final rankCounts = <int, List<CardModel>>{};
    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length >= 3) {
        final triple = rankCounts[power]!.take(3).toList();

        for (final singlePower in rankCounts.keys.toList()..sort()) {
          if (singlePower != power) {
            final single = [rankCounts[singlePower]!.first];
            return [...triple, ...single];
          }
        }
      }
    }

    return null;
  }
}
