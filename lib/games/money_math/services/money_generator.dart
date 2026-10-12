import 'dart:math';

import '../../../core/l10n/app_lang.dart';
import '../models/money_level.dart';
import '../models/money_question.dart';

/// Generates Money Math questions. [difficulty] 0..1 controls the coin set and
/// pile sizes, and unlocks harder question types.
///
/// [lang] selects the currency and prompt language: English => US cents (¢),
/// Hebrew => Israeli shekel/agorot (₪). It is passed in explicitly because the
/// generator is static/stateless (the screen resolves it via `L10n.read` in
/// `initState`, matching the Word Wizard pattern). English is byte-identical to
/// the original behavior.
class MoneyQuestionGenerator {
  MoneyQuestionGenerator({Random? random, this.lang = AppLang.en})
      : _rng = random ?? Random();

  final Random _rng;
  final AppLang lang;

  /// The currency chosen by the current language.
  Currency get currency => lang == AppLang.he ? Currency.ils : Currency.usd;

  static List<MoneyQuestion> forLevel(
    MoneyLevel level, {
    Random? random,
    AppLang lang = AppLang.en,
  }) {
    final gen = MoneyQuestionGenerator(random: random, lang: lang);
    return gen.generateRound(
      level.questionCount,
      difficulty: level.difficulty(MoneyMap.levelsPerTrail),
      world: level.world,
    );
  }

  /// The coins available at a difficulty (bigger coins unlock as it rises).
  /// US keeps its exact original tiers; ILS mirrors the same 3-tier ramp over
  /// its six denominations (10a/½₪/₪1/₪2/₪5/₪10).
  List<Coin> _coinSet(double d) {
    if (currency == Currency.ils) {
      if (d < 0.34) return const [Coin.agora10, Coin.halfShekel, Coin.shekel1];
      if (d < 0.67) {
        return const [
          Coin.agora10,
          Coin.halfShekel,
          Coin.shekel1,
          Coin.shekel2,
        ];
      }
      return Coin.ilsAll;
    }
    if (d < 0.34) return const [Coin.penny, Coin.nickel];
    if (d < 0.67) return const [Coin.penny, Coin.nickel, Coin.dime];
    return Coin.usdAll;
  }

  int _pileSize(double d) {
    if (d < 0.34) return 2 + _rng.nextInt(2); // 2..3
    if (d < 0.67) return 3 + _rng.nextInt(2); // 3..4
    return 3 + _rng.nextInt(3); // 3..5
  }

  CoinPile _randomPile(double d, {int? size}) {
    final coins = _coinSet(d);
    final n = size ?? _pileSize(d);
    return CoinPile(List.generate(n, (_) => coins[_rng.nextInt(coins.length)]));
  }

  String _signature(MoneyQuestion q) {
    final a = q.pile?.total ?? q.pileA?.total ?? 0;
    final b = q.pileB?.total ?? 0;
    return '${q.type}|${q.prompt}|$a|$b';
  }

  List<MoneyQuestion> generateRound(
    int count, {
    double difficulty = 0.3,
    MoneyWorld world = MoneyWorld.piggy,
  }) {
    final questions = <MoneyQuestion>[];
    final seen = <String>{};
    for (var i = 0; i < count; i++) {
      final dd = (difficulty + i / (count * 2)).clamp(0.0, 1.0);
      MoneyQuestion q;
      var guard = 0;
      do {
        q = generateOne(dd, world: world);
        guard++;
      } while (seen.contains(_signature(q)) && guard < 25);
      seen.add(_signature(q));
      questions.add(q);
    }
    return questions;
  }

  MoneyQuestion generateOne(double d, {MoneyWorld world = MoneyWorld.piggy}) {
    final types = <MoneyQuestionType>[
      MoneyQuestionType.countCoins,
      if (d >= 0.3) MoneyQuestionType.whichMore,
      if (d >= 0.5) MoneyQuestionType.makeAmount,
      if (world == MoneyWorld.vault) MoneyQuestionType.makeChange,
    ];
    final type = types[_rng.nextInt(types.length)];
    switch (type) {
      case MoneyQuestionType.countCoins:
        return _countCoins(d);
      case MoneyQuestionType.whichMore:
        return _whichMore(d);
      case MoneyQuestionType.makeAmount:
        return _makeAmount(d);
      case MoneyQuestionType.makeChange:
        return _makeChange(d);
    }
  }

  bool get _he => lang == AppLang.he;

  String _fmt(int cents) => currency.format(cents);

