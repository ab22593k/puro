import 'package:checks/checks.dart';
import 'package:puro/src/command_result.dart';
import 'package:puro/src/config.dart';
import 'package:test/test.dart';

void main() {
  group('isValidName', () {
    test('valid names', () {
      check(isValidName('stable')).isTrue();
      check(isValidName('foo-bar')).isTrue();
      check(isValidName('foo_bar')).isTrue();
      check(isValidName('a')).isTrue();
      check(isValidName('z')).isTrue();
      check(isValidName('foo123')).isTrue();
      check(isValidName('x-y_z')).isTrue();
    });

    test('invalid names', () {
      check(isValidName('')).isFalse();
      check(isValidName('123foo')).isFalse();
      check(isValidName('FOO')).isFalse();
      check(isValidName('foo bar')).isFalse();
      check(isValidName('foo.bar')).isFalse();
    });
  });

  group('isValidVersion', () {
    test('valid versions', () {
      check(isValidVersion('3.10.0')).isTrue();
      check(isValidVersion('3.0.0')).isTrue();
      check(isValidVersion('0.0.1')).isTrue();
      check(isValidVersion('1.0.0-alpha')).isTrue();
    });

    test('invalid versions', () {
      check(isValidVersion('foo')).isFalse();
      check(isValidVersion('3')).isFalse();
      check(isValidVersion('')).isFalse();
      check(isValidVersion('stable')).isFalse();
    });
  });

  group('isValidEnvName', () {
    test('valid env names (regular names)', () {
      check(isValidEnvName('stable')).isTrue();
      check(isValidEnvName('beta')).isTrue();
      check(isValidEnvName('my-env')).isTrue();
    });

    test('valid env names (version strings)', () {
      check(isValidEnvName('3.10.0')).isTrue();
      check(isValidEnvName('3.13.6')).isTrue();
    });

    test('invalid env names', () {
      check(isValidEnvName('')).isFalse();
      check(isValidEnvName('FOO')).isFalse();
      check(isValidEnvName('foo bar')).isFalse();
    });
  });

  group('ensureValidEnvName', () {
    test('accepts valid names', () {
      check(() => ensureValidEnvName('stable')).returnsNormally();
      check(() => ensureValidEnvName('3.10.0')).returnsNormally();
      check(() => ensureValidEnvName('foo-bar')).returnsNormally();
    });

    test('rejects invalid names with CommandError', () {
      check(() => ensureValidEnvName('')).throws<CommandError>();
      check(() => ensureValidEnvName('Foo')).throws<CommandError>();
      check(() => ensureValidEnvName('foo bar')).throws<CommandError>();
    });
  });

  group('isValidCommitHash', () {
    test('valid commit hashes', () {
      check(isValidCommitHash('abc123')).isTrue();
      check(
        isValidCommitHash('a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2'),
      ).isTrue();
      check(isValidCommitHash('a' * 40)).isTrue();
    });

    test('invalid commit hashes', () {
      check(isValidCommitHash('')).isFalse();
      check(isValidCommitHash('abc')).isFalse();
      check(isValidCommitHash('abc12')).isFalse();
      check(isValidCommitHash('xyz123')).isFalse();
      check(isValidCommitHash('ABCDEF')).isFalse();
    });
  });

  group('tryParseVersion', () {
    test('parses standard versions', () {
      final v = tryParseVersion('3.10.0');
      check(v).isNotNull();
      check(v!.major).equals(3);
      check(v.minor).equals(10);
    });

    test('strips leading v', () {
      final v = tryParseVersion('v3.10.0');
      check(v).isNotNull();
      check(v!.major).equals(3);
    });

    test('returns null for invalid input', () {
      check(tryParseVersion('')).isNull();
      check(tryParseVersion('not-a-version')).isNull();
      check(tryParseVersion('foo.bar')).isNull();
    });
  });

  group('prettyJsonEncoder', () {
    test('encodes with 2-space indent', () {
      check(prettyJsonEncoder.convert({'a': 'b'})).equals('{\n  "a": "b"\n}');
    });
  });
}
