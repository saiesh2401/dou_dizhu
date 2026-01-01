enum HandType {
  invalid,
  single, // 1 card
  pair, // 2 cards same rank
  triple, // 3 cards same rank
  tripleWithSingle, // 3 + 1
  tripleWithPair, // 3 + 2
  straight, // 5+ consecutive cards
  consecutivePairs, // 3+ consecutive pairs (e.g., 334455)
  airplane, // 2+ consecutive triples
  airplaneWithSingles, // airplane + same number of singles
  airplaneWithPairs, // airplane + same number of pairs
  quadWithSingles, // 4 + 2 singles
  quadWithPairs, // 4 + 2 pairs
  bomb, // 4 of a kind
  rocket, // Small Joker + Big Joker
}

class HandAnalysis {
  final HandType type;
  final List<int>
  primaryCards; // Main cards (e.g., the triple in triple+single)
  final List<int>
  kickerCards; // Kicker cards (e.g., the single in triple+single)
  final int length; // For straights/consecutive pairs/airplane
  final int baseRank; // Starting rank for sequences

  const HandAnalysis({
    required this.type,
    this.primaryCards = const [],
    this.kickerCards = const [],
    this.length = 0,
    this.baseRank = 0,
  });

  /// Invalid hand
  static const HandAnalysis invalid = HandAnalysis(type: HandType.invalid);

  bool get isValid => type != HandType.invalid;

  /// Get the comparison value for this hand (higher = stronger)
  int get compareValue {
    if (primaryCards.isEmpty) return 0;
    // For most hands, use the highest primary card
    return primaryCards.reduce((a, b) => a > b ? a : b);
  }

  @override
  String toString() {
    return 'HandAnalysis(type: $type, primary: $primaryCards, kickers: $kickerCards, len: $length, base: $baseRank)';
  }
}
