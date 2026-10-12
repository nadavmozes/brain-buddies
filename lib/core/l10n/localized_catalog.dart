import 'app_lang.dart';

/// Localized strings for the app's `const` data catalogs (game catalog,
/// achievements, missions, avatars, pet stages, and per-game world/boss
/// labels).
///
/// The design doc (§4.5) keeps the existing `const` catalogs — their ids are
/// the stable keys — and resolves content through this parallel id→Hebrew
/// lookup. English is NOT duplicated here: callers pass the existing English
/// literal as the fallback, so when the language is English (or a Hebrew value
/// is missing) the original string is used unchanged. This keeps every
/// English-asserting test green with zero risk of drift.
///
/// Keys are grouped by a `domain` so ids never collide across catalogs.
class LocalizedCatalog {
  LocalizedCatalog._();

  /// Resolves [key] in [domain] for [lang], falling back to [fallback] (the
  /// existing English literal) when English is selected or no translation
  /// exists.
  static String resolve(
    String domain,
    String key,
    String fallback, {
    required AppLang lang,
  }) {
    if (lang != AppLang.he) return fallback;
    return _he[domain]?[key] ?? fallback;
  }

  // Hebrew values keyed by domain → stable id/key.
  static const Map<String, Map<String, String>> _he = {
    // ---- game_catalog.dart (titles + taglines) ----
    'game.title': {
      'number_quest': 'מסע המספרים',
      'shape_safari': 'ספארי הצורות',
      'word_wizard': 'קוסם המילים',
      'clock_hero': 'גיבור השעון',
      'money_math': 'חשבון הכסף',
      'memory_match': 'משחק הזיכרון',
    },
    'game.tagline': {
      'number_quest': 'חיבור, חיסור, כפל וחילוק דרך עולמות של הרפתקה.',
      'shape_safari': 'מצאו צורות, ספרו צלעות והשלימו תבניות.',
      'word_wizard': 'הטילו לחשי איות ואוצר מילים.',
      'clock_hero': 'קראו את השעון וגלו מה השעה.',
      'money_math': 'ספרו מטבעות, הרכיבו סכומים והשוו כסף.',
      'memory_match': 'הפכו קלפים ומצאו את הזוגות התואמים.',
    },

    // ---- achievement.dart (name + description) ----
    'ach.name': {
      'first_game': 'צעדים ראשונים',
      'perfect_round': 'ללא רבב',
      'streak_5': 'על האש',
      'coin_200': 'אספן מטבעות',
      'coin_500': 'צייד אוצרות',
      'avatar_collector': 'התחפושת',
      'coin_1000': 'אלוף המטבעות',
      'avatar_wardrobe': 'אשף אופנה',
      'speedster': 'מהיר כברק',
      'three_star': 'כוח הכוכבים',
      'hub_explorer': 'חוקר',
      'streak_3_days': 'שחקן יומי',
      'streak_7_days': 'לוחם השבוע',
      'missions_done': 'אשף המשימות',
      'pet_level5': 'חבר של החיה',
      'pet_level10': 'מומחה חיות',
      'nq_boss': 'מנצח הבוסים',
      'nq_mult': 'אלוף הכפל',
      'nq_level5': 'כוכב עולה',
      'ss_guardian': 'חבר של בעלי חיים',
      'ss_explorer': 'פורץ דרך',
      'ww_master': 'אשף האיות',
      'ch_keeper': 'שומר הזמן',
      'mm_master': 'אלוף הכסף',
      'mem_master': 'אלוף הזיכרון',
    },
    'ach.desc': {
      'first_game': 'סיימו את הסיבוב הראשון שלכם.',
      'perfect_round': 'ענו נכון על כל השאלות בסיבוב.',
      'streak_5': 'ענו נכון 5 פעמים ברצף.',
      'coin_200': 'אספו 200 מטבעות בסך הכול.',
      'coin_500': 'אספו 500 מטבעות בסך הכול.',
      'avatar_collector': 'החזיקו 3 דמויות שונות.',
      'coin_1000': 'אספו 1000 מטבעות בסך הכול.',
      'avatar_wardrobe': 'החזיקו 6 דמויות שונות.',
      'speedster': 'קבעו שיא זמן באחד המשחקים.',
      'three_star': 'קבלו 3 כוכבים בסיבוב.',
      'hub_explorer': 'שחקו בכל משחק לפחות פעם אחת.',
      'streak_3_days': 'שחקו 3 ימים ברצף.',
      'streak_7_days': 'שחקו 7 ימים ברצף.',
      'missions_done': 'סיימו את כל המשימות של היום.',
      'pet_level5': 'גדלו את החיה לדרגה 5.',
      'pet_level10': 'גדלו את החיה לדרגה 10.',
      'nq_boss': 'נצחו בוס במסע המספרים.',
      'nq_mult': 'ענו נכון על 50 שאלות כפל.',
      'nq_level5': 'הגיעו לדרגת גיבור 5 במסע המספרים.',
      'ss_guardian': 'התיידדו עם שומר בספארי הצורות.',
      'ss_explorer': 'סיימו שביל שלם בספארי הצורות.',
      'ww_master': 'השיגו סיבוב מושלם בקוסם המילים.',
      'ch_keeper': 'השיגו סיבוב מושלם בגיבור השעון.',
      'mm_master': 'השיגו סיבוב מושלם בחשבון הכסף.',
      'mem_master': 'השיגו סיבוב מושלם במשחק הזיכרון.',
    },

    // ---- mission.dart (title) ----
    'mission.title': {
      'answer_15': 'ענו נכון על 15 שאלות',
      'answer_30': 'ענו נכון על 30 שאלות',
      'finish_3': 'סיימו 3 שלבים',
      'coins_60': 'הרוויחו 60 מטבעות',
      'three_star_2': 'קבלו 3 כוכבים פעמיים',
      'boss_1': 'נצחו בוס',
    },

    // ---- avatar.dart (names) ----
    'avatar.name': {
      'ranger': 'חבר',
      'wizard': 'קוסם',
      'robot': 'רובי',
      'ninja': 'נינג׳ה',
      'unicorn': 'נצנוץ',
      'dragon': 'דראקו',
      'astronaut': 'אסטרו',
      'fox': 'שועלון',
      'panda': 'במבוק',
      'owl': 'ינשופון',
      'frog': 'קפצן',
      'cat': 'שפמון',
      'penguin': 'ברווזון',
      'monkey': 'קוקו',
      'superhero': 'קפטן מוח',
      'phoenix_pal': 'להבה',
      'crown': 'מלכותי',
      'star_master': 'סופרנובה',
      'nq_hero': 'סר כוכבים',
      'ss_hero': 'פורץ דרך',
      'ww_hero': 'אשף הכישוף',
      'ch_hero': 'שומר הזמן',
      'mm_hero': 'קפטן המטבע',
      'mem_hero': 'אדון המחשבה',
      'grand_champion': 'אלוף העל',
      'golden_hero': 'אלוף',
    },
    // ---- avatar.dart (unlock requirement labels) ----
    'avatar.unlock': {
      'superhero': 'שחקו בכל משחק פעם אחת',
      'phoenix_pal': 'גדלו את החיה לדרגה 10',
      'crown': 'שחקו 7 ימים ברצף',
      'star_master': 'החזיקו 6 דמויות',
      'nq_hero': 'נצחו את הבוס של מסע המספרים',
      'ss_hero': 'התיידדו עם שומר בספארי הצורות',
      'ww_hero': 'סיבוב מושלם בקוסם המילים',
      'ch_hero': 'סיבוב מושלם בגיבור השעון',
      'mm_hero': 'סיבוב מושלם בחשבון הכסף',
      'mem_hero': 'סיבוב מושלם במשחק הזיכרון',
      'grand_champion': 'שלטו בכל 6 המשחקים',
    },

    // ---- pet.dart (stage names) ----
    'pet.stage': {
      'Egg': 'ביצה',
      'Hatchling': 'בוקע',
      'Chick': 'אפרוח',
      'Birdie': 'ציפורון',
      'Owl': 'ינשוף',
      'Phoenix': 'עוף החול',
      'Dragon': 'דרקון',
    },

    // ---- number_quest difficulty.dart ----
    'nq.difficulty.label': {
      'easy': 'קל',
      'intermediate': 'בינוני',
      'expert': 'מומחה',
    },
    'nq.difficulty.subtitle': {
      'easy': 'כיתה א׳ - חיבור וחיסור של מספרים קטנים',
      'intermediate': 'כיתה ב׳ - סכומים גדולים יותר ולוח הכפל',
      'expert': 'כיתה ג׳ - כפל, חילוק ומסעות מעורבים',
    },
    // ---- number_quest skill.dart ----
    'nq.skill.label': {
      'addition': 'חיבור',
      'subtraction': 'חיסור',
      'multiplication': 'כפל',
      'division': 'חילוק',
    },
    // ---- number_quest boss names ----
    'nq.boss.name': {
      'easy': 'גולפאף',
      'intermediate': 'אוקטו',
      'expert': 'דראקו',
      // Times Tables campaign guardian ("Times Guardian").
      'times': 'שומר הכפל',
    },
    // ---- number_quest Times Tables campaign ----
    'nq.times.label': {
      'times': 'לוח הכפל',
    },
    'nq.times.subtitle': {
      'times': 'בנו את לוח הכפל עם נקודות, מ-1 עד 12.',
    },

    // ---- shape_safari habitat.dart ----
    'ss.habitat.label': {
      'jungle': 'ג׳ונגל',
      'desert': 'מדבר',
      'mountain': 'הר',
    },
    'ss.habitat.subtitle': {
      'jungle': 'הכירו את הצורות הבסיסיות בין הגפנים.',
      'desert': 'צורות חדשות מופיעות על החולות.',
      'mountain': 'כל הצורות, והתבניות המאתגרות ביותר.',
    },
    // ---- shape_safari guardian names ----
    'ss.guardian.name': {
      'jungle': 'ליאו האריה',
      'desert': 'קאמי הגמל',
      'mountain': 'רוקי הנשר',
    },

    // ---- clock_hero time_world.dart ----
    'ch.world.label': {
      'morning': 'בוקר',
      'afternoon': 'צהריים',
      'night': 'לילה',
    },
    'ch.world.subtitle': {
      'morning': 'שעות עגולות לקום בבוקר.',
      'afternoon': 'חצי שעה ורבע שעה.',
      'night': 'שעות של חמש דקות ושעונים מאתגרים.',
    },
    // ---- clock_hero guardian names ----
    'ch.guardian.name': {
      'morning': 'תרנגול אדום',
      'afternoon': 'חתול שמש',
      'night': 'לונה הינשוף',
    },

    // ---- money_math money_level.dart ----
    'mm.world.label': {
      'piggy': 'קופת חזיר',
      'wallet': 'ארנק',
      'vault': 'כספת',
    },
    'mm.world.subtitle': {
      'piggy': 'ספרו קבוצות קטנות של מטבעות.',
      'wallet': 'הרכיבו סכומים והשוו כסף.',
      'vault': 'סכומים גדולים יותר ועודף.',
    },
    // ---- money_math guardian names ----
    'mm.guardian.name': {
      'piggy': 'חזרזיר פרוטה',
      'wallet': 'שפן שקל',
      'vault': 'שועל זהב',
    },

    // ---- memory_match memory_level.dart ----
    'mem.world.label': {
      'animals': 'חיות',
      'fruits': 'פירות',
      'space': 'חלל',
    },
    'mem.world.subtitle': {
      'animals': 'התאימו את החיות החמודות.',
      'fruits': 'הזוגו פירות טעימים.',
      'space': 'מצאו זוגות חלל תואמים.',
    },
    // ---- memory_match guardian names ----
    'mem.guardian.name': {
      'animals': 'אלי הפיל',
      'fruits': 'קפטן מלון',
      'space': 'מלך השביט',
    },

    // ---- word_wizard wizard_level.dart (chapter labels) ----
    'ww.chapter.label': {
      'sprout': 'נבט',
      'spark': 'ניצוץ',
      'storm': 'סערה',
    },
    'ww.chapter.subtitle': {
      'sprout': 'לחשים קצרים ופשוטים להתחלה.',
      'spark': 'מילים ארוכות יותר ואותיות מאתגרות.',
      'storm': 'המילים והאיות הקשים ביותר.',
    },
    // ---- word_wizard spell-boss names ----
    'ww.boss.name': {
      'sprout': 'ינשופרט',
      'spark': 'שועלהב',
      'storm': 'הקוסם הגדול',
    },
  };
}
