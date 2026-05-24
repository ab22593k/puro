import 'dart:io';

import 'package:quectocolors/quectocolors.dart';

import 'debouncer.dart';
import 'provider.dart';

/// Removes all ANSI escape sequences from [str], returning only visible text.
String stripAnsiEscapes(String str) => str.stripAnsi;

/// Like [String.padLeft] but accounts for ANSI escapes so visible width matches [width].
String padLeftColored(String str, int width, [String padding = ' ']) {
  final stripped = stripAnsiEscapes(str);
  return padding * (width - stripped.length) + str;
}

/// Like [String.padRight] but accounts for ANSI escapes so visible width matches [width].
String padRightColored(String str, int width, [String padding = ' ']) {
  final stripped = stripAnsiEscapes(str);
  return str + padding * (width - stripped.length);
}

const plainFormatter = OutputFormatter();
const colorFormatter = ColorOutputFormatter();

/// Defines visual prefixes and colors for completion states used in CLI output.
///
/// States: [success], [failure], [info], [alert], [indeterminate], [plain].
enum CompletionType {
  plain(''),
  success('[\u2713] '),
  failure('[x] '),
  indeterminate('[~] '),
  info('[i] '),
  alert('[!] ');

  const CompletionType(this.prefix);
  final String prefix;

  QuectoStyler get styler => switch (this) {
    CompletionType.plain => (s) => s,
    CompletionType.success => QuectoColors.green,
    CompletionType.failure => QuectoColors.red,
    CompletionType.indeterminate => QuectoColors.magenta,
    CompletionType.info => QuectoColors.blue,
    CompletionType.alert => QuectoColors.ansi256(208),
  };

  static final fromName = {
    for (final value in CompletionType.values) value.name: value,
  };
}

/// Formats CLI output with colored prefixes and indentation.
///
/// The default instance ([plainFormatter]) strips ANSI escapes; colored
/// output is provided by [ColorOutputFormatter].
class OutputFormatter {
  const OutputFormatter();

  String color(
    String content, {
    QuectoStyler? foreground,
    QuectoStyler? background,
    bool bold = false,
    bool underline = false,
  }) {
    return content;
  }

  String prefix(String prefix, String content) {
    if (prefix.isEmpty) return content;
    final prefixLength = stripAnsiEscapes(prefix).length;
    final lines = '$prefix$content'.split('\n');
    return [
      lines.first,
      for (final line in lines.skip(1)) '${' ' * prefixLength}${line.replaceAll('\t', '    ')}',
    ].join('\n');
  }

  String complete(
    String content, {
    CompletionType type = CompletionType.success,
  }) {
    return prefix(
      color(type.prefix, foreground: type.styler, bold: true),
      content,
    );
  }

  String success(String content) => complete(content, type: CompletionType.success);
  String failure(String content) => complete(content, type: CompletionType.failure);
  String indeterminate(String content) => complete(content, type: CompletionType.indeterminate);
  String info(String content) => complete(content, type: CompletionType.info);

  static const indeterminatePrefix = '[~]';
}

/// An [OutputFormatter] that renders colored output using ANSI escape sequences.
///
/// Enabled automatically when the terminal supports ANSI escapes.
class ColorOutputFormatter extends OutputFormatter {
  const ColorOutputFormatter();

  @override
  String color(
    String content, {
    QuectoStyler? foreground,
    QuectoStyler? background,
    bool bold = false,
    bool underline = false,
  }) {
    var result = content;
    if (bold) result = QuectoColors.bold(result);
    if (underline) result = QuectoColors.underline(result);
    if (foreground != null) result = foreground(result);
    if (background != null) result = background(result);
    return result;
  }
}

/// Primary CLI I/O interface wrapping a [Stdout] with status-line support.
///
/// Provides debounced status rendering, colored output, and ANSI-aware
/// formatting. Available via DI as [Terminal.provider].
class Terminal implements StringSink {
  Terminal({required this.stdout});

  final Stdout stdout;
  late var enableColor =
      stdout.supportsAnsiEscapes ||
      (Platform.isWindows && (Platform.environment['TERM']?.contains('xterm') ?? false));
  late var enableStatus = enableColor;
  late final statusDebouncer = Debouncer<String>(
    minDuration: const Duration(milliseconds: 50),
    maxDuration: const Duration(milliseconds: 100),
    onUpdate: _flushStatus,
    initialValue: '',
  );

  OutputFormatter get format => enableColor ? colorFormatter : plainFormatter;

  var _status = '';

  String _clearStatusStr() {
    if (_status.isEmpty) return '';
    final lines = '\n'.allMatches(_status).length;
    _status = '';
    return '\r${lines == 0 ? '' : '\x1b[${lines}F'}\x1b[0J';
  }

  void resetStatus() {
    final output = _clearStatusStr();
    statusDebouncer.reset('');
    if (output.isNotEmpty) stdout.write(output);
  }

  String _flushStatusStr(String pendingStatus) {
    if (!enableStatus || pendingStatus == _status) return '';
    final clear = _clearStatusStr();
    _status = pendingStatus;
    return '$clear$pendingStatus';
  }

  void _flushStatus(String pendingStatus) {
    final output = _flushStatusStr(pendingStatus);
    if (output.isNotEmpty) stdout.write(output);
  }

  void flushStatus() {
    final pendingStatus = statusDebouncer.value;
    _flushStatus(pendingStatus);
    statusDebouncer.reset(pendingStatus);
  }

  String get status => _status;
  set status(String newStatus) {
    if (enableStatus) statusDebouncer.add(newStatus);
  }

  void preserveStatus() {
    final pendingStatus = statusDebouncer.value;
    if (pendingStatus.isNotEmpty || _status.isNotEmpty) {
      final flush = _flushStatusStr(pendingStatus);
      stdout.write(flush);
      if (_status.isNotEmpty) {
        stdout.write('\n');
      }
      statusDebouncer.reset('');
      _status = '';
    }
  }

  void close() {
    resetStatus();
  }

  @override
  void write(Object? object) {
    stdout.write('${_clearStatusStr()}$object');
    flushStatus();
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    write(objects.map((Object? e) => '$e').join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object? object = '']) {
    write('$object\n');
  }

  static final provider = Provider<Terminal>.late();
  static Terminal of(Scope scope) => scope.read(provider);
}
