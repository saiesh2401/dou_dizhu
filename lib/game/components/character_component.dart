import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CharacterPosition { left, top, right }

/// Anime character sprite component with avatar circle
class CharacterComponent extends PositionComponent {
  final CharacterPosition characterPosition;
  final int playerIndex;
  final String playerName;
  final int coins;

  ui.Image? _characterImage;
  bool _imageLoaded = false;

  CharacterComponent({
    required this.characterPosition,
    required this.playerIndex,
    this.playerName = 'Player',
    this.coins = 1922,
    super.position,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadCharacterImage();
  }

  Future<void> _loadCharacterImage() async {
    try {
      final imagePath = _getImagePath();
      final data = await rootBundle.load(imagePath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _characterImage = frame.image;
      _imageLoaded = true;

      // Set size based on image aspect ratio to preserve proportions
      final imageWidth = _characterImage!.width.toDouble();
      final imageHeight = _characterImage!.height.toDouble();
      final aspectRatio = imageWidth / imageHeight;

      // Scale to reasonable display size while preserving aspect ratio
      final displayHeight = 180.0;
      final displayWidth = displayHeight * aspectRatio;
      size = Vector2(displayWidth, displayHeight);
    } catch (e) {
      print('Failed to load character image: $e');
      _imageLoaded = false;
      size = Vector2(120, 180); // Fallback size
    }
  }

  String _getImagePath() {
    switch (characterPosition) {
      case CharacterPosition.left:
        return 'assets/images/character_left.png';
      case CharacterPosition.top:
        return 'assets/images/character_top.png';
      case CharacterPosition.right:
        return 'assets/images/character_right.png';
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw character sprite if loaded
    if (_imageLoaded && _characterImage != null) {
      final srcRect = Rect.fromLTWH(
        0,
        0,
        _characterImage!.width.toDouble(),
        _characterImage!.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawImageRect(
        _characterImage!,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    }

    // Draw avatar circle and player info for left position
    if (characterPosition == CharacterPosition.left) {
      _drawPlayerInfo(canvas);
    }
  }

  void _drawPlayerInfo(Canvas canvas) {
    // Avatar circle (top-left of character)
    final avatarCenter = Offset(-40, -60);
    final avatarRadius = 25.0;

    // Avatar background
    final avatarBgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(avatarCenter, avatarRadius, avatarBgPaint);

    // Avatar border (gold)
    final avatarBorderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(avatarCenter, avatarRadius, avatarBorderPaint);

    // Coins display below avatar
    final coinsCenter = Offset(-40, -20);

    // Coins background
    final coinsBgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final coinsRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: coinsCenter, width: 70, height: 24),
      const Radius.circular(12),
    );

    canvas.drawRRect(coinsRect, coinsBgPaint);

    // Coins border
    final coinsBorderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(coinsRect, coinsBorderPaint);

    // Coin icon (gold circle)
    final coinIconPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(coinsCenter.dx - 20, coinsCenter.dy),
      6,
      coinIconPaint,
    );

    // Coins text
    final textPainter = TextPainter(
      text: TextSpan(
        text: coins.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(coinsCenter.dx - 5, coinsCenter.dy - textPainter.height / 2),
    );
  }
}
