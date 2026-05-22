import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:puro/src/json_edit/element.dart';
import 'package:puro/src/json_edit/grammar.dart';
import 'package:test/test.dart';

void main() {
  test('Special chars', () {
    for (final entry in JsonGrammar.escapeChars.entries) {
      final result = JsonGrammar.parse('"\\${entry.key}"');
      final value = result.value;
      check(value).isA<JsonLiteral>().has((l) => l.value.value, 'value').equals(entry.value);
    }
  });

  test('Trailing commas', () {
    final result = JsonGrammar.parse('{"foo": "bar",}');
    final value = result.value;
    check(jsonEncode(value.toJson())).equals('{"foo":"bar"}');
  });
}
