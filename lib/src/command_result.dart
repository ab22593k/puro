import 'dart:io';

import '../models.dart';
import 'provider.dart';
import 'terminal.dart';

extension CommandResultModelExtensions on CommandResultModel {
  void addMessage(CommandMessage message, OutputFormatter format) {
    messages.add(
      CommandMessageModel(
        type: (message.type ?? (success ? CompletionType.success : CompletionType.failure)).name,
        message: message.message(format),
      ),
    );
  }

  void addMessages(Iterable<CommandMessage> messages, OutputFormatter format) {
    for (final message in messages) {
      addMessage(message, format);
    }
  }
}

/// A [CommandResult] for unhandled exceptions during command execution.
///
/// Always returns [success] as false and includes the exception details.
class CommandErrorResult extends CommandResult {
  CommandErrorResult(this.exception, this.stackTrace, this.logLevel);

  final Object exception;
  final StackTrace stackTrace;
  final int? logLevel;

  @override
  Iterable<CommandMessage> get messages {
    return [
      CommandMessage('$exception\n$stackTrace'),
      CommandMessage(
        [
          'Puro crashed! Please file an issue at https://github.com/pingbird/puro',
          if (logLevel != null && logLevel! < 4)
            'Consider running the command with a higher log level: `--log-level=4`',
        ].join('\n'),
      ),
    ];
  }

  @override
  bool get success => false;

  @override
  CommandResultModel? get model => CommandResultModel(
    error: CommandErrorModel(
      exception: '$exception',
      exceptionType: '${exception.runtimeType}',
      stackTrace: '$stackTrace',
    ),
  );
}

/// A [CommandResult] produced when a command displays usage or help text.
///
/// [success] is true only when the user explicitly requested help
/// ([didRequestHelp]).
class CommandHelpResult extends CommandResult {
  CommandHelpResult({required this.didRequestHelp, this.help, this.usage});

  final bool didRequestHelp;
  final String? help;
  final String? usage;

  @override
  Iterable<CommandMessage> get messages => [
    if (message != null) CommandMessage(help!, type: CompletionType.failure),
    if (usage != null)
      CommandMessage(
        usage!,
        type: message == null && didRequestHelp ? CompletionType.plain : CompletionType.info,
      ),
  ];

  @override
  bool get success => didRequestHelp;

  @override
  CommandResultModel? get model => CommandResultModel(usage: usage);
}

/// A simple [CommandResult] with an explicit list of [CommandMessage]s and [success] flag.
class BasicMessageResult extends CommandResult {
  BasicMessageResult(
    String message, {
    this.success = true,
    CompletionType? type,
    this.model,
  }) : messages = [CommandMessage(message, type: type)];

  BasicMessageResult.format(
    String Function(OutputFormatter format) message, {
    this.success = true,
    CompletionType? type,
    this.model,
  }) : messages = [CommandMessage.format(message, type: type)];

  BasicMessageResult.list(this.messages, {this.success = true, this.model});

  @override
  final bool success;
  @override
  final List<CommandMessage> messages;
  @override
  final CommandResultModel? model;
}

/// The result of executing a puro command.
///
/// Subclasses define the [success] status, user-facing [messages], and optional
/// structured [model] (a protobuf [CommandResultModel]) for JSON serialization.
abstract class CommandResult {
  bool get success;

  CommandMessage? get message => null;

  Iterable<CommandMessage> get messages => [message!];

  CommandResultModel? get model => null;

  CommandResultModel toModel([OutputFormatter format = plainFormatter]) {
    final result = CommandResultModel();
    if (model != null) {
      result.mergeFromMessage(model!);
    }
    result.success = success;
    result.addMessages(messages, format);
    return result;
  }

  @override
  String toString() => CommandMessage.formatMessages(
    messages: messages,
    format: plainFormatter,
    success: toModel().success,
  );
}

/// A single user-facing message with a [CompletionType] and lazy formatting.
///
/// Use [queue] to display the message through the active scope's handler.
class CommandMessage {
  CommandMessage(String message, {this.type}) : message = ((format) => message);
  CommandMessage.format(this.message, {this.type});

  final CompletionType? type;
  final String Function(OutputFormatter format) message;

  static String formatMessages({
    required Iterable<CommandMessage> messages,
    required OutputFormatter format,
    required bool success,
  }) {
    return messages
        .map(
          (e) => format.complete(
            e.message(format),
            type: e.type ?? (success ? CompletionType.success : CompletionType.failure),
          ),
        )
        .join('\n');
  }

  static final provider = Provider<void Function(CommandMessage)>(
    (scope) => (message) {},
  );

  void queue(Scope scope) => scope.read(provider)(this);
}

/// Like [CommandResult] but thrown as an exception.
class CommandError implements Exception {
  CommandError(
    String message, {
    CompletionType? type,
    CommandResultModel? model,
    bool success = false,
  }) : result = BasicMessageResult(
         message,
         success: success,
         type: type,
         model: model,
       );

  CommandError.format(
    String Function(OutputFormatter format) message, {
    CompletionType? type,
    CommandResultModel? model,
    bool success = false,
  }) : result = BasicMessageResult.format(
         message,
         success: success,
         type: type,
         model: model,
       );

  CommandError.list(
    List<CommandMessage> messages, {
    CommandResultModel? model,
    bool success = false,
  }) : result = BasicMessageResult.list(
         messages,
         success: success,
         model: model,
       );

  final CommandResult result;

  @override
  String toString() => result.toString();
}

/// A [CommandError] thrown when a puro command is run on an unsupported OS.
class UnsupportedOSError extends CommandError {
  UnsupportedOSError() : super('Unsupported OS: `${Platform.operatingSystem}`');
}
