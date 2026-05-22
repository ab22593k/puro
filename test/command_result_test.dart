import 'package:checks/checks.dart';
import 'package:puro/src/command_result.dart';
import 'package:puro/src/terminal.dart';
import 'package:test/test.dart';

void main() {
  group('BasicMessageResult', () {
    test('constructs with simple message', () {
      final result = BasicMessageResult('hello');
      check(result.success).isTrue();
      check(result.messages.length).equals(1);
    });

    test('message content via formatMessages', () {
      final result = BasicMessageResult('hello');
      final output = CommandMessage.formatMessages(
        messages: result.messages,
        format: plainFormatter,
        success: result.success,
      );
      check(output).contains('hello');
    });

    test('supports custom success flag', () {
      final result = BasicMessageResult('hello', success: false);
      check(result.success).isFalse();
    });

    test('supports custom type', () {
      final result = BasicMessageResult('err', type: CompletionType.failure);
      final output = CommandMessage.formatMessages(
        messages: result.messages,
        format: plainFormatter,
        success: false,
      );
      check(output).contains('err');
    });

    test('list constructor', () {
      final msg = CommandMessage('a');
      final result = BasicMessageResult.list([msg], success: true);
      check(result.messages.length).equals(1);
      check(result.success).isTrue();
    });

    test('format constructor', () {
      final result = BasicMessageResult.format(
        (format) => 'formatted',
        success: true,
      );
      final output = CommandMessage.formatMessages(
        messages: result.messages,
        format: plainFormatter,
        success: true,
      );
      check(output).contains('formatted');
    });
  });

  group('CommandErrorResult', () {
    test('constructs with exception and stack trace', () {
      final exc = Exception('boom');
      final st = StackTrace.current;
      final result = CommandErrorResult(exc, st, 4);
      check(result.success).isFalse();
      check(result.messages.length).equals(2);
    });

    test('model contains exception details', () {
      final exc = Exception('boom');
      final st = StackTrace.current;
      final result = CommandErrorResult(exc, st, null);
      final model = result.model;
      check(model).isNotNull();
      check(model!.error).isNotNull();
      check(model.error.exception).contains('boom');
    });
  });

  group('CommandHelpResult', () {
    test('success when didRequestHelp is true', () {
      final result = CommandHelpResult(didRequestHelp: true);
      check(result.success).isTrue();
    });

    test('failure when didRequestHelp is false', () {
      final result = CommandHelpResult(didRequestHelp: false);
      check(result.success).isFalse();
    });

    test('includes usage message when provided', () {
      final result = CommandHelpResult(
        didRequestHelp: true,
        usage: 'usage text',
      );
      check(result.messages.length).equals(1);
    });

    test('model includes usage when provided', () {
      final result = CommandHelpResult(
        didRequestHelp: false,
        usage: 'usage text',
      );
      final model = result.model;
      check(model).isNotNull();
      check(model!.usage).equals('usage text');
    });

    test('model usage is empty when not provided', () {
      final result = CommandHelpResult(didRequestHelp: true);
      final model = result.model;
      check(model).isNotNull();
      check(model!.usage).equals('');
    });
  });

  group('CommandMessage', () {
    test('constructor creates message', () {
      final msg = CommandMessage('test');
      check(msg.type).isNull();
    });

    test('format constructor', () {
      final msg = CommandMessage.format((f) => f.prefix('> ', 'test'));
      check(msg.type).isNull();
    });

    test('formatMessages produces combined output', () {
      final msgs = [CommandMessage('a'), CommandMessage('b')];
      final output = CommandMessage.formatMessages(
        messages: msgs,
        format: plainFormatter,
        success: true,
      );
      check(output).contains('a');
      check(output).contains('b');
    });
  });

  group('CommandError', () {
    test('constructs with message and wraps as result', () {
      final err = CommandError('boom');
      check(err.result).isA<BasicMessageResult>();
      check(err.result.success).isFalse();
    });

    test('format constructor', () {
      final err = CommandError.format((f) => 'formatted');
      check(err.result).isA<BasicMessageResult>();
    });

    test('list constructor', () {
      final err = CommandError.list([CommandMessage('a')]);
      check(err.result).isA<BasicMessageResult>();
    });

    test('toString delegates to result', () {
      final err = CommandError('boom');
      check(err.toString()).contains('boom');
    });
  });

  group('UnsupportedOSError', () {
    test('message contains OS name', () {
      final err = UnsupportedOSError();
      check(err.toString()).contains('Unsupported OS');
    });
  });

  group('CommandResult.toModel', () {
    test('BasicMessageResult roundtrips', () {
      final result = BasicMessageResult('roundtrip');
      final model = result.toModel();
      check(model.success).isTrue();
      check(model.messages.length).isGreaterThan(0);
    });

    test('CommandErrorResult roundtrips', () {
      final result = CommandErrorResult(Exception('x'), StackTrace.current, null);
      final model = result.toModel();
      check(model.success).isFalse();
      check(model.error).isNotNull();
    });
  });
}
