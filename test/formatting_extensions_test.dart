import 'package:checks/checks.dart';
import 'package:puro/src/formatting_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('num.pretty', () {
    test('formats integer', () {
      check(1234.pretty()).equals('1,234');
    });

    test('formats decimal', () {
      check(1234.567.pretty()).equals('1,234.567');
    });

    test('formats with precision', () {
      check(1234.567.pretty(precision: 2)).equals('1,234.56');
    });

    test('handles zero', () {
      check(0.pretty()).equals('0');
    });

    test('handles negative numbers', () {
      check((-1234).pretty()).equals('-1,234');
    });

    test('handles minusSign false', () {
      check((-5).pretty(minusSign: false)).equals('5');
    });

    test('handles plusSign', () {
      check(5.pretty(plusSign: true)).equals('+5');
    });

    test('handles infinity', () {
      check(double.infinity.pretty()).equals('∞');
    });

    test('handles negative infinity', () {
      check(double.negativeInfinity.pretty()).equals('-∞');
    });

    test('handles NaN', () {
      check(double.nan.pretty()).equals('NaN');
    });
  });

  group('num.prettyPercent', () {
    test('formats 0.56 as 56% with default plusSign', () {
      check(0.56.prettyPercent()).equals('+56.00%');
    });

    test('formats 0.056 with precision', () {
      check(0.056.prettyPercent(precision: 1, plusSign: false)).equals('5.6%');
    });

    test('formats > 100%', () {
      check(1.5.prettyPercent(precision: 1, plusSign: false)).equals('150.0%');
    });
  });

  group('num.prettyAbbr', () {
    test('under 100 returns plain', () {
      check(42.prettyAbbr()).equals('42');
    });

    test('under 5000 with K', () {
      check(1234.prettyAbbr()).equals('1.2K');
    });

    test('under 500000 with K', () {
      check(12345.prettyAbbr()).equals('12K');
    });

    test('under 5000000 with M', () {
      check(1234567.prettyAbbr()).equals('1.2M');
    });

    test('handles zero', () {
      check(0.prettyAbbr()).equals('0');
    });

    test('handles infinity', () {
      check(double.infinity.prettyAbbr()).equals('∞');
    });

    test('handles NaN', () {
      check(double.nan.prettyAbbr()).equals('NaN');
    });
  });

  group('Duration.pretty', () {
    test('formats milliseconds', () {
      check(const Duration(milliseconds: 500).pretty(abbr: true)).equals('500ms');
    });

    test('formats seconds', () {
      check(const Duration(seconds: 30).pretty(abbr: true)).equals('30s');
    });

    test('formats minutes', () {
      check(const Duration(minutes: 5).pretty(abbr: true)).equals('5m');
    });

    test('formats hours', () {
      check(const Duration(hours: 3).pretty(abbr: true)).equals('3h');
    });

    test('formats days', () {
      check(const Duration(days: 2).pretty(abbr: true)).equals('2d');
    });

    test('handles very large duration', () {
      check(const Duration(days: 99999).pretty(abbr: true)).endsWith('y');
    });
  });

  group('IterableExtensions', () {
    test('delimitate inserts separator between elements', () {
      check([1, 2, 3].delimitate(0).toList()).deepEquals([1, 0, 2, 0, 3]);
    });

    test('delimitate on single element returns same element', () {
      check([1].delimitate(0).toList()).deepEquals([1]);
    });

    test('delimitate on empty returns empty', () {
      check(<int>[].delimitate(0).toList()).deepEquals([]);
    });

    test('mapWithIndex provides index', () {
      final result = ['a', 'b', 'c'].mapWithIndex((e, i) => '$e$i');
      check(result).deepEquals(['a0', 'b1', 'c2']);
    });
  });
}
