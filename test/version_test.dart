import 'package:checks/checks.dart';
import 'package:puro/src/version.dart';
import 'package:test/test.dart';

void main() {
  group('PuroBuildTarget', () {
    group('fromString', () {
      test('parses windows-x64', () {
        check(PuroBuildTarget.fromString('windows-x64')).equals(PuroBuildTarget.windowsX64);
      });

      test('parses linux-x64', () {
        check(PuroBuildTarget.fromString('linux-x64')).equals(PuroBuildTarget.linuxX64);
      });

      test('parses darwin-x64', () {
        check(PuroBuildTarget.fromString('darwin-x64')).equals(PuroBuildTarget.macosX64);
      });

      test('parses darwin-arm64', () {
        check(PuroBuildTarget.fromString('darwin-arm64')).equals(PuroBuildTarget.macosArm64);
      });

      test('throws for unknown string', () {
        check(
          () => PuroBuildTarget.fromString('unknown'),
        ).throws<ArgumentError>();
      });

      test('throws for empty string', () {
        check(
          () => PuroBuildTarget.fromString(''),
        ).throws<ArgumentError>();
      });
    });

    group('properties', () {
      test('windows-x64 has correct suffixes', () {
        const target = PuroBuildTarget.windowsX64;
        check(target.name).equals('windows-x64');
        check(target.exeSuffix).equals('.exe');
        check(target.scriptSuffix).equals('.bat');
      });

      test('linux-x64 has empty suffixes', () {
        const target = PuroBuildTarget.linuxX64;
        check(target.name).equals('linux-x64');
        check(target.exeSuffix).equals('');
        check(target.scriptSuffix).equals('');
      });

      test('macosX64 has empty suffixes', () {
        const target = PuroBuildTarget.macosX64;
        check(target.name).equals('darwin-x64');
        check(target.exeSuffix).equals('');
        check(target.scriptSuffix).equals('');
      });

      test('macosArm64 has empty suffixes', () {
        const target = PuroBuildTarget.macosArm64;
        check(target.name).equals('darwin-arm64');
        check(target.exeSuffix).equals('');
        check(target.scriptSuffix).equals('');
      });
    });

    group('derived names', () {
      test('executableName includes exeSuffix', () {
        check(PuroBuildTarget.windowsX64.executableName).equals('puro.exe');
        check(PuroBuildTarget.linuxX64.executableName).equals('puro');
      });

      test('trampolineName includes scriptSuffix', () {
        check(PuroBuildTarget.windowsX64.trampolineName).equals('puro.bat');
        check(PuroBuildTarget.linuxX64.trampolineName).equals('puro');
      });

      test('flutterName includes scriptSuffix', () {
        check(PuroBuildTarget.windowsX64.flutterName).equals('flutter.bat');
        check(PuroBuildTarget.linuxX64.flutterName).equals('flutter');
      });

      test('dartName includes scriptSuffix', () {
        check(PuroBuildTarget.windowsX64.dartName).equals('dart.bat');
        check(PuroBuildTarget.linuxX64.dartName).equals('dart');
      });
    });
  });

  group('PuroInstallationType', () {
    test('distribution has description', () {
      check(PuroInstallationType.distribution.description).contains('installed normally');
    });

    test('standalone has description', () {
      check(PuroInstallationType.standalone.description).contains('standalone');
    });

    test('development has description', () {
      check(PuroInstallationType.development.description).contains('development');
    });

    test('pub has description', () {
      check(PuroInstallationType.pub.description).contains('pub');
    });

    test('unknown has description', () {
      check(PuroInstallationType.unknown.description).contains('Could not determine');
    });
  });
}
