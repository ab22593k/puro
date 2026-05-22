import 'package:checks/checks.dart';
import 'package:puro/src/logger.dart';
import 'package:puro/src/provider.dart';
import 'package:test/test.dart';

void main() {
  group('LogLevel', () {
    group('comparison operators', () {
      test('wtf < error < warning < verbose < debug', () {
        check(LogLevel.wtf < LogLevel.error).isTrue();
        check(LogLevel.error < LogLevel.warning).isTrue();
        check(LogLevel.warning < LogLevel.verbose).isTrue();
        check(LogLevel.verbose < LogLevel.debug).isTrue();
      });

      test('reverse comparisons', () {
        check(LogLevel.debug > LogLevel.verbose).isTrue();
        check(LogLevel.verbose > LogLevel.warning).isTrue();
        check(LogLevel.warning > LogLevel.error).isTrue();
        check(LogLevel.error > LogLevel.wtf).isTrue();
      });

      test('equal levels', () {
        check(LogLevel.wtf < LogLevel.wtf).isFalse();
        check(LogLevel.wtf > LogLevel.wtf).isFalse();
        check(LogLevel.wtf <= LogLevel.wtf).isTrue();
        check(LogLevel.wtf >= LogLevel.wtf).isTrue();
      });
    });

    group('shouldLog', () {
      test('null level logs nothing', () {
        final logger = PuroLogger(level: null);
        check(logger.shouldLog(LogLevel.wtf)).isFalse();
      });

      test('wtf level logs wtf', () {
        final logger = PuroLogger(level: LogLevel.wtf);
        check(logger.shouldLog(LogLevel.wtf)).isTrue();
        check(logger.shouldLog(LogLevel.error)).isFalse();
      });

      test('debug level logs everything', () {
        final logger = PuroLogger(level: LogLevel.debug);
        check(logger.shouldLog(LogLevel.debug)).isTrue();
        check(logger.shouldLog(LogLevel.verbose)).isTrue();
        check(logger.shouldLog(LogLevel.warning)).isTrue();
        check(logger.shouldLog(LogLevel.error)).isTrue();
        check(logger.shouldLog(LogLevel.wtf)).isTrue();
      });

      test('warning level logs wtf, error, warning', () {
        final logger = PuroLogger(level: LogLevel.warning);
        check(logger.shouldLog(LogLevel.wtf)).isTrue();
        check(logger.shouldLog(LogLevel.error)).isTrue();
        check(logger.shouldLog(LogLevel.warning)).isTrue();
        check(logger.shouldLog(LogLevel.verbose)).isFalse();
        check(logger.shouldLog(LogLevel.debug)).isFalse();
      });
    });
  });

  group('PuroLogger', () {
    group('log methods', () {
      test('e logs at error level', () {
        final entries = <LogEntry>[];
        final logger = PuroLogger(
          level: LogLevel.error,
          onAdd: (e) => entries.add(e),
        );
        logger.e('test error');
        check(entries.length).equals(1);
        check(entries.first.level).equals(LogLevel.error);
        check(entries.first.message).equals('test error');
      });

      test('e skips when level is wtf', () {
        final entries = <LogEntry>[];
        final logger = PuroLogger(
          level: LogLevel.wtf,
          onAdd: (e) => entries.add(e),
        );
        logger.e('test error');
        check(entries).isEmpty();
      });

      test('v logs at verbose level', () {
        final entries = <LogEntry>[];
        final logger = PuroLogger(
          level: LogLevel.verbose,
          onAdd: (e) => entries.add(e),
        );
        logger.v('test verbose');
        check(entries.first.level).equals(LogLevel.verbose);
      });

      test('w logs at warning level', () {
        final entries = <LogEntry>[];
        final logger = PuroLogger(
          level: LogLevel.warning,
          onAdd: (e) => entries.add(e),
        );
        logger.w('test warning');
        check(entries.first.level).equals(LogLevel.warning);
      });

      test('d logs at debug level', () {
        final entries = <LogEntry>[];
        final logger = PuroLogger(
          level: LogLevel.debug,
          onAdd: (e) => entries.add(e),
        );
        logger.d('test debug');
        check(entries.first.level).equals(LogLevel.debug);
      });

      test('wtf logs at wtf level', () {
        final entries = <LogEntry>[];
        final logger = PuroLogger(
          level: LogLevel.wtf,
          onAdd: (e) => entries.add(e),
        );
        logger.wtf('test wtf');
        check(entries.first.level).equals(LogLevel.wtf);
      });

      test('message interpolation with function', () {
        final entries = <LogEntry>[];
        final logger = PuroLogger(
          level: LogLevel.error,
          onAdd: (e) => entries.add(e),
        );
        logger.e(() => 'computed');
        check(entries.first.message).equals('computed');
      });
    });

    group('add method', () {
      test('filters by level', () {
        final entries = <LogEntry>[];
        final logger = PuroLogger(
          level: LogLevel.error,
          onAdd: (e) => entries.add(e),
        );
        logger.add(LogEntry(DateTime.now(), LogLevel.verbose, 'skip'));
        logger.add(LogEntry(DateTime.now(), LogLevel.error, 'keep'));
        check(entries.length).equals(1);
        check(entries.first.message).equals('keep');
      });

      test('null level filters everything', () {
        final entries = <LogEntry>[];
        final logger = PuroLogger(
          level: null,
          onAdd: (e) => entries.add(e),
        );
        logger.add(LogEntry(DateTime.now(), LogLevel.wtf, 'test'));
        check(entries).isEmpty();
      });
    });

    group('provider integration', () {
      test('provider is fine', () {
        final scope = RootScope();
        final logger = PuroLogger(level: LogLevel.debug);
        scope.add(PuroLogger.provider, logger);
        check(scope.read(PuroLogger.provider)).identicalTo(logger);
      });
    });
  });

  group('runOptional', () {
    test('runs callback and returns value', () async {
      final scope = RootScope();
      scope.add(PuroLogger.provider, PuroLogger(level: LogLevel.debug));
      final result = await runOptional(scope, 'test', () async => 42);
      check(result).equals(42);
    });

    test('returns null on exception', () async {
      final scope = RootScope();
      scope.add(PuroLogger.provider, PuroLogger(level: LogLevel.debug));
      final result = await runOptional(scope, 'test', () async => throw Exception('boom'));
      check(result).isNull();
    });

    test('skips when skip is true', () async {
      final scope = RootScope();
      scope.add(PuroLogger.provider, PuroLogger(level: LogLevel.debug));
      var ran = false;
      final result = await runOptional(
        scope,
        'test',
        () async {
          ran = true;
          return 42;
        },
        skip: true,
      );
      check(result).isNull();
      check(ran).isFalse();
    });

    test('logs skipped action at verbose level', () async {
      final entries = <LogEntry>[];
      final scope = RootScope();
      scope.add(
        PuroLogger.provider,
        PuroLogger(level: LogLevel.verbose, onAdd: (e) => entries.add(e)),
      );
      await runOptional(scope, 'test', () async => 42, skip: true);
      check(entries.any((e) => e.message.contains('Skipped'))).isTrue();
    });
  });
}
