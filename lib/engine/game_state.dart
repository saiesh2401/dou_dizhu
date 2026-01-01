import 'card_model.dart';
import 'deck.dart';
import 'hand_analyzer.dart';
import 'hand_compare.dart';
import 'hand_type.dart';

enum GamePhase { initial, bidding, playing, gameOver }

enum BidAction {
  pass,
  call, // Bid to be landlord
  rob, // Increase bid
}

class PlayResult {
  final bool isOk;
  final GameState? nextState;
  final String? errorMessage;

  const PlayResult.ok(this.nextState) : isOk = true, errorMessage = null;

  const PlayResult.error(this.errorMessage) : isOk = false, nextState = null;
}

class GameState {
  final GamePhase phase;
  final List<List<CardModel>> playerHands; // 3 players
  final List<CardModel> bottomCards; // 3 cards for landlord
  final int? landlordIndex; // null until determined
  final int currentTurn; // 0, 1, or 2
  final HandAnalysis? lastPlayedHand;
  final List<CardModel>? lastPlayedCards;
  final int lastPlayedBy; // Who played the last hand
  final int passCount; // Consecutive passes
  final Set<String> selectedCardIds; // For local player (player 0)
  final String? uiMessage; // Transient message for UI
  final int? winnerIndex; // null until game over

  const GameState({
    required this.phase,
    required this.playerHands,
    required this.bottomCards,
    this.landlordIndex,
    required this.currentTurn,
    this.lastPlayedHand,
    this.lastPlayedCards,
    required this.lastPlayedBy,
    this.passCount = 0,
    this.selectedCardIds = const {},
    this.uiMessage,
    this.winnerIndex,
  });

  /// Initial empty state
  factory GameState.initial() {
    return const GameState(
      phase: GamePhase.initial,
      playerHands: [[], [], []],
      bottomCards: [],
      currentTurn: 0,
      lastPlayedBy: -1,
    );
  }

  /// Start a new round with dealt cards
  GameState startNewRound(DealResult deal) {
    return GameState(
      phase: GamePhase.bidding,
      playerHands: [
        Deck.sortByPower(deal.player0),
        Deck.sortByPower(deal.player1),
        Deck.sortByPower(deal.player2),
      ],
      bottomCards: deal.bottomCards,
      currentTurn: 0, // Start bidding from player 0
      lastPlayedBy: -1,
      passCount: 0,
      selectedCardIds: {},
    );
  }

  /// Toggle card selection for player 0
  GameState toggleSelect(String cardId) {
    final newSelection = Set<String>.from(selectedCardIds);
    if (newSelection.contains(cardId)) {
      newSelection.remove(cardId);
    } else {
      newSelection.add(cardId);
    }

    return copyWith(selectedCardIds: newSelection);
  }

  /// Process a bid action
  GameState processBid(int playerIndex, BidAction action) {
    if (phase != GamePhase.bidding) return this;

    // Simple bidding: first player to call becomes landlord
    if (action == BidAction.call || action == BidAction.rob) {
      // Give bottom cards to landlord
      final newHands = List<List<CardModel>>.from(playerHands);
      newHands[playerIndex] = Deck.sortByPower([
        ...newHands[playerIndex],
        ...bottomCards,
      ]);

      return GameState(
        phase: GamePhase.playing,
        playerHands: newHands,
        bottomCards: [],
        landlordIndex: playerIndex,
        currentTurn: playerIndex, // Landlord starts
        lastPlayedBy: -1,
        passCount: 0,
      );
    }

    // Pass - move to next player
    final nextTurn = (currentTurn + 1) % 3;
    return copyWith(currentTurn: nextTurn);
  }

  /// Try to play selected cards
  PlayResult tryPlaySelected() {
    if (phase != GamePhase.playing) {
      return const PlayResult.error('Not in playing phase');
    }

    if (currentTurn != 0) {
      return const PlayResult.error('Not your turn');
    }

    final selectedCards = playerHands[0]
        .where((c) => selectedCardIds.contains(c.id))
        .toList();

    if (selectedCards.isEmpty) {
      return const PlayResult.error('No cards selected');
    }

    final analysis = HandAnalyzer.analyzeHand(selectedCards);

    if (!analysis.isValid) {
      return const PlayResult.error('Invalid hand combination');
    }

    // Check if can beat last played hand
    if (!HandComparator.canBeat(analysis, lastPlayedHand)) {
      final reason = HandComparator.getInvalidReason(analysis, lastPlayedHand);
      return PlayResult.error(reason ?? 'Cannot beat last played hand');
    }

    // Valid play - remove cards from hand
    final newHand = playerHands[0]
        .where((c) => !selectedCardIds.contains(c.id))
        .toList();
    final newHands = List<List<CardModel>>.from(playerHands);
    newHands[0] = newHand;

    // Check for win
    if (newHand.isEmpty) {
      return PlayResult.ok(
        GameState(
          phase: GamePhase.gameOver,
          playerHands: newHands,
          bottomCards: bottomCards,
          landlordIndex: landlordIndex,
          currentTurn: currentTurn,
          lastPlayedHand: analysis,
          lastPlayedCards: selectedCards,
          lastPlayedBy: 0,
          passCount: 0,
          winnerIndex: 0,
          uiMessage: 'You win!',
        ),
      );
    }

    // Move to next player
    final nextTurn = (currentTurn + 1) % 3;

    return PlayResult.ok(
      GameState(
        phase: GamePhase.playing,
        playerHands: newHands,
        bottomCards: bottomCards,
        landlordIndex: landlordIndex,
        currentTurn: nextTurn,
        lastPlayedHand: analysis,
        lastPlayedCards: selectedCards,
        lastPlayedBy: 0,
        passCount: 0, // Reset pass count
        selectedCardIds: {}, // Clear selection
      ),
    );
  }

