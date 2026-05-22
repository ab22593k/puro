import 'package:checks/checks.dart';
import 'package:puro/src/logger.dart';
import 'package:puro/src/process.dart';
import 'package:puro/src/provider.dart';
import 'package:test/test.dart';

void main() {
  late Scope scope;

  setUp(() {
    scope = RootScope();
    scope.add(PuroLogger.provider, PuroLogger(level: LogLevel.wtf));
  });

  group('runProcess', () {
    test('runs a command and returns stdout', () async {
      final result = await runProcess(scope, 'dart', ['--version']);
      check(result.exitCode).equals(0);
      check((result.stdout as String).isNotEmpty).isTrue();
    });

    test('throws on non-zero exit with throwOnFailure', () async {
      await check(
        runProcess(scope, 'sh', ['-c', 'exit 1'], throwOnFailure: true),
      ).throws<AssertionError>();
    });

    test('does not throw on non-zero exit without throwOnFailure', () async {
      final result = await runProcess(scope, 'sh', ['-c', 'exit 1']);
      check(result.exitCode).equals(1);
    });
  });

  group('runProcessSync', () {
    test('runs a command synchronously and returns stdout', () {
      final result = runProcessSync(scope, 'dart', ['--version']);
      check(result.exitCode).equals(0);
      check((result.stdout as String).isNotEmpty).isTrue();
    });

    test('throws on non-zero exit with throwOnFailure', () {
      check(
        () => runProcessSync(scope, 'sh', ['-c', 'exit 1'], throwOnFailure: true),
      ).throws<AssertionError>();
    });
  });

  group('runProcessWithTimeout', () {
    test('returns result for fast command', () async {
      final result = await runProcessWithTimeout(
        scope,
        'dart',
        ['--version'],
        timeout: const Duration(seconds: 5),
      );
      check(result).isNotNull();
      check(result!.exitCode).equals(0);
    });

    test('returns null on timeout', () async {
      final result = await runProcessWithTimeout(
        scope,
        'sleep',
        ['5'],
        timeout: const Duration(milliseconds: 100),
      );
      check(result).isNull();
    });
  });

  group('startProcess', () {
    test('starts a process and returns it', () async {
      final process = await startProcess(scope, 'sh', ['-c', 'exit 0']);
      check(process.pid).isGreaterThan(0);
      process.kill();
    });

    test('process exits with correct code', () async {
      final process = await startProcess(scope, 'sh', ['-c', 'exit 0']);
      final exitCode = await process.exitCode;
      check(exitCode).equals(0);
    });
  });

  group('_logProcessResult (indirectly through runProcess)', () {
    test('does not crash with empty stdout/stderr', () async {
      final result = await runProcess(
        scope,
        'sh',
        ['-c', 'exit 0'],
        throwOnFailure: false,
      );
      check(result.exitCode).equals(0);
      check(result.stdout as String).isEmpty();
      check(result.stderr as String).isEmpty();
    });
  });
}
