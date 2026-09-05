import 'package:flutter/material.dart';

/// Describes a single game shown in the BrainBuddies hub.
class GameEntry {
  const GameEntry({
    required this.id,
    required this.title,
    required this.tagline,
    required this.emoji,
    required this.color,
    required this.available,
  });

  final String id;
  final String title;
  final String tagline;
  final String emoji;
  final Color color;

  /// Whether the game is playable. `false` renders a "coming soon" card.
  final bool available;
}

/// The catalog of games in the hub. Add new games here to surface them.
class GameCatalog {
  GameCatalog._();

  static const numberQuest = GameEntry(
    id: 'number_quest',
    title: 'Number Quest',
    tagline: 'Add, subtract, multiply & divide through worlds of adventure.',
    emoji: '🔢',
    color: Color(0xFF6C63FF),
    available: true,
  );

  static const shapeSafari = GameEntry(
    id: 'shape_safari',
    title: 'Shape Safari',
    tagline: 'Spot shapes, count sides & finish patterns.',
    emoji: '🔺',
    color: Color(0xFF26A69A),
    available: true,
  );

  static const wordWizard = GameEntry(
    id: 'word_wizard',
    title: 'Word Wizard',
    tagline: 'Cast spelling & vocabulary spells.',
    emoji: '🔤',
    color: Color(0xFFEC407A),
    available: true,
  );

  static const clockHero = GameEntry(
    id: 'clock_hero',
    title: 'Clock Hero',
    tagline: 'Read the clock and tell the time.',
    emoji: '🕒',
    color: Color(0xFFFF9800),
    available: true,
  );

  static const List<GameEntry> all = [
    numberQuest,
    shapeSafari,
    wordWizard,
    clockHero,
  ];
}
