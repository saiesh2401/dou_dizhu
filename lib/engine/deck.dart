import 'card_model.dart';

class Deck {
  final List<CardModel> cards;

  Deck(this.cards);

  /// Create a standard 54-card Dou Dizhu deck (52 regular + 2 jokers)
  factory Deck.standard54() {
    final cards = <CardModel>[];

    // Add 52 regular cards (4 suits × 13 ranks)
    for (final suit in [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs]) {
      for (final rank in [
        Rank.r3,
        Rank.r4,
        Rank.r5,
        Rank.r6,
        Rank.r7,
        Rank.r8,
        Rank.r9,
        Rank.r10,
        Rank.j,
        Rank.q,
        Rank.k,
        Rank.a,
        Rank.r2,
      ]) {
        cards.add(CardModel(rank, suit));
      }
    }

    // Add 2 jokers
    cards.add(const CardModel(Rank.sj, Suit.none));
    cards.add(const CardModel(Rank.bj, Suit.none));

    return Deck(cards);
  }

  /// Shuffle the deck
  void shuffle() {
    cards.shuffle();
  }

  /// Deal cards to 3 players: 17 + 17 + 17 + 3 bottom cards
  DealResult deal3Players() {
    if (cards.length != 54) {
      throw StateError('Deck must have 54 cards to deal');
    }

    return DealResult(
      player0: cards.sublist(0, 17),
      player1: cards.sublist(17, 34),
      player2: cards.sublist(34, 51),
      bottomCards: cards.sublist(51, 54),
    );
  }

  /// Sort cards by power (ascending)
  static List<CardModel> sortByPower(List<CardModel> cards) {
    final sorted = List<CardModel>.from(cards);
    sorted.sort((a, b) => a.power.compareTo(b.power));
    return sorted;
  }

  /// Sort cards by power (descending)
  static List<CardModel> sortByPowerDesc(List<CardModel> cards) {
    final sorted = List<CardModel>.from(cards);
    sorted.sort((a, b) => b.power.compareTo(a.power));
    return sorted;
  }
}

class DealResult {
  final List<CardModel> player0;
  final List<CardModel> player1;
  final List<CardModel> player2;
  final List<CardModel> bottomCards;

  DealResult({
    required this.player0,
    required this.player1,
    required this.player2,
    required this.bottomCards,
  });
}