  /// Pass turn
  GameState passTurn() {
    if (phase != GamePhase.playing) return this;

    final newPassCount = passCount + 1;

    // If 2 consecutive passes, next player can play anything
    final nextTurn = (currentTurn + 1) % 3;
    final shouldResetLastPlay = newPassCount >= 2;

    return GameState(
      phase: phase,
      playerHands: playerHands,
      bottomCards: bottomCards,
      landlordIndex: landlordIndex,
      currentTurn: nextTurn,
      lastPlayedHand: shouldResetLastPlay ? null : lastPlayedHand,
      lastPlayedCards: shouldResetLastPlay ? null : lastPlayedCards,
      lastPlayedBy: shouldResetLastPlay ? -1 : lastPlayedBy,
      passCount: shouldResetLastPlay ? 0 : newPassCount,
      selectedCardIds: currentTurn == 0
          ? {}
          : selectedCardIds, // Clear selection if player 0
    );
  }

  /// AI play (for players 1 and 2)
  GameState aiPlay(int playerIndex, List<CardModel> cards) {
    if (playerIndex == 0) return this; // Not for human player

    final analysis = HandAnalyzer.analyzeHand(cards);

    if (!analysis.isValid ||
        !HandComparator.canBeat(analysis, lastPlayedHand)) {
      return this; // Invalid move
    }

    // Remove cards from AI hand
    final cardIds = cards.map((c) => c.id).toSet();
    final newHand = playerHands[playerIndex]
        .where((c) => !cardIds.contains(c.id))
        .toList();
    final newHands = List<List<CardModel>>.from(playerHands);
    newHands[playerIndex] = newHand;

    // Check for win
    if (newHand.isEmpty) {
      return GameState(
        phase: GamePhase.gameOver,
        playerHands: newHands,
        bottomCards: bottomCards,
        landlordIndex: landlordIndex,
        currentTurn: currentTurn,
        lastPlayedHand: analysis,
        lastPlayedCards: cards,
        lastPlayedBy: playerIndex,
        passCount: 0,
        winnerIndex: playerIndex,
        uiMessage: 'Player $playerIndex wins!',
      );
    }

    // Move to next player
    final nextTurn = (currentTurn + 1) % 3;

    return GameState(
      phase: phase,
      playerHands: newHands,
      bottomCards: bottomCards,
      landlordIndex: landlordIndex,
      currentTurn: nextTurn,
      lastPlayedHand: analysis,
      lastPlayedCards: cards,
      lastPlayedBy: playerIndex,
      passCount: 0,
    );
  }

  /// Computed properties
  bool get canPlay =>
      phase == GamePhase.playing &&
      currentTurn == 0 &&
      selectedCardIds.isNotEmpty;

  bool get canPass =>
      phase == GamePhase.playing && currentTurn == 0 && lastPlayedHand != null;

  bool get isPlayerTurn => currentTurn == 0;

  /// Copy with helper
  GameState copyWith({
    GamePhase? phase,
    List<List<CardModel>>? playerHands,
    List<CardModel>? bottomCards,
    int? landlordIndex,
    int? currentTurn,
    HandAnalysis? lastPlayedHand,
    List<CardModel>? lastPlayedCards,
    int? lastPlayedBy,
    int? passCount,
    Set<String>? selectedCardIds,
    String? uiMessage,
    int? winnerIndex,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      playerHands: playerHands ?? this.playerHands,
      bottomCards: bottomCards ?? this.bottomCards,
      landlordIndex: landlordIndex ?? this.landlordIndex,
      currentTurn: currentTurn ?? this.currentTurn,
      lastPlayedHand: lastPlayedHand ?? this.lastPlayedHand,
      lastPlayedCards: lastPlayedCards ?? this.lastPlayedCards,
      lastPlayedBy: lastPlayedBy ?? this.lastPlayedBy,
      passCount: passCount ?? this.passCount,
      selectedCardIds: selectedCardIds ?? this.selectedCardIds,
      uiMessage: uiMessage ?? this.uiMessage,
      winnerIndex: winnerIndex ?? this.winnerIndex,
    );
  }

  GameState withUiMessage(String message) {
    return copyWith(uiMessage: message);
  }
}
