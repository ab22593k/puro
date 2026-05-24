extension NumExtensions on num {
  static final _triplePattern = RegExp(r'...');
  static final _prefixCommaPattern = RegExp('^,');
  static final _trailingDotPattern = RegExp(r'\.$');

  /// Returns a custom pretty formatted number with an optional precision.
  ///
  /// For example:
  ///
  /// ```dart
  /// 1234.567.pretty() => '1,234.567'
  /// 123456.pretty()   => '123,456'
  /// ```
  String pretty({
    int? precision,
    bool minusSign = true,
    bool plusSign = false,
  }) {
    switch (this) {
      case == double.infinity:
        return plusSign ? '+∞' : '∞';
      case == double.negativeInfinity:
        return minusSign ? '-∞' : '∞';
      case _ when identical(this, double.nan):
        return 'NaN';
      default:
        break;
    }
    final nnn = abs().toString();
    var nnnIter = nnn.split('').skipWhile((c) => c != '.').skip(1);
    if (precision != null) {
      nnnIter = nnnIter.take(precision);
    }
    final ndn = abs().floor().toString();
    var o = ndn
        .split('')
        .reversed
        .join()
        .replaceAllMapped(_triplePattern, (m) => '${m.group(0)!},')
        .split('')
        .reversed
        .join()
        .replaceFirst(_prefixCommaPattern, '');
    if (precision != null || nnnIter.isNotEmpty) {
      o += '.${nnnIter.join().padRight(precision ?? 0, '0')}';
    }
    if (minusSign && this < 0) {
      o = '-$o';
    } else if (plusSign && this > 0) {
      o = '+$o';
    }
    if (o.contains('.')) {
      o = o.replaceAll(_trailingDotPattern, '');
    }
    return o;
  }

  /// Returns a pretty formatted percentage with an optional precision.
  ///
  /// For example:
  ///
  /// ```dart
  /// 0.56.prettyPercent(precision: 1) => '56%'
  /// 1.111.prettyPercent(precision: 1) => '111.1%'
  /// ```
  String prettyPercent({
    int? precision,
    bool minusSign = true,
    bool plusSign = true,
  }) {
    precision ??= abs() > 0 && abs() < 1 ? 2 : 0;
    return '${(this * 100).pretty(precision: precision, minusSign: minusSign, plusSign: plusSign)}%';
  }

  /// Returns a short formatted number using abbreviations.
  ///
  /// For example:
  ///
  /// ```dart
  /// 1.prettyAbbr()          => '1'
  /// 12345678.prettyAbbr()   => '123M'
  /// 1234567891.prettyAbbr() => '1.2B'
  /// ```
  String prettyAbbr({
    bool? precision,
    bool minusSign = true,
    bool plusSign = false,
    bool metric = false,
  }) {
    return switch (this) {
      == double.infinity => plusSign ? '+∞' : '∞',
      == double.negativeInfinity => minusSign ? '-∞' : '∞',
      _ when identical(this, double.nan) => 'NaN',
      == 0 => pretty(precision: 0, plusSign: plusSign, minusSign: minusSign),
      < 1 => pretty(precision: 1, plusSign: plusSign, minusSign: minusSign),
      < 100 => pretty(precision: 0, plusSign: plusSign, minusSign: minusSign),
      < 5000 =>
        '${(this / 1000).pretty(precision: 1, plusSign: plusSign, minusSign: minusSign)}${metric ? 'k' : 'K'}',
      < 500000 =>
        '${(this / 1000).pretty(precision: 0, plusSign: plusSign, minusSign: minusSign)}${metric ? 'k' : 'K'}',
      < 5000000 =>
        '${(this / 1000000).pretty(precision: 1, plusSign: plusSign, minusSign: minusSign)}M',
      < 500000000 =>
        '${(this / 1000000).pretty(precision: 0, plusSign: plusSign, minusSign: minusSign)}M',
      < 5000000000 =>
        '${(this / 1000000000).pretty(precision: 1, plusSign: plusSign, minusSign: minusSign)}${metric ? 'G' : 'B'}',
      < 500000000000 =>
        '${(this / 1000000000).pretty(precision: 0, plusSign: plusSign, minusSign: minusSign)}${metric ? 'G' : 'B'}',
      < 5000000000000 =>
        '${(this / 1000000000000).pretty(precision: 1, plusSign: plusSign, minusSign: minusSign)}T',
      _ =>
        '${(this / 1000000000000).pretty(precision: 0, plusSign: plusSign, minusSign: minusSign)}T',
    };
  }
}

extension DurationExtensions on Duration {
  static const _mult = <String, double>{
    'millisecond': 0.001,
    'second': 1.0,
    'minute': 60.0,
    'hour': 3600.0,
    'day': 86400.0,
    'week': 604800.0,
    'month': 2629746.0,
    'year': 31556952.0,
  };

  String pretty({String before = 'before', bool abbr = false}) {
    if (before.isNotEmpty) before = ' $before';
    var s = inMicroseconds / 1000000;
    switch (s) {
      case == double.infinity:
        return 'never';
      case == double.negativeInfinity:
        return 'forever$before';
      case _ when identical(s, double.nan):
        return 'unknown';
    }

    var sr = '';
    if (s < 0) {
      sr = before;
      s = s.abs();
    }

    String c(String n, String a) {
      final t = (s / _mult[n]!).round();
      return '$t${abbr ? a : ' $n${t != 1 ? 's' : ''}'}';
    }

    final label = switch (s) {
      < 1 => c('millisecond', 'ms'),
      < 60 => c('second', 's'),
      < 3600 => c('minute', 'm'),
      < 86400 => c('hour', 'h'),
      < 604800 => c('day', 'd'),
      < 2629800 => c('week', 'w'),
      < 31556952 => c('month', 'mo'),
      _ => c('year', 'y'),
    };
    return '$label$sr';
  }
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> delimitate(T delimiter) {
    return expand((e) => [delimiter, e]).skip(1);
  }

  Iterable<R> mapWithIndex<R>(R Function(T e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}
