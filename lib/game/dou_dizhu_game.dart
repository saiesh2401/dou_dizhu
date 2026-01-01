import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../engine/game_state.dart';
import 'components/table_component.dart';
import 'components/hand_component.dart';
import 'components/opponent_hand_component.dart';
import 'components/center_pile_component.dart';

typedef GameStateReader = GameState Function();
typedef CardTapHandler = void Function(String cardId);

class DouDizhuGame extends FlameGame {
  final GameStateReader readGameState;
  final CardTapHandler onCardTapped;

  DouDizhuGame({required this.readGameState, required this.onCardTapped});

  late TableComponent table;
  late HandComponent playerHand;
  late OpponentHandComponent leftOpponent;
  late OpponentHandComponent topOpponent;
  late CenterPileComponent centerPile;

  @override
  Color backgroundColor() => const Color(0xFF0B5D3B);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add table background
    table = TableComponent();
    add(table);

    // Add center pile (for last played cards)
    centerPile = CenterPileComponent();
    add(centerPile);

    // Add opponent hands
    leftOpponent = OpponentHandComponent(
      opponentPosition: OpponentPosition.left,
    );
    add(leftOpponent);

    topOpponent = OpponentHandComponent(opponentPosition: OpponentPosition.top);
    add(topOpponent);

    // Add player hand (bottom)
    playerHand = HandComponent(onCardTapped: onCardTapped);
    add(playerHand);
  }

  /// Called from Flutter layer when state changes
  void onStateChanged(GameState newState) {
    // Don't update if components aren't loaded yet
    if (!isMounted) return;

    playerHand.updateState(newState);
    leftOpponent.updateState(newState, playerIndex: 1);
    topOpponent.updateState(newState, playerIndex: 2);
    centerPile.updateState(newState);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Don't update if components aren't loaded yet
    if (!isMounted) return;

    // Update component positions based on screen size
    centerPile.position = Vector2(size.x / 2, size.y * 0.4);

    leftOpponent.position = Vector2(20, size.y * 0.3);
    topOpponent.position = Vector2(size.x / 2, 40);

    playerHand.position = Vector2(size.x / 2, size.y - 180);
  }
}
