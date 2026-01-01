import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../engine/game_state.dart';
import 'card_sprite.dart';

class CenterPileComponent extends PositionComponent {
  final List<CardSprite> cardSprites = [];
  String lastPlayerName = '';

  CenterPileComponent() : super(anchor: Anchor.center);

  void updateState(GameState state) {
    if (state.lastPlayedCards == null || state.lastPlayedCards!.isEmpty) {
      // Remove old cards
      removeAll(cardSprites);
      cardSprites.clear();
      lastPlayerName = '';
      return;
    }

    // Update player name
    final playerIndex = state.lastPlayedBy;
    if (playerIndex == 0) {
      lastPlayerName = 'You';
    } else if (playerIndex == state.landlordIndex) {
      lastPlayerName = 'Landlord';
    } else {
      lastPlayerName = 'Farmer ${playerIndex + 1}';
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
    final cardWidth = 110.0; // Updated to match actual card size
    final spacing =
        115.0; // Increased to spread cards completely apart (no overlap)

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

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw player name label if there are cards
    if (lastPlayerName.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: lastPlayerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw background
      final padding = 8.0;
      final bgRect = Rect.fromLTWH(
        -textPainter.width / 2 - padding,
        -100,
        textPainter.width + padding * 2,
        textPainter.height + padding * 2,
      );

      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final rRect = RRect.fromRectAndRadius(bgRect, const Radius.circular(8));
      canvas.drawRRect(rRect, bgPaint);

      // Draw text
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -100 + padding));
    }
  }
}
