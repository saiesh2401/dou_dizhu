enum Suit { spades, hearts, diamonds, clubs, none }

enum Rank {
  r3,
  r4,
  r5,
  r6,
  r7,
  r8,
  r9,
  r10,
  j,
  q,
  k,
  a,
  r2,
  sj, // Small Joker
  bj, // Big Joker
}

class CardModel {
  final Rank rank;
  final Suit suit;

  const CardModel(this.rank, this.suit);

  /// Dou Dizhu power: 3..A..2..SJ..BJ
  int get power {
    switch (rank) {
      case Rank.r3:
        return 3;
      case Rank.r4:
        return 4;
      case Rank.r5:
        return 5;
      case Rank.r6:
        return 6;
      case Rank.r7:
        return 7;
      case Rank.r8:
        return 8;
      case Rank.r9:
        return 9;
      case Rank.r10:
        return 10;
      case Rank.j:
        return 11;
      case Rank.q:
        return 12;
      case Rank.k:
        return 13;
      case Rank.a:
        return 14;
      case Rank.r2:
        return 15;
      case Rank.sj:
        return 16;
      case Rank.bj:
        return 17;
    }
  }

  bool get isJoker => rank == Rank.sj || rank == Rank.bj;

  /// Unique identifier for this card (for selection tracking)
  String get id => '${suit.name}_${rank.name}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel &&
          runtimeType == other.runtimeType &&
          rank == other.rank &&
          suit == other.suit;

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode;

  @override
  String toString() =>
      isJoker ? rank.name.toUpperCase() : '${rank.name}${suit.name[0]}';
}
