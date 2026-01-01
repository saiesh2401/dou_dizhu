import '../card_model.dart';
import '../hand_type.dart';

class AiEasy {
  /// Find a legal move for the AI player
  /// Returns null if AI should pass
  static List<CardModel>? findMove(
    List<CardModel> hand,
    HandAnalysis? lastPlayed,
  ) {
    // If no last play, AI can play anything - choose lowest single
    if (lastPlayed == null) {
      return [hand.first]; // Play lowest card
    }

    // Try to find a legal move
    final legalMove = _findLowestLegalMove(hand, lastPlayed);

    // If no legal move found (except bombs), pass
    return legalMove;
  }

  /// Find the lowest legal move that can beat the last played hand
  static List<CardModel>? _findLowestLegalMove(
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

      case HandType.straight:
        return _findLowestStraight(hand, lastPlayed);

      case HandType.bomb:
        return _findLowestBomb(hand, lastPlayed);

      default:
        // For complex types, just try to find a bomb
        return _findAnyBomb(hand);
    }
  }

  /// Find lowest single that beats the last played single
  static List<CardModel>? _findLowestSingle(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredPower = lastPlayed.compareValue;

    for (final card in hand) {
      if (card.power > requiredPower) {
        return [card];
      }
    }

    // No single found, try bomb
    return _findAnyBomb(hand);
  }

  /// Find lowest pair that beats the last played pair
  static List<CardModel>? _findLowestPair(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredPower = lastPlayed.compareValue;
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length >= 2 && power > requiredPower) {
        return rankCounts[power]!.take(2).toList();
      }
    }

    // No pair found, try bomb
    return _findAnyBomb(hand);
  }

  /// Find lowest triple that beats the last played triple
  static List<CardModel>? _findLowestTriple(
    List<CardModel> hand,
    HandAnalysis lastPlayed,
  ) {
    final requiredPower = lastPlayed.compareValue;
    final rankCounts = <int, List<CardModel>>{};

    for (final card in hand) {
      rankCounts.putIfAbsent(card.power, () => []).add(card);
    }

    for (final power in rankCounts.keys.toList()..sort()) {
      if (rankCounts[power]!.length >= 3 && power > requiredPower) {
        return rankCounts[power]!.take(3).toList();
      }
    }

    // No triple found, try bomb
    return _findAnyBomb(hand);
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
        // No 2s or jokers
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

    // No straight found, try bomb
    return _findAnyBomb(hand);
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

    return null; // Cannot beat
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

    return null; // No bomb available
  }
}
