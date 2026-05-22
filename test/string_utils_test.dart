import 'package:checks/checks.dart';
import 'package:puro/src/string_utils.dart';
import 'package:test/test.dart';

void main() {
  group('escapePowershellString', () {
    test('escapes backtick', () {
      check(escapePowershellString('`')).equals('``');
    });

    test('escapes double quote', () {
      check(escapePowershellString('"')).equals('`"');
    });

    test('escapes dollar sign', () {
      check(escapePowershellString('\$')).equals('`\$');
    });

    test('escapes newline', () {
      check(escapePowershellString('\n')).equals('`n');
    });

    test('escapes tab', () {
      check(escapePowershellString('\t')).equals('`t');
    });

    test('escapes carriage return', () {
      check(escapePowershellString('\r')).equals('`r');
    });

    test('passes normal text through', () {
      check(escapePowershellString('hello')).equals('hello');
    });

    test('handles mixed content with newline', () {
      check(escapePowershellString('hello\$world\n')).equals('hello`\$world`n');
    });

    test('handles mixed content with double quote', () {
      check(escapePowershellString('say "hello"')).equals('say `"hello`"');
    });
  });

  group('escapeCmdString', () {
    test('escapes percent sign', () {
      check(escapeCmdString('%')).equals('%%');
    });

    test('escapes ampersand', () {
      check(escapeCmdString('&')).equals('^&');
    });

    test('escapes pipe', () {
      check(escapeCmdString('|')).equals('^|');
    });

    test('escapes angle brackets', () {
      check(escapeCmdString('< >')).equals('^< ^>');
    });

    test('escapes parentheses', () => check(escapeCmdString('()')).equals('^(^)'));

    test('escapes exclamation', () {
      check(escapeCmdString('!')).equals('^^!');
    });

    test('escapes double and single quotes', () {
      check(escapeCmdString('"\'')).equals('^"^\'');
    });

    test('passes normal text through', () {
      check(escapeCmdString('hello')).equals('hello');
    });

    test('handles mixed content', () {
      check(escapeCmdString('echo %path% & dir')).equals('echo %%path%% ^& dir');
    });
  });
}
