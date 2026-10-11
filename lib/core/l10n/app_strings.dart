/// User-facing "chrome" strings for BrainBuddies, in English and Hebrew.
///
/// This is the in-repo string table chosen over gen-l10n/ARB (see the design
/// doc §4.1): a plain abstract [AppStrings] with an [EnStrings] and [HeStrings]
/// implementation, resolved at runtime by the current `AppLang`.
///
/// English values MUST match the literals the app previously hard-coded so the
/// existing tests (which assert English strings) keep passing. When adding a
/// string, add it to the abstract class AND both implementations.
abstract class AppStrings {
  const AppStrings();

  // ---- Hub ----
  String get hubTagline; // "Pick a game and start learning!"
  String get madeWithAi; // "Made with AI 🤖"
  String get feedback; // "Feedback"
  String get daily; // "Daily"
  String get missions; // "Missions"
  String get buddy; // "Buddy"
  String get shop; // "Shop"
  String get awards; // "Awards"
  String comingSoonGame(String title); // "<title> is coming soon! 🚧"
  String get play; // "PLAY"
  String get soon; // "SOON"

  // ---- Shop / avatars ----
  String get avatarShop; // "Avatar Shop"
  String get chooseYourAvatar; // "Choose your avatar"
  String get getMore; // "Get more"
  String get done; // "Done"
  String get comingSoon; // "Coming Soon"
  String get equipped; // "Equipped ✓"
  String get equip; // "Equip"
  String get claimGift; // "CLAIM 🎁"
  String lockedRequirement(String label); // "🔒 <label>"
  String unlockedAvatar(String name); // "Unlocked <name>! 🎉"
  String get notEnoughCoins; // "Not enough coins yet!"
  String coinCost(int cost); // "🪙 <cost>"
  String claimCost(int cost); // "🔓 🪙<cost>"

  // ---- Common game chrome ----
  String get allGames; // "All Games"
  String trailTitle(String emoji, String label); // "<emoji> <label> Trail"
  String trailLabel(String label); // "<label> Trail" (no emoji)
  String deckLabel(String label); // "<label> Deck"
  String worldLabel(String label); // "<label> World" (no emoji)
  String get chooseYourWorld; // "Choose Your World"
  String get dailyChallenge; // "Daily Challenge"
  String get progress; // "Progress"
  String get howToPlayBody; // the NQ how-to body
  String worldTitle(String emoji, String label); // "<emoji> <label> World"
  String chapterTitle(String emoji, String label); // "<emoji> <label> Chapter"
  String chapterLabel(String label); // "<label> Chapter" (no emoji)
  String get bossUpper; // "BOSS"
  String get spellMaster; // "Spell Master"
  String lessonN(int n); // "Lesson <n>"
  String get playUpper; // "PLAY" (reused)
  String get back; // "Back"
  String get backToMap; // "Back to Map"
  String get backToTrail; // "Back to Trail"
  String get nextLevel; // "Next Level"
  String get playAgain; // "Play Again"
  String get stop; // "Stop"
  String get howToPlay; // "How to Play"
  String get gotIt; // "Got it!"
  String get locked; // "Locked"
  String get level; // "Level"
  String levelN(int n); // "Level <n>"
  String get boss; // "Boss"
  String get guardian; // "Guardian"
  String stopN(int n); // "Stop <n>"
  String get youWin; // "You Win!"
  String get greatJob; // "Great job!"
  String questionProgress(int i, int n); // "<i> / <n>"
  String get time; // "Time"
  String get stars; // "Stars"
  String get coins; // "Coins"
  String get newRecord; // "New record!"
  String get correct; // "Correct!"
  String get tryAgain; // "Try again!"

  // ---- Settings / language ----
  String get settings; // "Settings"
  String get sound; // "Sound"
  String get soundAndHaptics; // "Sound & Haptics"
  String get language; // "Language"
  String get languageEnglish; // "English"
  String get languageHebrew; // "עברית"
  /// The short code shown on the toggle pill for the OTHER language — tap to
  /// switch. English UI shows "עב", Hebrew UI shows "EN".
  String get languageToggleLabel;

