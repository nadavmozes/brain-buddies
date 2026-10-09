/// A hub-wide achievement, earned across any game and shown in the shared
/// achievements shelf.
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });

  final String id;
  final String name;
  final String emoji;
  final String description;
}

/// The shared catalog of achievements. Games grant these by id via the
/// PlayerProfile; keep ids stable once shipped.
class Achievements {
  Achievements._();

  // General / cross-game
  static const firstGame = Achievement(
    id: 'first_game',
    name: 'First Steps',
    emoji: '👣',
    description: 'Finish your very first round.',
  );
  static const perfectRound = Achievement(
    id: 'perfect_round',
    name: 'Flawless',
    emoji: '💯',
    description: 'Get every answer right in a round.',
  );
  static const streak5 = Achievement(
    id: 'streak_5',
    name: 'On Fire',
    emoji: '🔥',
    description: 'Answer 5 in a row correctly.',
  );
  static const coin200 = Achievement(
    id: 'coin_200',
    name: 'Coin Collector',
    emoji: '💰',
    description: 'Collect 200 coins in total.',
  );
  static const coin500 = Achievement(
    id: 'coin_500',
    name: 'Treasure Hunter',
    emoji: '💎',
    description: 'Collect 500 coins in total.',
  );
  static const collector = Achievement(
    id: 'avatar_collector',
    name: 'Dress Up',
    emoji: '🎭',
    description: 'Own 3 different avatars.',
  );
  static const coin1000 = Achievement(
    id: 'coin_1000',
    name: 'Coin Champion',
    emoji: '🏦',
    description: 'Collect 1000 coins in total.',
  );
  static const wardrobe = Achievement(
    id: 'avatar_wardrobe',
    name: 'Fashionista',
    emoji: '👗',
    description: 'Own 6 different avatars.',
  );
  static const speedster = Achievement(
    id: 'speedster',
    name: 'Speedster',
    emoji: '⚡',
    description: 'Set a fastest-time record in any game.',
  );
  static const threeStar = Achievement(
    id: 'three_star',
    name: 'Star Power',
    emoji: '🌟',
    description: 'Earn 3 stars in a round.',
  );
  static const explorer = Achievement(
    id: 'hub_explorer',
    name: 'Explorer',
    emoji: '🗺️',
    description: 'Play every game at least once.',
  );
  static const streak3days = Achievement(
    id: 'streak_3_days',
    name: 'Daily Dabbler',
    emoji: '📅',
    description: 'Play 3 days in a row.',
  );
  static const streak7days = Achievement(
    id: 'streak_7_days',
    name: 'Week Warrior',
    emoji: '🗓️',
    description: 'Play 7 days in a row.',
  );
  static const missionsDone = Achievement(
    id: 'missions_done',
    name: 'Mission Master',
    emoji: '📋',
    description: 'Finish all of today\'s missions.',
  );
  static const petLevel5 = Achievement(
    id: 'pet_level5',
    name: 'Pet Pal',
    emoji: '🐣',
    description: 'Grow your pet to level 5.',
  );
  static const petLevel10 = Achievement(
    id: 'pet_level10',
    name: 'Pet Pro',
    emoji: '🐦',
    description: 'Grow your pet to level 10.',
  );

  // Number Quest
  static const bossFriend = Achievement(
    id: 'nq_boss',
    name: 'Boss Beater',
    emoji: '⚔️',
    description: 'Beat a boss in Number Quest.',
  );
  static const multMaster = Achievement(
    id: 'nq_mult',
    name: 'Times Master',
    emoji: '✖️',
    description: 'Answer 50 multiplication questions right.',
  );
  static const heroLevel5 = Achievement(
    id: 'nq_level5',
    name: 'Rising Star',
    emoji: '⭐',
    description: 'Reach hero level 5 in Number Quest.',
  );

  // Shape Safari
  static const guardianFriend = Achievement(
    id: 'ss_guardian',
    name: 'Animal Friend',
    emoji: '🤝',
    description: 'Befriend a guardian in Shape Safari.',
  );
  static const shapeExplorer = Achievement(
    id: 'ss_explorer',
    name: 'Trailblazer',
    emoji: '🧭',
    description: 'Clear a whole habitat trail in Shape Safari.',
  );

  // Word Wizard
  static const spellMaster = Achievement(
    id: 'ww_master',
    name: 'Spell Master',
    emoji: '📜',
    description: 'Get a perfect round in Word Wizard.',
  );

  // Clock Hero
  static const timeKeeper = Achievement(
    id: 'ch_keeper',
    name: 'Time Keeper',
    emoji: '⏰',
    description: 'Get a perfect round in Clock Hero.',
  );

  // Money Math
  static const moneyMaster = Achievement(
    id: 'mm_master',
    name: 'Money Master',
    emoji: '💵',
    description: 'Get a perfect round in Money Math.',
  );

  // Memory Match
  static const memoryMaster = Achievement(
    id: 'mem_master',
    name: 'Memory Master',
    emoji: '🧠',
    description: 'Get a perfect round in Memory Match.',
  );

  static const List<Achievement> all = [
    firstGame,
    perfectRound,
    threeStar,
    streak5,
    speedster,
    coin200,
    coin500,
    coin1000,
    collector,
    wardrobe,
    explorer,
    streak3days,
    streak7days,
    missionsDone,
    petLevel5,
    petLevel10,
    bossFriend,
    multMaster,
    heroLevel5,
    guardianFriend,
    shapeExplorer,
    spellMaster,
    timeKeeper,
    moneyMaster,
    memoryMaster,
  ];

  static Achievement byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
