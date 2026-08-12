import 'dart:math';

final Random _rng = Random();

/// Generates a random hex id (32 chars) that avoids the collision risk of
/// timestamp-based ids.
String generateId() {
  final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
