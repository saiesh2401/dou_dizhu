import 'hand_type.dart';

class HandComparator {
  /// Check if the current hand can beat the previous hand
  /// Returns true if current can beat previous
  static bool canBeat(HandAnalysis current, HandAnalysis? previous) {
    // First play - any valid hand is allowed
    if (previous == null || !previous.isValid) {
      return current.isValid;
    }

    // Invalid hand cannot beat anything
    if (!current.isValid) return false;

    // Rocket beats everything
    if (current.type == HandType.rocket) return true;

    // Bomb beats everything except rocket and bigger bombs
    if (current.type == HandType.bomb) {
      if (previous.type == HandType.rocket) return false;
      if (previous.type == HandType.bomb) {
        return current.compareValue > previous.compareValue;
      }
      return true; // Bomb beats all non-bomb/rocket hands
    }

    // Previous was a bomb or rocket - only bomb/rocket can beat it
    if (previous.type == HandType.bomb || previous.type == HandType.rocket) {
      return false;
    }

    // Same type comparison
    if (current.type != previous.type) return false;

    // Compare based on type
    switch (current.type) {
      case HandType.single:
      case HandType.pair:
      case HandType.triple:
      case HandType.tripleWithSingle:
      case HandType.tripleWithPair:
      case HandType.quadWithSingles:
      case HandType.quadWithPairs:
        return current.compareValue > previous.compareValue;

      case HandType.straight:
      case HandType.consecutivePairs:
      case HandType.airplane:
      case HandType.airplaneWithSingles:
      case HandType.airplaneWithPairs:
        // Must have same length
        if (current.length != previous.length) return false;
        // Compare base rank
        return current.baseRank > previous.baseRank;

      default:
        return false;
    }
  }

  /// Get a human-readable description of why a hand cannot beat another
  static String? getInvalidReason(
    HandAnalysis current,
    HandAnalysis? previous,
  ) {
    if (!current.isValid) return 'Invalid hand combination';
    if (previous == null) return null; // First play is always valid

    if (current.type == HandType.rocket) return null;
    if (current.type == HandType.bomb && previous.type != HandType.rocket) {
      if (previous.type == HandType.bomb &&
          current.compareValue <= previous.compareValue) {
        return 'Bomb is not strong enough';
      }
      return null;
    }

    if (previous.type == HandType.bomb || previous.type == HandType.rocket) {
      return 'Can only beat with a stronger bomb or rocket';
    }

    if (current.type != previous.type) {
      return 'Must play the same hand type (${previous.type.name})';
    }

    if (current.type == HandType.straight ||
        current.type == HandType.consecutivePairs ||
        current.type == HandType.airplane ||
        current.type == HandType.airplaneWithSingles ||
        current.type == HandType.airplaneWithPairs) {
      if (current.length != previous.length) {
        return 'Must have the same length (${previous.length})';
      }
      if (current.baseRank <= previous.baseRank) {
        return 'Not strong enough';
      }
    } else {
      if (current.compareValue <= previous.compareValue) {
        return 'Not strong enough';
      }
    }

    return null;
  }
}
