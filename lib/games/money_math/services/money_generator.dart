import 'dart:math';

import '../models/money_level.dart';
import '../models/money_question.dart';

/// Generates Money Math questions. [difficulty] 0..1 controls the coin set and
/// pile sizes, and unlocks harder question types.
class MoneyQuestionGenerator {
  MoneyQuestionGenerator({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  static List<MoneyQuestion> forLevel(MoneyLevel level, {Random? random}) {
    final gen = MoneyQuestionGenerator(random: random);
    return gen.generateRound(
      level.questionCount,
      difficulty: level.difficulty(MoneyMap.levelsPerTrail),
    );
  }

  /// The coins available at a difficulty (bigger coins unlock as it rises).
  List<Coin> _coinSet(double d) {
    if (d < 0.34) return const [Coin.penny, Coin.nickel];
    if (d < 0.67) return const [Coin.penny, Coin.nickel, Coin.dime];
    return Coin.all;
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

  List<MoneyQuestion> generateRound(int count, {double difficulty = 0.3}) {
    final questions = <MoneyQuestion>[];
    final seen = <String>{};
    for (var i = 0; i < count; i++) {
      final dd = (difficulty + i / (count * 2)).clamp(0.0, 1.0);
      MoneyQuestion q;
      var guard = 0;
      do {
        q = generateOne(dd);
        guard++;
      } while (seen.contains(_signature(q)) && guard < 25);
      seen.add(_signature(q));
      questions.add(q);
    }
    return questions;
  }

  MoneyQuestion generateOne(double d) {
    final types = <MoneyQuestionType>[
      MoneyQuestionType.countCoins,
      if (d >= 0.3) MoneyQuestionType.whichMore,
      if (d >= 0.5) MoneyQuestionType.makeAmount,
    ];
    final type = types[_rng.nextInt(types.length)];
    switch (type) {
      case MoneyQuestionType.countCoins:
        return _countCoins(d);
      case MoneyQuestionType.whichMore:
        return _whichMore(d);
      case MoneyQuestionType.makeAmount:
        return _makeAmount(d);
    }
  }

  String _fmt(int cents) => '$cents¢';

  // Show a pile; pick its total value.
  MoneyQuestion _countCoins(double d) {
    final pile = _randomPile(d);
    final answer = pile.total;
    final options = _distinctAmounts(answer, 4, d);
    return MoneyQuestion(
      type: MoneyQuestionType.countCoins,
      prompt: 'How much money is this?',
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
    if (a.total == b.total) b = CoinPile([...b.coins, Coin.penny]);
    final aMore = a.total > b.total;
    return MoneyQuestion(
      type: MoneyQuestionType.whichMore,
      prompt: 'Which one is more money?',
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
      piles.add(CoinPile([...answerPile.coins, Coin.penny]));
    }
    piles.shuffle(_rng);
    return MoneyQuestion(
      type: MoneyQuestionType.makeAmount,
      prompt: 'Which coins make ${_fmt(target.total)}?',
      pileChoices: piles,
      correctIndex: piles.indexWhere((p) => p.total == target.total),
    );
  }

  List<int> _distinctAmounts(int answer, int count, double d) {
    final set = <int>{answer};
    var guard = 0;
    while (set.length < count && guard < 60) {
      guard++;
      final spread = 2 + (answer * 0.4).round();
      var delta = _rng.nextInt(spread * 2 + 1) - spread;
      if (delta == 0) delta = _rng.nextBool() ? 1 : -1;
      final cand = answer + delta;
      if (cand > 0) set.add(cand);
    }
    var filler = answer + 1;
    while (set.length < count) {
      set.add(filler);
      filler++;
    }
    return set.toList()..shuffle(_rng);
  }
}
