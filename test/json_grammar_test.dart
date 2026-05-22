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

  test('Trailing comma in list', () {
    final result = JsonGrammar.parse('[1, 2, 3,]');
    final value = result.value;
    check(jsonEncode(value.toJson())).equals('[1,2,3]');
  });

  test('Nested structures with trailing commas', () {
    final result = JsonGrammar.parse('{"a": [1, 2,], "b": {"c": "d",},}');
    final value = result.value;
    check(jsonEncode(value.toJson())).equals('{"a":[1,2],"b":{"c":"d"}}');
  });

  test('Unicode escapes', () {
    for (final entry in {'\\u0041': 'A', '\\u00e9': 'é', '\\u0048\\u0069': 'Hi'}.entries) {
      final result = JsonGrammar.parse('"${entry.key}"');
      final value = result.value;
      check(value).isA<JsonLiteral>().has((l) => l.value.value, 'value').equals(entry.value);
    }
  });

  test('Mixed escape sequences', () {
    final result = JsonGrammar.parse('"hello\\nworld\\ttab"');
    final value = result.value;
    check(value).isA<JsonLiteral>().has((l) => l.value.value, 'value').equals('hello\nworld\ttab');
  });

  test('Empty string', () {
    final result = JsonGrammar.parse('""');
    final value = result.value;
    check(value).isA<JsonLiteral>().has((l) => l.value.value, 'value').equals('');
  });

  test('Empty nested structures', () {
    final result = JsonGrammar.parse('{"a": {}, "b": []}');
    final value = result.value;
    check(jsonEncode(value.toJson())).equals('{"a":{},"b":[]}');
  });

  test('Numbers with exponents', () {
    final result = JsonGrammar.parse('1.5e10');
    final value = result.value;
    check(value).isA<JsonLiteral>().has((l) => l.value.value, 'value').equals(1.5e10);
  });
}
