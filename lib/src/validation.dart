import 'dart:convert';

import 'package:pub_semver/pub_semver.dart';

import 'command_result.dart';

final _nameRegex = RegExp(r'^[_\-a-z][_\-a-z0-9]*$');

/// Returns `true` if [name] matches the pattern `[_\-a-z][_\-a-z0-9]*`.
bool isValidName(String name) {
  return _nameRegex.hasMatch(name);
}

/// Returns `true` if [name] is a valid semantic version string.
bool isValidVersion(String name) {
  final version = tryParseVersion(name);
  return version != null && name == '$version';
}

/// Returns `true` if [name] is a valid environment name (name or version).
bool isValidEnvName(String name) {
  return isValidName(name) || isValidVersion(name);
}

final _commitHashRegex = RegExp(r'^[0-9a-f]{6,40}$');

/// Returns `true` if [commit] is a valid hex commit hash (6–40 characters).
bool isValidCommitHash(String commit) {
  return _commitHashRegex.hasMatch(commit);
}

/// Tries to parse [text] as a semantic version, stripping a leading `v` if present.
/// Returns `null` on failure.
Version? tryParseVersion(String text) {
  try {
    text = text.trim();
    return Version.parse(text.startsWith('v') ? text.substring(1) : text);
  } catch (exception) {
    return null;
  }
}

/// Validates [name] is a valid environment name; throws [CommandError] if not.
void ensureValidEnvName(String name) {
  if (isValidVersion(name)) return;
  for (var i = 0; i < name.length; i++) {
    final char = name[i];
    final codeUnit = char.codeUnitAt(0);
    if (char == '-' ||
        char == '_' ||
        (i != 0 && codeUnit >= 0x30 && codeUnit <= 0x39) ||
        (codeUnit >= 0x61 && codeUnit <= 0x7a)) {
      continue;
    }
    throw CommandError(
      'Unexpected `$char` at index $i of name `$name`\n'
      'Names must match pattern [_\\-a-z][_\\-a-z0-9]* or be a valid version',
    );
  }
  if (!isValidName(name)) {
    throw CommandError('Not a valid name: `$name`');
  }
}

/// A [JsonEncoder] that produces human-readable JSON with two-space indentation.
const prettyJsonEncoder = JsonEncoder.withIndent('  ');
