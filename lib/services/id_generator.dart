import 'dart:math';

final Random _random = Random.secure();

/// Gera um identificador único e ordenável no tempo, sem depender de
/// pacotes externos: timestamp em microssegundos + sufixo aleatório.
String generateId() {
  final timePart = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final randomPart = _random.nextInt(1 << 32).toRadixString(36);
  return '$timePart-$randomPart';
}
