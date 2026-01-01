import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 3D perspective table with wood texture and decorative borders
class TableComponent extends PositionComponent with HasGameRef {
  ui.Image? _backgroundImage;
  bool _imageLoaded = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    await _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final data = await rootBundle.load(
        'assets/images/cityscape_background.png',
      );
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _backgroundImage = frame.image;
      _imageLoaded = true;
    } catch (e) {
      print('Failed to load background image: $e');
      _imageLoaded = false;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw background image if loaded
    if (_imageLoaded && _backgroundImage != null) {
      final srcRect = Rect.fromLTWH(
        0,
        0,
        _backgroundImage!.width.toDouble(),
        _backgroundImage!.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawImageRect(
        _backgroundImage!,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      // Fallback gradient background
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF87CEEB), // Sky blue
          const Color(0xFFFFB347), // Sunset orange
          const Color(0xFF0A4D2E), // Dark green
        ],
        stops: const [0.0, 0.4, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.x, size.y));

      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
    }

    // Draw 3D perspective table
    _draw3DTable(canvas);
  }

  void _draw3DTable(Canvas canvas) {
    final centerX = size.x / 2;
    final centerY = size.y * 0.5;

    // Table dimensions (trapezoid for 3D perspective)
    final tableWidth = size.x * 0.7;
    final tableHeight = size.y * 0.5;
    final topWidth = tableWidth * 0.6; // Narrower at top for perspective

    // Create trapezoid path
    final tablePath = Path()
      ..moveTo(centerX - topWidth / 2, centerY - tableHeight / 2) // Top-left
      ..lineTo(centerX + topWidth / 2, centerY - tableHeight / 2) // Top-right
      ..lineTo(
        centerX + tableWidth / 2,
        centerY + tableHeight / 2,
      ) // Bottom-right
      ..lineTo(
        centerX - tableWidth / 2,
        centerY + tableHeight / 2,
      ) // Bottom-left
      ..close();

    // Wood texture gradient
    final woodGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFD4A574), // Light wood
        const Color(0xFFC19A6B), // Medium wood
        const Color(0xFFB8860B), // Dark gold
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final woodPaint = Paint()
      ..shader = woodGradient.createShader(
        Rect.fromLTWH(
          centerX - tableWidth / 2,
          centerY - tableHeight / 2,
          tableWidth,
          tableHeight,
        ),
      );

    // Draw table surface
    canvas.drawPath(tablePath, woodPaint);

    // Draw decorative gold border
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawPath(tablePath, borderPaint);

    // Draw inner border (darker gold)
    final innerBorderPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final innerPath = Path()
      ..moveTo(centerX - topWidth / 2 + 10, centerY - tableHeight / 2 + 10)
      ..lineTo(centerX + topWidth / 2 - 10, centerY - tableHeight / 2 + 10)
      ..lineTo(centerX + tableWidth / 2 - 10, centerY + tableHeight / 2 - 10)
      ..lineTo(centerX - tableWidth / 2 + 10, centerY + tableHeight / 2 - 10)
      ..close();

    canvas.drawPath(innerPath, innerBorderPaint);

    // Draw center emblem (circular pattern)
    final emblemRadius = 40.0;
    final emblemPaint = Paint()
      ..color = const Color(0xFFB8860B).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Outer circle
    canvas.drawCircle(Offset(centerX, centerY), emblemRadius, emblemPaint);

    // Inner circles
    canvas.drawCircle(
      Offset(centerX, centerY),
      emblemRadius * 0.7,
      emblemPaint,
    );

    canvas.drawCircle(
      Offset(centerX, centerY),
      emblemRadius * 0.4,
      emblemPaint,
    );

    // Decorative lines radiating from center
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final x1 = centerX + (emblemRadius * 0.4) * cos(angle);
      final y1 = centerY + (emblemRadius * 0.4) * sin(angle);
      final x2 = centerX + emblemRadius * cos(angle);
      final y2 = centerY + emblemRadius * sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), emblemPaint);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}
