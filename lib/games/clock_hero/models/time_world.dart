import 'package:flutter/material.dart';

/// The time-of-day worlds in Clock Hero. Each unlocks finer minute precision
/// and a higher base difficulty.
enum TimeWorld {
  morning,
  afternoon,
  night,
}

extension TimeWorldInfo on TimeWorld {
  String get label {
    switch (this) {
      case TimeWorld.morning:
        return 'Morning';
      case TimeWorld.afternoon:
        return 'Afternoon';
      case TimeWorld.night:
        return 'Night';
    }
  }

  String get subtitle {
    switch (this) {
      case TimeWorld.morning:
        return "O'clock times to wake up to.";
      case TimeWorld.afternoon:
        return 'Half past and quarter times.';
      case TimeWorld.night:
        return 'Five-minute times and tricky clocks.';
    }
  }

  String get emoji {
    switch (this) {
      case TimeWorld.morning:
        return '🌅';
      case TimeWorld.afternoon:
        return '☀️';
      case TimeWorld.night:
        return '🌙';
    }
  }

  Color get color {
    switch (this) {
      case TimeWorld.morning:
        return const Color(0xFFFFB74D);
      case TimeWorld.afternoon:
        return const Color(0xFFFF8A65);
      case TimeWorld.night:
        return const Color(0xFF5C6BC0);
    }
  }

  double get baseDifficulty {
    switch (this) {
      case TimeWorld.morning:
        return 0.1;
      case TimeWorld.afternoon:
        return 0.45;
      case TimeWorld.night:
        return 0.8;
    }
  }

  /// The minute values that can appear in this world.
  List<int> get minutePool {
    switch (this) {
      case TimeWorld.morning:
        return const [0];
      case TimeWorld.afternoon:
        return const [0, 30, 15, 45];
      case TimeWorld.night:
        return const [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
    }
  }
}

/// A friendly guardian at the end of each world's trail. Instead of defeating
/// it, the child "wakes" or "greets" it by answering well.
class TimeGuardian {
  const TimeGuardian({required this.name, required this.emoji});

  final String name;
  final String emoji;
}

class TimeGuardians {
  TimeGuardians._();

  static const Map<TimeWorld, TimeGuardian> _byWorld = {
    TimeWorld.morning: TimeGuardian(name: 'Rooster Red', emoji: '🐓'),
    TimeWorld.afternoon: TimeGuardian(name: 'Sunny Cat', emoji: '🐈'),
    TimeWorld.night: TimeGuardian(name: 'Luna Owl', emoji: '🦉'),
  };

  static TimeGuardian forWorld(TimeWorld w) => _byWorld[w]!;
}

/// A single stop on a world's clock trail.
class ClockLevel {
  const ClockLevel({
    required this.world,
    required this.index,
    required this.isBoss,
  });

  final TimeWorld world;
  final int index;
  final bool isBoss;

  int get number => index + 1;
  String get id => '${world.name}_$index';
  int get questionCount => isBoss ? 8 : 5;
  String get title => isBoss ? 'Guardian' : 'Stop $number';
  TimeGuardian get guardian => TimeGuardians.forWorld(world);

  double difficulty(int levelsPerTrail) {
    final ramp = index / (levelsPerTrail - 1) * 0.25;
    return (world.baseDifficulty + ramp).clamp(0.0, 1.0);
  }
}

/// A world's ordered trail of stops.
class ClockTrail {
  ClockTrail({required this.world, required this.levels});
  final TimeWorld world;
  final List<ClockLevel> levels;
  int get length => levels.length;
}

/// Builds the fixed clock-trail layout: each world is a path of stops ending
/// in a guardian.
class ClockMap {
  ClockMap._();

  static const int levelsPerTrail = 5; // 4 stops + 1 guardian

  static final Map<TimeWorld, ClockTrail> trails = {
    for (final w in TimeWorld.values)
      w: ClockTrail(
        world: w,
        levels: List.generate(
          levelsPerTrail,
          (i) => ClockLevel(
            world: w,
            index: i,
            isBoss: i == levelsPerTrail - 1,
          ),
        ),
      ),
  };

  static ClockTrail trail(TimeWorld w) => trails[w]!;

  static List<ClockLevel> get allLevels =>
      [for (final w in TimeWorld.values) ...trail(w).levels];
}