  // ---- Hub screens ----
  String get pickHabitat; // "Pick a habitat to explore!"
  String get pickWorld; // "Choose Your World" / "Pick a world"
  String get pickChapter; // "Pick a chapter"
  String get pickDeck; // "Pick a deck"
  String get pickTimeOfDay; // "Pick a time of day to explore!"
  String get pickPiggy; // "Pick a piggy bank to open!"
  String get achievements; // "Achievements"
  String earnedCount(int earned, int total); // "<e> / <t> earned"
  String get dailyMissions; // "Daily Missions"
  String get yourBuddy; // "Your Buddy"
  String dayStreak(int n); // "Day streak: <n>"
  String get todaysMissions; // "Today's Missions"
  String get newMissionsTomorrow; // "New missions arrive every day..."
  String get claimed; // "Claimed ✓"
  String claimReward(int coins); // "Claim 🪙 <coins>"
  String rewardCoins(int coins); // "🪙 <coins>"
  String coinsGained(int coins); // "+<coins> coins! 🪙"
  String get myBuddy; // "My Buddy"
  String get growth; // "Growth"
  String get growthStages; // "Growth Stages"
  String get fullyGrown; // "Your buddy is fully grown! 🎉"
  String reachStage(String name, String emoji, int level); // keep-playing hint
  String get buddyGrowsHint; // "Your buddy grows as you earn..."
  String levelAbbrev(int n); // "Lv <n>"

  // ---- Admin ----
  String get adminTitle; // "Admin / Dev Tools"
  String get resetEverything; // "Reset Everything"
}

/// English chrome strings. Values here MUST equal the previously hard-coded
/// literals so existing tests stay green.
class EnStrings extends AppStrings {
  const EnStrings();

  @override
  String get hubTagline => 'Pick a game and start learning!';
  @override
  String get madeWithAi => 'Made with AI 🤖';
  @override
  String get feedback => 'Feedback';
  @override
  String get daily => 'Daily';
  @override
  String get missions => 'Missions';
  @override
  String get buddy => 'Buddy';
  @override
  String get shop => 'Shop';
  @override
  String get awards => 'Awards';
  @override
  String comingSoonGame(String title) => '$title is coming soon! 🚧';
  @override
  String get play => 'PLAY';
  @override
  String get soon => 'SOON';

  @override
  String get avatarShop => 'Avatar Shop';
  @override
  String get chooseYourAvatar => 'Choose your avatar';
  @override
  String get getMore => 'Get more';
  @override
  String get done => 'Done';
  @override
  String get comingSoon => 'Coming Soon';
  @override
  String get equipped => 'Equipped ✓';
  @override
  String get equip => 'Equip';
  @override
  String get claimGift => 'CLAIM 🎁';
  @override
  String lockedRequirement(String label) => '🔒 $label';
  @override
  String unlockedAvatar(String name) => 'Unlocked $name! 🎉';
  @override
  String get notEnoughCoins => 'Not enough coins yet!';
  @override
  String coinCost(int cost) => '🪙 $cost';
  @override
  String claimCost(int cost) => '🔓 🪙$cost';

  @override
  String get allGames => 'All Games';
  @override
  String trailTitle(String emoji, String label) => '$emoji $label Trail';
  @override
  String trailLabel(String label) => '$label Trail';
  @override
  String deckLabel(String label) => '$label Deck';
  @override
  String worldLabel(String label) => '$label World';
  @override
  String get chooseYourWorld => 'Choose Your World';
  @override
  String get dailyChallenge => 'Daily Challenge';
  @override
  String get progress => 'Progress';
  @override
  String get howToPlayBody =>
      '1. Pick a world and follow the level path.\n\n'
      '2. Tap the right answer. Chain answers for a streak bonus!\n\n'
      '3. Earn coins and XP. Beat the boss at the end of each world.\n\n'
      '4. Spend coins in the hub Shop, collect awards, and play every day '
      'to grow your streak!';
  @override
  String worldTitle(String emoji, String label) => '$emoji $label World';
  @override
  String chapterTitle(String emoji, String label) => '$emoji $label Chapter';
  @override
  String chapterLabel(String label) => '$label Chapter';
  @override
  String get bossUpper => 'BOSS';
  @override
  String get spellMaster => 'Spell Master';
  @override
  String lessonN(int n) => 'Lesson $n';
  @override
  String get playUpper => 'PLAY';
  @override
  String get back => 'Back';
  @override
  String get backToMap => 'Back to Map';
  @override
  String get backToTrail => 'Back to Trail';
  @override
  String get nextLevel => 'Next Level';
  @override
  String get playAgain => 'Play Again';
  @override
  String get stop => 'Stop';
  @override
  String get howToPlay => 'How to Play';
  @override
  String get gotIt => 'Got it!';
  @override
  String get locked => 'Locked';
  @override
  String get level => 'Level';
  @override
  String levelN(int n) => 'Level $n';
  @override
  String get boss => 'Boss';
  @override
  String get guardian => 'Guardian';
  @override
  String stopN(int n) => 'Stop $n';
  @override
  String get youWin => 'You Win!';
  @override
  String get greatJob => 'Great job!';
  @override
  String questionProgress(int i, int n) => '$i / $n';
  @override
  String get time => 'Time';
  @override
  String get stars => 'Stars';
  @override
  String get coins => 'Coins';
  @override
  String get newRecord => 'New record!';
  @override
  String get correct => 'Correct!';
  @override
  String get tryAgain => 'Try again!';

