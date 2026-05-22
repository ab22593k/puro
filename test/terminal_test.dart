import 'package:checks/checks.dart';
import 'package:puro/src/terminal.dart';
import 'package:test/test.dart';

void main() {
  group('stripAnsiEscapes', () {
    test('removes ANSI foreground color', () {
      check(stripAnsiEscapes('\x1b[38;5;1mhello\x1b[0m')).equals('hello');
    });

    test('removes ANSI bold', () {
      check(stripAnsiEscapes('\x1b[1mbold\x1b[0m')).equals('bold');
    });

    test('passes through plain text unchanged', () {
      check(stripAnsiEscapes('hello world')).equals('hello world');
    });

    test('handles empty string', () {
      check(stripAnsiEscapes('')).equals('');
    });
  });

  group('padLeftColored', () {
    test('pads plain text', () {
      check(padLeftColored('x', 4)).equals('   x');
    });

    test('pads ANSI-colored text to correct visible width', () {
      check(padLeftColored('\x1b[1mx\x1b[0m', 4)).equals('   \x1b[1mx\x1b[0m');
    });
  });

  group('padRightColored', () {
    test('pads plain text', () {
      check(padRightColored('x', 4)).equals('x   ');
    });

    test('pads ANSI-colored text to correct visible width', () {
      check(padRightColored('\x1b[1mx\x1b[0m', 4)).equals('\x1b[1mx\x1b[0m   ');
    });
  });

  group('CompletionType', () {
    test('fromName maps all values', () {
      for (final value in CompletionType.values) {
        check(CompletionType.fromName[value.name]).equals(value);
      }
    });

    test('plain has empty prefix', () {
      check(CompletionType.plain.prefix).equals('');
    });

    test('success has checkmark prefix', () {
      check(CompletionType.success.prefix).equals('[\u2713] ');
    });
  });

  group('OutputFormatter', () {
    test('color returns content unchanged (plain formatter)', () {
      const f = OutputFormatter();
      check(f.color('hello', bold: true)).equals('hello');
    });

    test('prefix indents continuation lines', () {
      const f = OutputFormatter();
      final result = f.prefix('[X] ', 'line1\nline2\nline3');
      check(result).equals('[X] line1\n    line2\n    line3');
    });

    test('prefix with empty prefix returns content', () {
      const f = OutputFormatter();
      check(f.prefix('', 'hello')).equals('hello');
    });

    test('complete wraps content with prefix', () {
      const f = OutputFormatter();
      check(f.complete('done')).equals('[\u2713] done');
    });

    test('failure formats with x prefix', () {
      const f = OutputFormatter();
      check(f.failure('failed').startsWith('[x]')).isTrue();
    });

    test('info formats with i prefix', () {
      const f = OutputFormatter();
      check(f.info('note').startsWith('[i]')).isTrue();
    });

    test('indeterminate formats with tilde prefix', () {
      const f = OutputFormatter();
      check(f.indeterminate('working').startsWith('[~]')).isTrue();
    });

    test('success formats with checkmark prefix', () {
      const f = OutputFormatter();
      check(f.success('ok')).equals('[\u2713] ok');
    });
  });

  group('ColorOutputFormatter', () {
    test('color adds ANSI escape sequences', () {
      const f = ColorOutputFormatter();
      final result = f.color('hello', bold: true);
      check(result.contains('\x1b[')).isTrue();
      check(result.contains('hello')).isTrue();
    });
  });

  group('plainFormatter', () {
    test('is the default formatter', () {
      check(plainFormatter).isA<OutputFormatter>();
    });
  });

  group('colorFormatter', () {
    test('is a ColorOutputFormatter', () {
      check(colorFormatter).isA<ColorOutputFormatter>();
    });
  });
}
