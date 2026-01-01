import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_controller.dart';
import '../../../engine/game_state.dart';

/// Main game state provider
final gameControllerProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);