  @override
  String get settings => 'Settings';
  @override
  String get sound => 'Sound';
  @override
  String get soundAndHaptics => 'Sound & Haptics';
  @override
  String get language => 'Language';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageHebrew => 'עברית';
  @override
  String get languageToggleLabel => 'עב';

  @override
  String get pickHabitat => 'Pick a habitat to explore!';
  @override
  String get pickWorld => 'Pick a world';
  @override
  String get pickChapter => 'Pick a chapter to cast spells!';
  @override
  String get pickDeck => 'Pick a deck and find the pairs!';
  @override
  String get pickTimeOfDay => 'Pick a time of day to explore!';
  @override
  String get pickPiggy => 'Pick a bank to start saving!';
  @override
  String get achievements => 'Achievements';
  @override
  String earnedCount(int earned, int total) => '$earned / $total earned';
  @override
  String get dailyMissions => 'Daily Missions';
  @override
  String get yourBuddy => 'Your Buddy';
  @override
  String dayStreak(int n) => 'Day streak: $n';
  @override
  String get todaysMissions => "Today's Missions";
  @override
  String get newMissionsTomorrow =>
      'New missions arrive every day. Come back tomorrow!';
  @override
  String get claimed => 'Claimed ✓';
  @override
  String claimReward(int coins) => 'Claim 🪙 $coins';
  @override
  String rewardCoins(int coins) => '🪙 $coins';
  @override
  String coinsGained(int coins) => '+$coins coins! 🪙';
  @override
  String get myBuddy => 'My Buddy';
  @override
  String get growth => 'Growth';
  @override
  String get growthStages => 'Growth Stages';
  @override
  String get fullyGrown => 'Your buddy is fully grown! 🎉';
  @override
  String reachStage(String name, String emoji, int level) =>
      'Keep playing to reach $name $emoji at level $level';
  @override
  String get buddyGrowsHint =>
      'Your buddy grows as you earn stars and coins in any game.';
  @override
  String levelAbbrev(int n) => 'Lv $n';

  @override
  String get adminTitle => 'Admin / Dev Tools';
  @override
  String get resetEverything => 'Reset Everything';
}

/// Hebrew chrome strings. Emoji are kept (language-neutral); numerals stay
/// Western Arabic digits. Phrasing is kid-friendly for grades 1-3.
class HeStrings extends AppStrings {
  const HeStrings();

  @override
  String get hubTagline => 'בחרו משחק ומתחילים ללמוד!';
  @override
  String get madeWithAi => 'נוצר עם AI 🤖';
  @override
  String get feedback => 'משוב';
  @override
  String get daily => 'יומי';
  @override
  String get missions => 'משימות';
  @override
  String get buddy => 'חבר';
  @override
  String get shop => 'חנות';
  @override
  String get awards => 'פרסים';
  @override
  String comingSoonGame(String title) => '$title יגיע בקרוב! 🚧';
  @override
  String get play => 'שחקו';
  @override
  String get soon => 'בקרוב';

  @override
  String get avatarShop => 'חנות דמויות';
  @override
  String get chooseYourAvatar => 'בחרו את הדמות שלכם';
  @override
  String get getMore => 'עוד דמויות';
  @override
  String get done => 'סיום';
  @override
  String get comingSoon => 'בקרוב';
  @override
  String get equipped => 'נבחר ✓';
  @override
  String get equip => 'בחירה';
  @override
  String get claimGift => 'קבלו 🎁';
  @override
  String lockedRequirement(String label) => '🔒 $label';
  @override
  String unlockedAvatar(String name) => 'פתחתם את $name! 🎉';
  @override
  String get notEnoughCoins => 'עדיין אין מספיק מטבעות!';
  @override
  String coinCost(int cost) => '🪙 $cost';
  @override
  String claimCost(int cost) => '🔓 🪙$cost';

