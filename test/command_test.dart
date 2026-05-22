import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart' show UsageException;
import 'package:checks/checks.dart';
import 'package:puro/src/command.dart';
import 'package:puro/src/command_result.dart';
import 'package:puro/src/provider.dart';
import 'package:test/test.dart';

class _TestCommand extends PuroCommand {
  @override
  String get name => 'test';

  @override
  FutureOr<CommandResult> run() async => BasicMessageResult('ok');

  set rest(List<String> args) {
    argParser.addMultiOption('__rest__', hide: true);
    ArgResults results;
    try {
      results = argParser.parse(args);
    } on FormatException {
      results = argParser.parse(['--__rest__']);
    }
    _argResults = results;
  }

  ArgResults? _argResults;
  @override
  ArgResults get argResults => _argResults!;
}

class _HiddenCommand extends PuroCommand {
  @override
  String get name => '_hidden';

  @override
  FutureOr<CommandResult> run() async => BasicMessageResult('ok');
}

void main() {
  late _TestCommand cmd;

  setUp(() {
    final runner = PuroCommandRunner(
      'puro',
      'test runner',
      scope: RootScope(),
      isJson: false,
    );
    cmd = _TestCommand();
    runner.addCommand(cmd);
  });

  group('PuroCommand', () {
    group('unwrapSingleArgument', () {
      test('returns single argument', () {
        cmd.rest = ['foo'];
        check(cmd.unwrapSingleArgument()).equals('foo');
      });

      test('throws when no arguments', () {
        cmd.rest = [];
        check(() => cmd.unwrapSingleArgument()).throws<UsageException>();
      });

      test('throws when multiple arguments', () {
        cmd.rest = ['a', 'b'];
        check(() => cmd.unwrapSingleArgument()).throws<UsageException>();
      });
    });

    group('unwrapSingleOptionalArgument', () {
      test('returns null when no arguments', () {
        cmd.rest = [];
        check(cmd.unwrapSingleOptionalArgument()).isNull();
      });

      test('returns single argument', () {
        cmd.rest = ['foo'];
        check(cmd.unwrapSingleOptionalArgument()).equals('foo');
      });

      test('throws when multiple arguments', () {
        cmd.rest = ['a', 'b'];
        check(() => cmd.unwrapSingleOptionalArgument()).throws<UsageException>();
      });
    });

    group('unwrapArguments', () {
      test('returns all arguments by default', () {
        cmd.rest = ['a', 'b', 'c'];
        check(cmd.unwrapArguments()).deepEquals(['a', 'b', 'c']);
      });

      test('respects startingAt', () {
        cmd.rest = ['a', 'b', 'c'];
        check(cmd.unwrapArguments(startingAt: 1)).deepEquals(['b', 'c']);
      });

      test('enforces atLeast', () {
        cmd.rest = ['a'];
        check(() => cmd.unwrapArguments(atLeast: 2)).throws<UsageException>();
      });

      test('enforces atMost inclusive of startingAt', () {
        cmd.rest = ['a', 'b', 'c'];
        check(() => cmd.unwrapArguments(atMost: 2)).throws<UsageException>();
      });

      test('atMost with startingAt adjusts expected max', () {
        cmd.rest = ['a', 'b', 'c'];
        check(() => cmd.unwrapArguments(startingAt: 1, atMost: 1)).throws<UsageException>();
      });

      test('atMost returns limited args within range', () {
        cmd.rest = ['a', 'b'];
        check(cmd.unwrapArguments(atMost: 2)).deepEquals(['a', 'b']);
      });

      test('enforces exactly', () {
        cmd.rest = ['a', 'b'];
        check(() => cmd.unwrapArguments(exactly: 1)).throws<UsageException>();
      });

      test('exactly passes with correct count', () {
        cmd.rest = ['a', 'b'];
        check(cmd.unwrapArguments(exactly: 2)).deepEquals(['a', 'b']);
      });

      test('atMost passes with count equal to limit', () {
        cmd.rest = ['a'];
        check(cmd.unwrapArguments(atMost: 1)).deepEquals(['a']);
      });
    });

    group('name based properties', () {
      test('hidden when name starts with underscore', () {
        final hiddenCmd = _HiddenCommand();
        check(hiddenCmd.hidden).isTrue();
      });
    });
  });

  group('PuroCommandRunner', () {
    test('puroArgs returns all args when no separator', () {
      final runner = PuroCommandRunner(
        'puro',
        '',
        scope: RootScope(),
        isJson: false,
      );
      runner.parse(['cmd', 'arg1']);
      check(runner.puroArgs).deepEquals(['cmd', 'arg1']);
    });

    test('puroArgs strips args after --', () {
      final runner = PuroCommandRunner(
        'puro',
        '',
        scope: RootScope(),
        isJson: false,
      );
      runner.parse(['cmd', '--', 'extra']);
      check(runner.puroArgs).deepEquals(['cmd']);
    });

    test('didRequestHelp with --help', () {
      final runner = PuroCommandRunner(
        'puro',
        '',
        scope: RootScope(),
        isJson: false,
      );
      runner.parse(['--help']);
      check(runner.didRequestHelp).isTrue();
    });

    test('didRequestHelp with -h', () {
      final runner = PuroCommandRunner(
        'puro',
        '',
        scope: RootScope(),
        isJson: false,
      );
      runner.parse(['-h']);
      check(runner.didRequestHelp).isTrue();
    });

    test('didRequestHelp with help subcommand', () {
      final runner = PuroCommandRunner(
        'puro',
        '',
        scope: RootScope(),
        isJson: false,
      );
      runner.parse(['help']);
      check(runner.didRequestHelp).isTrue();
    });

    test('didRequestHelp false for regular args', () {
      final runner = PuroCommandRunner(
        'puro',
        '',
        scope: RootScope(),
        isJson: false,
      );
      runner.parse(['version']);
      check(runner.didRequestHelp).isFalse();
    });

    test('isExiting defaults to false', () {
      final runner = PuroCommandRunner(
        'puro',
        '',
        scope: RootScope(),
        isJson: false,
      );
      check(runner.isExiting).isFalse();
    });

    test('wrapCallback queues the callback', () {
      final runner = PuroCommandRunner(
        'puro',
        '',
        scope: RootScope(),
        isJson: false,
      );
      final calls = <String>[];
      final wrapped = runner.wrapCallback<String>((s) {
        calls.add(s);
      });
      wrapped('test');
      check(calls).isEmpty();
      check(runner.callbackQueue.length).equals(1);
      runner.callbackQueue.first();
      check(calls).deepEquals(['test']);
    });
  });
}
