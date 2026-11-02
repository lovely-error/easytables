import 'dart:math';

final Random _random = Random();

String newId(String prefix) {
  final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final noise = _random.nextInt(1 << 32).toRadixString(36);
  return '$prefix$timestamp$noise';
}
