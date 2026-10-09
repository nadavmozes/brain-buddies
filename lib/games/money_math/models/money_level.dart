import 'package:flutter/material.dart';

/// Money Math worlds (piggy banks), each with a bigger coin range + a boss.
enum MoneyWorld {
  piggy, // small coins / counting
  wallet, // make amounts, compare
  vault, // bigger amounts, change
}

extension MoneyWorldInfo on MoneyWorld {
  String get label {
    switch (this) {
      case MoneyWorld.piggy:
        return 'Piggy Bank';
      case MoneyWorld.wallet:
        return 'Wallet';
      case MoneyWorld.vault:
        return 'Vault';
    }
  }

  String get subtitle {
    switch (this) {
      case MoneyWorld.piggy:
        return 'Count small groups of coins.';
      case MoneyWorld.wallet:
        return 'Make amounts and compare money.';
      case MoneyWorld.vault:
        return 'Bigger amounts and making change.';
    }
  }

  String get emoji {
    switch (this) {
      case MoneyWorld.piggy:
        return '🐷';
      case MoneyWorld.wallet:
        return '👛';
      case MoneyWorld.vault:
        return '🏦';
    }
  }

  Color get color {
    switch (this) {
      case MoneyWorld.piggy:
        return const Color(0xFF66BB6A);
      case MoneyWorld.wallet:
        return const Color(0xFF42A5F5);
      case MoneyWorld.vault:
        return const Color(0xFF8D6E63);
    }
  }

  double get baseDifficulty {
    switch (this) {
      case MoneyWorld.piggy:
        return 0.1;
      case MoneyWorld.wallet:
        return 0.45;
      case MoneyWorld.vault:
        return 0.8;
    }
  }
}

/// The guardian at the end of each world's trail (friendly, never scary).
class MoneyGuardian {
  const MoneyGuardian({required this.name, required this.emoji});
  final String name;
  final String emoji;
}

class MoneyGuardians {
  MoneyGuardians._();

  static const Map<MoneyWorld, MoneyGuardian> _byWorld = {
    MoneyWorld.piggy: MoneyGuardian(name: 'Penny Pig', emoji: '🐷'),
    MoneyWorld.wallet: MoneyGuardian(name: 'Buck Bunny', emoji: '🐰'),
    MoneyWorld.vault: MoneyGuardian(name: 'Goldie Fox', emoji: '🦊'),
  };

  static MoneyGuardian forWorld(MoneyWorld w) => _byWorld[w]!;
}

/// A single stop on a world's money trail.
class MoneyLevel {
  const MoneyLevel({
    required this.world,
    required this.index,
    required this.isBoss,
  });

  final MoneyWorld world;
  final int index;
  final bool isBoss;

  int get number => index + 1;
  String get id => '${world.name}_$index';
  int get questionCount => isBoss ? 8 : 5;
  String get title => isBoss ? 'Guardian' : 'Stop $number';
  MoneyGuardian get guardian => MoneyGuardians.forWorld(world);

  double difficulty(int levelsPerTrail) {
    final ramp = index / (levelsPerTrail - 1) * 0.25;
    return (world.baseDifficulty + ramp).clamp(0.0, 1.0);
  }
}

class MoneyTrail {
  MoneyTrail({required this.world, required this.levels});
  final MoneyWorld world;
  final List<MoneyLevel> levels;
  int get length => levels.length;
}

class MoneyMap {
  MoneyMap._();

  static const int levelsPerTrail = 5;

  static final Map<MoneyWorld, MoneyTrail> trails = {
    for (final w in MoneyWorld.values)
      w: MoneyTrail(
        world: w,
        levels: List.generate(
          levelsPerTrail,
          (i) => MoneyLevel(
            world: w,
            index: i,
            isBoss: i == levelsPerTrail - 1,
          ),
        ),
      ),
  };

  static MoneyTrail trail(MoneyWorld w) => trails[w]!;

  static List<MoneyLevel> get allLevels =>
      [for (final w in MoneyWorld.values) ...trail(w).levels];
}