  @override
  String get allGames => 'כל המשחקים';
  @override
  String trailTitle(String emoji, String label) => 'שביל $label $emoji';
  @override
  String trailLabel(String label) => 'שביל $label';
  @override
  String deckLabel(String label) => 'חפיסת $label';
  @override
  String worldLabel(String label) => 'עולם $label';
  @override
  String get chooseYourWorld => 'בחרו את העולם שלכם';
  @override
  String get dailyChallenge => 'אתגר יומי';
  @override
  String get progress => 'התקדמות';
  @override
  String get howToPlayBody =>
      '1. בחרו עולם ועקבו אחרי שביל השלבים.\n\n'
      '2. לחצו על התשובה הנכונה. שרשרו תשובות לבונוס רצף!\n\n'
      '3. צברו מטבעות ונקודות ניסיון. נצחו את הבוס בסוף כל עולם.\n\n'
      '4. בזבזו מטבעות בחנות, אספו פרסים ושחקו כל יום '
      'כדי להגדיל את הרצף שלכם!';
  @override
  String worldTitle(String emoji, String label) => 'עולם $label $emoji';
  @override
  String chapterTitle(String emoji, String label) => 'פרק $label $emoji';
  @override
  String chapterLabel(String label) => 'פרק $label';
  @override
  String get bossUpper => 'בוס';
  @override
  String get spellMaster => 'אשף הכישוף';
  @override
  String lessonN(int n) => 'שיעור $n';
  @override
  String get playUpper => 'שחקו';
  @override
  String get back => 'חזרה';
  @override
  String get backToMap => 'חזרה למפה';
  @override
  String get backToTrail => 'חזרה לשביל';
  @override
  String get nextLevel => 'השלב הבא';
  @override
  String get playAgain => 'שחקו שוב';
  @override
  String get stop => 'עצירה';
  @override
  String get howToPlay => 'איך משחקים';
  @override
  String get gotIt => 'הבנתי!';
  @override
  String get locked => 'נעול';
  @override
  String get level => 'שלב';
  @override
  String levelN(int n) => 'שלב $n';
  @override
  String get boss => 'בוס';
  @override
  String get guardian => 'שומר';
  @override
  String stopN(int n) => 'תחנה $n';
  @override
  String get youWin => 'ניצחתם!';
  @override
  String get greatJob => 'כל הכבוד!';
  @override
  String questionProgress(int i, int n) => '$i / $n';
  @override
  String get time => 'זמן';
  @override
  String get stars => 'כוכבים';
  @override
  String get coins => 'מטבעות';
  @override
  String get newRecord => 'שיא חדש!';
  @override
  String get correct => 'נכון!';
  @override
  String get tryAgain => 'נסו שוב!';

  @override
  String get settings => 'הגדרות';
  @override
  String get sound => 'צליל';
  @override
  String get soundAndHaptics => 'צליל ורטט';
  @override
  String get language => 'שפה';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageHebrew => 'עברית';
  @override
  String get languageToggleLabel => 'EN';

  @override
  String get pickHabitat => 'בחרו בית גידול לחקור!';
  @override
  String get pickWorld => 'בחרו עולם';
  @override
  String get pickChapter => 'בחרו פרק כדי להטיל לחשים!';
  @override
  String get pickDeck => 'בחרו חפיסה ומצאו את הזוגות!';
  @override
  String get pickTimeOfDay => 'בחרו שעה ביום לחקור!';
  @override
  String get pickPiggy => 'בחרו קופה כדי להתחיל לחסוך!';
  @override
  String get achievements => 'הישגים';
  @override
  String earnedCount(int earned, int total) => '$earned / $total הושגו';
  @override
  String get dailyMissions => 'משימות יומיות';
  @override
  String get yourBuddy => 'החבר שלך';
  @override
  String dayStreak(int n) => 'רצף ימים: $n';
  @override
  String get todaysMissions => 'המשימות של היום';
  @override
  String get newMissionsTomorrow => 'משימות חדשות מגיעות כל יום. חזרו מחר!';
  @override
  String get claimed => 'נאסף ✓';
  @override
  String claimReward(int coins) => 'קבלו 🪙 $coins';
  @override
  String rewardCoins(int coins) => '🪙 $coins';
  @override
  String coinsGained(int coins) => '+$coins מטבעות! 🪙';
  @override
  String get myBuddy => 'החבר שלי';
  @override
  String get growth => 'צמיחה';
  @override
  String get growthStages => 'שלבי צמיחה';
  @override
  String get fullyGrown => 'החבר שלך גדל במלואו! 🎉';
  @override
  String reachStage(String name, String emoji, int level) =>
      'המשיכו לשחק כדי להגיע ל$name $emoji בדרגה $level';
  @override
  String get buddyGrowsHint =>
      'החבר שלך גדל ככל שאתם צוברים כוכבים ומטבעות בכל משחק.';
  @override
  String levelAbbrev(int n) => 'דרגה $n';

  @override
  String get adminTitle => 'Admin / Dev Tools';
  @override
  String get resetEverything => 'Reset Everything';
}

/// Resolves the [AppStrings] implementation for a language code.
AppStrings stringsFor(bool isHebrew) =>
    isHebrew ? const HeStrings() : const EnStrings();
