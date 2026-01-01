import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TableComponent extends RectangleComponent {
  TableComponent()
    : super(
        paint: Paint()
          ..color = const Color(0xFF0B5D3B)
          ..style = PaintingStyle.fill,
      );

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}
