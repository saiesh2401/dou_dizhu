import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../engine/card_model.dart';

class CardSprite extends PositionComponent with TapCallbacks, HoverCallbacks {
  final CardModel card;
  final VoidCallback? onTap;
  bool _isSelected;
  final bool isFaceDown;
  bool _isHovered = false;

  CardSprite({
    required this.card,
    this.onTap,
    bool isSelected = false,
    this.isFaceDown = false,
    super.position,
  }) : _isSelected = isSelected,
       super(size: Vector2(60, 84), anchor: Anchor.center);

  bool get isSelected => _isSelected;

  set isSelected(bool value) {
    if (_isSelected != value) {
      _isSelected = value;
      _animateSelection(value);
    }
  }

  void _animateSelection(bool selected) {
    removeAll(children.whereType<Effect>());

    if (selected) {
      // Scale up slightly
      add(
        ScaleEffect.to(
          Vector2.all(1.1),
          EffectController(duration: 0.2, curve: Curves.easeOutCubic),
        ),
      );
    } else {
      // Scale back to normal
      add(
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.2, curve: Curves.easeOutCubic),
        ),
      );
    }
  }

  @override
  void onHoverEnter() {
    _isHovered = true;
  }

  @override
  void onHoverExit() {
    _isHovered = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = size.toRect();

    // Card background with glow effect when hovered
    final bgPaint = Paint()
      ..color = isFaceDown ? const Color(0xFF8B4513) : Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = _isSelected
          ? const Color(0xFFFFD700)
          : _isHovered
          ? const Color(0xFFFFE55C)
          : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isSelected ? 3 : (_isHovered ? 2.5 : 2);

    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Glow effect when hovered
    if (_isHovered && !_isSelected) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFE55C).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(rRect, glowPaint);
    }

    canvas.drawRRect(rRect, bgPaint);
    canvas.drawRRect(rRect, borderPaint);

    if (!isFaceDown) {
      _drawCardFace(canvas, rect);
    }
  }

  void _drawCardFace(Canvas canvas, Rect rect) {
    // Determine color based on suit
    final color = _getCardColor();

    // Draw rank
    final rankText = _getRankText();
    final textPainter = TextPainter(
      text: TextSpan(
        text: rankText,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(6, 6));

    // Draw suit symbol
    if (!card.isJoker) {
      final suitText = _getSuitSymbol();
      final suitPainter = TextPainter(
        text: TextSpan(
          text: suitText,
          style: TextStyle(color: color, fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      );
      suitPainter.layout();
      suitPainter.paint(
        canvas,
        Offset(
          rect.width / 2 - suitPainter.width / 2,
          rect.height / 2 - suitPainter.height / 2,
        ),
      );
    }
  }

  Color _getCardColor() {
    if (card.isJoker) {
      return card.rank == Rank.sj ? Colors.black : Colors.red;
    }
    return (card.suit == Suit.hearts || card.suit == Suit.diamonds)
        ? Colors.red
        : Colors.black;
  }

  String _getRankText() {
    switch (card.rank) {
      case Rank.r3:
        return '3';
      case Rank.r4:
        return '4';
      case Rank.r5:
        return '5';
      case Rank.r6:
        return '6';
      case Rank.r7:
        return '7';
      case Rank.r8:
        return '8';
      case Rank.r9:
        return '9';
      case Rank.r10:
        return '10';
      case Rank.j:
        return 'J';
      case Rank.q:
        return 'Q';
      case Rank.k:
        return 'K';
      case Rank.a:
        return 'A';
      case Rank.r2:
        return '2';
      case Rank.sj:
        return 'S';
      case Rank.bj:
        return 'B';
    }
  }

  String _getSuitSymbol() {
    switch (card.suit) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.none:
        return '';
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap?.call();
  }
}
