import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../engine/card_model.dart';

class CardSprite extends PositionComponent with TapCallbacks, HoverCallbacks {
  final CardModel card;
  final VoidCallback? onTap;
  bool _isSelected;
  final bool isFaceDown;
  bool _isHovered = false;
  ui.Image? _queenImage;
  bool _queenImageLoaded = false;

  CardSprite({
    required this.card,
    this.onTap,
    bool isSelected = false,
    this.isFaceDown = false,
    super.position,
  }) : _isSelected = isSelected,
       super(size: Vector2(110, 154), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Load Cora's image if this is a Queen card
    if (card.rank == Rank.q && !isFaceDown) {
      await _loadQueenImage();
    }
  }

  Future<void> _loadQueenImage() async {
    try {
      final data = await rootBundle.load('assets/images/cora.png');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _queenImage = frame.image;
      _queenImageLoaded = true;
    } catch (e) {
      print('Failed to load queen image: $e');
      _queenImageLoaded = false;
    }
  }

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
      // Scale up and lift slightly
      add(
        ScaleEffect.to(
          Vector2.all(1.15),
          EffectController(duration: 0.3, curve: Curves.easeOutCubic),
        ),
      );
    } else {
      // Scale back to normal
      add(
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.3, curve: Curves.easeOutCubic),
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
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Multi-layer 3D shadow for depth
    if (!isFaceDown) {
      // Bottom shadow layer (darkest, furthest)
      final shadowPaint1 = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(rRect.shift(const Offset(0, 6)), shadowPaint1);

      // Mid shadow layer
      final shadowPaint2 = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(rRect.shift(const Offset(0, 3)), shadowPaint2);

      // Top shadow layer (lightest, closest)
      final shadowPaint3 = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRRect(rRect.shift(const Offset(0, 1)), shadowPaint3);
    }

    // Glow effect when selected (gold)
    if (_isSelected) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(rRect, glowPaint);
    }

    // Glow effect when hovered (yellow)
    if (_isHovered && !_isSelected) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFE55C).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(rRect, glowPaint);
    }

    // Card background
    final bgPaint = Paint()
      ..color = isFaceDown ? const Color(0xFF8B4513) : Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rRect, bgPaint);

    // Card border
    final borderPaint = Paint()
      ..color = _isSelected
          ? const Color(0xFFFFD700)
          : _isHovered
          ? const Color(0xFFFFE55C)
          : Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isSelected ? 3 : (_isHovered ? 2.5 : 2);

    canvas.drawRRect(rRect, borderPaint);

    if (!isFaceDown) {
      _drawCardFace(canvas, rect);
    }
  }

  void _drawCardFace(Canvas canvas, Rect rect) {
    // Determine color based on suit
    final color = _getCardColor();

    // Draw rank in top-left corner
    final rankText = _getRankText();
    final rankPainter = TextPainter(
      text: TextSpan(
        text: rankText,
        style: TextStyle(
          color: color,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    rankPainter.layout();
    rankPainter.paint(canvas, const Offset(12, 10));

    // Draw suit symbol in top-left corner (below rank)
    if (!card.isJoker) {
      final suitText = _getSuitSymbol();
      final topSuitPainter = TextPainter(
        text: TextSpan(
          text: suitText,
          style: TextStyle(color: color, fontSize: 30, height: 1.0),
        ),
        textDirection: TextDirection.ltr,
      );
      topSuitPainter.layout();
      topSuitPainter.paint(canvas, const Offset(12, 44));
    }

    // Draw large suit symbol in center (or Cora's picture for Queens)
    if (card.rank == Rank.q && _queenImageLoaded && _queenImage != null) {
      // Draw Cora's picture for Queen cards
      final imageWidth = rect.width * 0.7;
      final imageHeight = rect.height * 0.6;
      final imageX = (rect.width - imageWidth) / 2;
      final imageY = (rect.height - imageHeight) / 2;

      // Clip to rounded rectangle
      final imagePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(imageX, imageY, imageWidth, imageHeight),
            const Radius.circular(6),
          ),
        );

      canvas.save();
      canvas.clipPath(imagePath);

      // Draw the image
      final srcRect = Rect.fromLTWH(
        0,
        0,
        _queenImage!.width.toDouble(),
        _queenImage!.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(imageX, imageY, imageWidth, imageHeight);
      canvas.drawImageRect(
        _queenImage!,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );

      canvas.restore();

      // Draw border around image
      final imageBorderPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(imageX, imageY, imageWidth, imageHeight),
          const Radius.circular(6),
        ),
        imageBorderPaint,
      );
    } else if (!card.isJoker) {
      // Draw large suit symbol in center for non-Queen cards
      final suitText = _getSuitSymbol();
      final centerSuitPainter = TextPainter(
        text: TextSpan(
          text: suitText,
          style: TextStyle(
            color: color.withOpacity(0.3),
            fontSize: 64,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      centerSuitPainter.layout();
      centerSuitPainter.paint(
        canvas,
        Offset(
          rect.width / 2 - centerSuitPainter.width / 2,
          rect.height / 2 - centerSuitPainter.height / 2,
        ),
      );
    } else {
      // For jokers, draw "JOKER" text
      final jokerPainter = TextPainter(
        text: TextSpan(
          text: card.rank == Rank.sj ? 'JOKER' : 'JOKER',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      jokerPainter.layout();
      jokerPainter.paint(
        canvas,
        Offset(
          rect.width / 2 - jokerPainter.width / 2,
          rect.height / 2 - jokerPainter.height / 2,
        ),
      );
    }

    // Draw rank in bottom-right corner (upside down)
    canvas.save();
    canvas.translate(rect.width, rect.height);
    canvas.rotate(3.14159); // 180 degrees
    rankPainter.paint(canvas, const Offset(12, 10));

    if (!card.isJoker) {
      final suitText = _getSuitSymbol();
      final bottomSuitPainter = TextPainter(
        text: TextSpan(
          text: suitText,
          style: TextStyle(color: color, fontSize: 30, height: 1.0),
        ),
        textDirection: TextDirection.ltr,
      );
      bottomSuitPainter.layout();
      bottomSuitPainter.paint(canvas, const Offset(12, 44));
    }
    canvas.restore();
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
