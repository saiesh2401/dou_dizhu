import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../engine/game_state.dart';
import '../../engine/card_model.dart';
import 'card_sprite.dart';

typedef CardTapHandler = void Function(String cardId);

class HandComponent extends PositionComponent {
  final CardTapHandler onCardTapped;
  final List<CardSprite> cardSprites = [];
  bool _isFirstDeal = true;

  HandComponent({required this.onCardTapped}) : super(anchor: Anchor.center);

  void updateState(GameState state) {
    final hand = state.playerHands.isNotEmpty
        ? state.playerHands[0]
        : <CardModel>[];

    if (hand.isEmpty) {
      // Remove all cards
      removeAll(cardSprites);
      cardSprites.clear();
      return;
    }

    // Check if this is a new deal (different cards)
    final isNewDeal =
        cardSprites.isEmpty ||
        cardSprites.length != hand.length ||
        !_cardsMatch(cardSprites.map((s) => s.card).toList(), hand);

    if (isNewDeal) {
      // Remove old cards and create new ones
      removeAll(cardSprites);
      cardSprites.clear();
      _createCards(hand, state.selectedCardIds, shouldAnimate: _isFirstDeal);
      _isFirstDeal = false;
    } else {
      // Just update selection state and position
      for (int i = 0; i < cardSprites.length; i++) {
        final card = hand[i];
        final isSelected = state.selectedCardIds.contains(card.id);
        final wasSelected = cardSprites[i].isSelected;

        cardSprites[i].isSelected = isSelected;

        // Animate position change if selection changed
        if (isSelected != wasSelected) {
          final cardWidth = 60.0;
          final maxSpacing = 40.0;
          final minSpacing = 15.0;
          final totalCards = hand.length;
          final availableWidth = 350.0;
          var spacing = (availableWidth - cardWidth) / (totalCards - 1);
          spacing = spacing.clamp(minSpacing, maxSpacing);
          final totalWidth = (totalCards - 1) * spacing + cardWidth;
          final startX = -totalWidth / 2 + cardWidth / 2;
          final targetX = startX + i * spacing;
          final targetY = isSelected ? -20.0 : 0.0;

          cardSprites[i].add(
            MoveEffect.to(
              Vector2(targetX, targetY),
              EffectController(duration: 0.2, curve: Curves.easeOutCubic),
            ),
          );
        }
      }
    }
  }

  bool _cardsMatch(List<CardModel> list1, List<CardModel> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _createCards(
    List<CardModel> hand,
    Set<String> selectedIds, {
    bool shouldAnimate = false,
  }) {
    final cardWidth = 60.0;
    final maxSpacing = 40.0;
    final minSpacing = 15.0;

    // Calculate spacing based on number of cards
    final totalCards = hand.length;
    final availableWidth = 350.0;
    var spacing = (availableWidth - cardWidth) / (totalCards - 1);
    spacing = spacing.clamp(minSpacing, maxSpacing);

    final totalWidth = (totalCards - 1) * spacing + cardWidth;
    final startX = -totalWidth / 2 + cardWidth / 2;

    for (int i = 0; i < hand.length; i++) {
      final card = hand[i];
      final isSelected = selectedIds.contains(card.id);

      final targetX = startX + i * spacing;
      final targetY = 0.0;

      final cardSprite = CardSprite(
        card: card,
        position: shouldAnimate ? Vector2(0, -200) : Vector2(targetX, targetY),
        isSelected: isSelected,
        onTap: () => onCardTapped(card.id),
      );

      cardSprites.add(cardSprite);
      add(cardSprite);

      // Add dealing animation
      if (shouldAnimate) {
        final delay = i * 0.05;
        cardSprite.add(
          MoveEffect.to(
            Vector2(targetX, targetY),
            EffectController(
              duration: 0.4,
              curve: Curves.easeOutCubic,
              startDelay: delay,
            ),
          ),
        );
      }
    }
  }
}
