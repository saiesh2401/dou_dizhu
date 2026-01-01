import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../engine/game_state.dart';

enum OpponentPosition { left, top }

class OpponentHandComponent extends PositionComponent {
  final OpponentPosition opponentPosition;
  int cardCount = 0;
  String playerName = '';

  OpponentHandComponent({required this.opponentPosition})
    : super(anchor: Anchor.topLeft);

  void updateState(GameState state, {required int playerIndex}) {
    if (state.playerHands.length > playerIndex) {
      cardCount = state.playerHands[playerIndex].length;
      playerName = playerIndex == state.landlordIndex ? 'Landlord' : 'Farmer';
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw player info
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$playerName\n$cardCount cards',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    // Draw card backs
    if (opponentPosition == OpponentPosition.left) {
      _drawLeftCards(canvas);
    } else {
      _drawTopCards(canvas);
    }
  }

  void _drawLeftCards(Canvas canvas) {
    const cardWidth = 40.0;
    const cardHeight = 56.0;
    const spacing = 3.0;

    for (int i = 0; i < math.min(cardCount, 10); i++) {
      final rect = Rect.fromLTWH(0, 40 + i * spacing, cardWidth, cardHeight);

      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

      final bgPaint = Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRRect(rRect, bgPaint);
      canvas.drawRRect(rRect, borderPaint);
    }
  }

  void _drawTopCards(Canvas canvas) {
    const cardWidth = 40.0;
    const cardHeight = 56.0;
    const spacing = 5.0;

    final totalWidth = math.min(cardCount, 10) * spacing + cardWidth;
    final startX = -totalWidth / 2;

    for (int i = 0; i < math.min(cardCount, 10); i++) {
      final rect = Rect.fromLTWH(
        startX + i * spacing,
        30,
        cardWidth,
        cardHeight,
      );

      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

      final bgPaint = Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRRect(rRect, bgPaint);
      canvas.drawRRect(rRect, borderPaint);
    }
  }
}
