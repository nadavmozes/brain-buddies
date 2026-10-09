/// A coin denomination shown with an emoji and its value in cents.
class Coin {
  const Coin(this.cents, this.emoji, this.label);
  final int cents;
  final String emoji;
  final String label;

  static const penny = Coin(1, '🟤', '1¢');
  static const nickel = Coin(5, '⚪', '5¢');
  static const dime = Coin(10, '🔵', '10¢');
  static const quarter = Coin(25, '🟡', '25¢');

  static const all = [penny, nickel, dime, quarter];
}

/// The kinds of Money Math questions.
enum MoneyQuestionType {
  /// A pile of coins is shown; pick the total value.
  countCoins,

  /// Two coin piles are shown; pick which is worth more.
  whichMore,

  /// A target amount is given; pick the coin pile that makes it.
  makeAmount,
}

/// A pile of coins (a multiset of denominations) with helpers.
class CoinPile {
  CoinPile(this.coins);
  final List<Coin> coins;

  int get total => coins.fold(0, (sum, c) => sum + c.cents);

  /// A compact emoji string of the coins, e.g. "🟡🔵🟤".
  String get emojiRow => coins.map((c) => c.emoji).join(' ');
}

/// A built Money Math question.
/// - [countCoins]: [pile] shown, [textChoices] are amounts.
/// - [whichMore]: [pileA]/[pileB] shown as two options.
/// - [makeAmount]: [prompt] gives a target, [pileChoices] are options.
class MoneyQuestion {
  MoneyQuestion({
    required this.type,
    required this.prompt,
    required this.correctIndex,
    this.pile,
    this.textChoices,
    this.pileA,
    this.pileB,
    this.pileChoices,
  });

  final MoneyQuestionType type;
  final String prompt;
  final int correctIndex;

  final CoinPile? pile;
  final List<String>? textChoices;
  final CoinPile? pileA;
  final CoinPile? pileB;
  final List<CoinPile>? pileChoices;
}
