import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../engine/game_state.dart';
import 'card_sprite.dart';

class CenterPileComponent extends PositionComponent {
  final List<CardSprite> cardSprites = [];

  CenterPileComponent() : super(anchor: Anchor.center);

  void updateState(GameState state) {
    if (state.lastPlayedCards == null || state.lastPlayedCards!.isEmpty) {
      // Remove old cards
      removeAll(cardSprites);
      cardSprites.clear();
      return;
    }

    // Check if cards changed
    final newCards = state.lastPlayedCards!;
    if (cardSprites.isNotEmpty && cardSprites.length == newCards.length) {
      bool same = true;
      for (int i = 0; i < newCards.length; i++) {
        if (cardSprites[i].card != newCards[i]) {
          same = false;
          break;
        }
      }
      if (same) return; // Same cards, no update needed
    }

    // Remove old cards
    removeAll(cardSprites);
    cardSprites.clear();

    // Add new cards with animation
    final cards = newCards;
    final cardWidth = 50.0;
    final spacing = 30.0;

    final totalWidth = (cards.length - 1) * spacing + cardWidth;
    final startX = -totalWidth / 2 + cardWidth / 2;

    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final x = startX + i * spacing;

      final cardSprite = CardSprite(card: card, position: Vector2(x, 0));

      // Scale in effect
      cardSprite.scale = Vector2.all(0.5);
      cardSprite.add(
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(
            duration: 0.3,
            curve: Curves.easeOutBack,
            startDelay: i * 0.05,
          ),
        ),
      );

      cardSprites.add(cardSprite);
      add(cardSprite);
    }
  }
}
