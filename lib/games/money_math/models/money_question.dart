import 'package:flutter/material.dart';

/// The two currencies Money Math can teach, chosen by the current language:
/// US dollars/cents (English) and Israeli shekel/agorot (Hebrew).
///
/// All values are kept in the smallest integer unit so the existing cents-based
/// math (totals, [CoinPile.total], make-change) generalizes unchanged:
/// - [Currency.usd]: 1 unit = 1 cent (¢), 100 units = $1.
/// - [Currency.ils]: 1 unit = 1 agora, 100 units = ₪1.
enum Currency {
  usd,
  ils;

  /// The coins available for this currency, smallest to largest.
  List<Coin> get coins =>
      this == Currency.ils ? Coin.ilsAll : Coin.usdAll;

  /// How many smallest units make one whole currency unit (dollar / shekel).
  int get unit => 100;

  /// Formats an amount (in smallest units) for display to a kid.
  ///
  /// USD keeps the original behavior exactly: sub-dollar amounts read as
  /// `"45¢"`, whole/large amounts as `"$1"` / `"$1.25"`.
  ///
  /// ILS reads sub-shekel amounts as `"10 אג׳"` (agorot) and shekel amounts as
  /// `"₪1"` or, when there are leftover agorot, `"₪2.50"`. Kept simple and
  /// left-to-right so the numerals read naturally inside Hebrew (RTL) screens.
  String format(int amount) {
    if (this == Currency.ils) {
      if (amount < unit) return '$amount אג׳';
      if (amount % unit == 0) return '₪${amount ~/ unit}';
      final shekels = amount ~/ unit;
      final agorot = amount % unit;
      // Two-digit agorot after the point, e.g. ₪2.50.
      return '₪$shekels.${agorot.toString().padLeft(2, '0')}';
    }
    // USD — byte-identical to the original '$cents¢' behavior.
    return '$amount¢';
  }
}

/// A coin denomination. [cents] is the value in the currency's smallest unit
/// (US cents or ILS agorot). [emoji] stays for backward compatibility; coins
/// are now drawn as a [chipLabel]-bearing minted chip (see CoinChip).
class Coin {
  const Coin(this.cents, this.emoji, this.label,
      {this.currency = Currency.usd, this.chipLabel = '', this.color});

  final int cents;
  final String emoji;
  final String label;
  final Currency currency;

  /// Short label printed on the minted coin chip (e.g. "5¢", "10", "₪1").
  final String chipLabel;

  /// Optional coin-metal color for the chip; a sensible default is used when
  /// null (see CoinChip).
  final Color? color;

  // ---- US set (unchanged values; drawn as chips now) ----
  static const penny =
      Coin(1, '🟤', '1¢', chipLabel: '1¢', color: Color(0xFFB87333));
  static const nickel =
      Coin(5, '⚪', '5¢', chipLabel: '5¢', color: Color(0xFFBFC1C2));
  static const dime =
      Coin(10, '🔵', '10¢', chipLabel: '10¢', color: Color(0xFF9AA0A6));
  static const quarter =
      Coin(25, '🟡', '25¢', chipLabel: '25¢', color: Color(0xFFD9D9D9));

  static const usdAll = [penny, nickel, dime, quarter];

  // ---- Israeli (ILS) set: 10a, ½₪ (50a), ₪1, ₪2, ₪5, ₪10 ----
  // Values in agorot (₪1 = 100 agorot). Israel's smallest circulating coin is
  // 10 agorot; there is no 1-agora coin.
  // The chip prints "10א" (10 + an agora mark) so it never reads as ₪10.
  static const agora10 = Coin(10, '🟤', '10 אג׳',
      currency: Currency.ils, chipLabel: '10א', color: Color(0xFFB87333));
  static const halfShekel = Coin(50, '⚪', 'חצי שקל',
      currency: Currency.ils, chipLabel: '½₪', color: Color(0xFFBFC1C2));
  static const shekel1 = Coin(100, '⚪', '₪1',
      currency: Currency.ils, chipLabel: '₪1', color: Color(0xFFCFD2D4));
  static const shekel2 = Coin(200, '🟡', '₪2',
      currency: Currency.ils, chipLabel: '₪2', color: Color(0xFFD9C27E));
  static const shekel5 = Coin(500, '🟡', '₪5',
      currency: Currency.ils, chipLabel: '₪5', color: Color(0xFFE0CB8A));
  static const shekel10 = Coin(1000, '🟡', '₪10',
      currency: Currency.ils, chipLabel: '₪10', color: Color(0xFFE9D79B));

  static const ilsAll = [
    agora10,
    halfShekel,
    shekel1,
    shekel2,
    shekel5,
    shekel10,
  ];

  static List<Coin> forCurrency(Currency c) =>
      c == Currency.ils ? ilsAll : usdAll;
}

/// The kinds of Money Math questions.
enum MoneyQuestionType {
  /// A pile of coins is shown; pick the total value.
  countCoins,

  /// Two coin piles are shown; pick which is worth more.
  whichMore,

  /// A target amount is given; pick the coin pile that makes it.
  makeAmount,

  /// A price is paid with a bigger amount; pick the change owed (text choices).
  makeChange,
}

/// A pile of coins (a multiset of denominations) with helpers.
class CoinPile {
  CoinPile(this.coins);
  final List<Coin> coins;

  int get total => coins.fold(0, (sum, c) => sum + c.cents);

  /// A compact emoji string of the coins, e.g. "🟡🔵🟤".
  /// Retained for backward compatibility; the UI now renders [coins] as chips.
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