  /// The smallest coin value of the current currency, used as the step for the
  /// make-change amounts so the result is always representable in coins.
  int get _smallestCoin =>
      currency == Currency.ils ? Coin.agora10.cents : Coin.penny.cents;

  /// The make-change step: multiples of 5¢ for US (kid-friendly mental math) or
  /// multiples of 10 agorot for ILS (its smallest coin).
  int get _changeStep => currency == Currency.ils ? 10 : 5;

  // Show a pile; pick its total value.
  MoneyQuestion _countCoins(double d) {
    final pile = _randomPile(d);
    final answer = pile.total;
    final options = _distinctAmounts(answer, 4, d);
    return MoneyQuestion(
      type: MoneyQuestionType.countCoins,
      prompt: _he ? 'כמה כסף יש כאן?' : 'How much money is this?',
      pile: pile,
      textChoices: options.map(_fmt).toList(),
      correctIndex: options.indexOf(answer),
    );
  }

  // Two piles; pick which is worth more.
  MoneyQuestion _whichMore(double d) {
    var a = _randomPile(d);
    var b = _randomPile(d);
    var guard = 0;
    while (a.total == b.total && guard < 20) {
      b = _randomPile(d);
      guard++;
    }
    if (a.total == b.total) {
      b = CoinPile([...b.coins, _coinSet(d).first]);
    }
    final aMore = a.total > b.total;
    return MoneyQuestion(
      type: MoneyQuestionType.whichMore,
      prompt: _he ? 'איפה יש יותר כסף?' : 'Which one is more money?',
      pileA: a,
      pileB: b,
      correctIndex: aMore ? 0 : 1,
    );
  }

  // Target amount; pick the pile that makes it.
  MoneyQuestion _makeAmount(double d) {
    final target = _randomPile(d);
    final answerPile = target;
    final piles = <CoinPile>[answerPile];
    var guard = 0;
    while (piles.length < 4 && guard < 40) {
      guard++;
      final other = _randomPile(d);
      if (!piles.any((p) => p.total == other.total)) piles.add(other);
    }
    while (piles.length < 4) {
      piles.add(CoinPile([...answerPile.coins, _coinSet(d).first]));
    }
    piles.shuffle(_rng);
    final amount = _fmt(target.total);
    return MoneyQuestion(
      type: MoneyQuestionType.makeAmount,
      prompt: _he ? 'אילו מטבעות שווים $amount?' : 'Which coins make $amount?',
      pileChoices: piles,
      correctIndex: piles.indexWhere((p) => p.total == target.total),
    );
  }

  // You pay more than a price; pick the change owed (shown as text amounts).
  MoneyQuestion _makeChange(double d) {
    // Difficulty-scaled whole amounts in steps of the currency's smallest coin
    // (5¢ for US, 10 agorot for ILS), so change is always coin-representable
    // and strictly positive.
    final step = _changeStep;
    final maxUnit = 4 + (d * 16).round(); // 4..20 steps
    final priceUnits = 1 + _rng.nextInt(maxUnit);
    final price = priceUnits * step;
    // Payment is at least price + one step so change is always positive.
    final extraUnits = 1 + _rng.nextInt(maxUnit);
    final pay = price + extraUnits * step;
    final answer = pay - price; // > 0 by construction
    final options = _distinctAmounts(answer, 4, d);
    final payStr = _fmt(pay);
    final priceStr = _fmt(price);
    return MoneyQuestion(
      type: MoneyQuestionType.makeChange,
      prompt: _he
          ? 'שילמתם $payStr על צעצוע ב-$priceStr. כמה עודף?'
          : 'You pay $payStr for a $priceStr toy. How much change?',
      textChoices: options.map(_fmt).toList(),
      correctIndex: options.indexOf(answer),
    );
  }

  List<int> _distinctAmounts(int answer, int count, double d) {
    // Distractors are offset in multiples of the smallest coin so every shown
    // amount is a sensible, representable value in the current currency.
    final unit = _smallestCoin;
    final set = <int>{answer};
    var guard = 0;
    while (set.length < count && guard < 60) {
      guard++;
      final spread = 2 + (answer / unit * 0.4).round();
      var deltaUnits = _rng.nextInt(spread * 2 + 1) - spread;
      if (deltaUnits == 0) deltaUnits = _rng.nextBool() ? 1 : -1;
      final cand = answer + deltaUnits * unit;
      if (cand > 0) set.add(cand);
    }
    var filler = answer + unit;
    while (set.length < count) {
      set.add(filler);
      filler += unit;
    }
    return set.toList()..shuffle(_rng);
  }
}
