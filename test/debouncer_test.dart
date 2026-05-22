import 'dart:async';

import 'package:checks/checks.dart';
import 'package:puro/src/debouncer.dart';
import 'package:test/test.dart';

void main() {
  group('Debouncer', () {
    test('fires onUpdate immediately with zero minDuration', () async {
      final updates = <String>[];
      final debouncer = Debouncer<String>(
        minDuration: Duration.zero,
        onUpdate: (value) {
          updates.add(value);
        },
      );
      debouncer.add('hello');
      await Future(() {});
      check(updates).deepEquals(['hello']);
    });

    test('add updates value before firing', () async {
      String? lastValue;
      final debouncer = Debouncer<String>(
        minDuration: Duration.zero,
        onUpdate: (value) {
          lastValue = value;
        },
      );
      debouncer.add('first');
      await Future(() {});
      check(debouncer.value).equals('first');
      check(lastValue).equals('first');
    });

    test('value reflects most recent add', () {
      final debouncer = Debouncer<String>(
        minDuration: const Duration(milliseconds: 100),
        onUpdate: (_) {},
      );
      debouncer.add('first');
      check(debouncer.value).equals('first');
      debouncer.add('second');
      check(debouncer.value).equals('second');
    });

    test('reset clears pending updates and sets value', () async {
      var callCount = 0;
      final debouncer = Debouncer<String>(
        minDuration: const Duration(milliseconds: 50),
        onUpdate: (value) {
          callCount++;
        },
      );
      debouncer.add('old');
      debouncer.reset('new');
      check(debouncer.value).equals('new');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      check(callCount).equals(0);
    });

    test('initialValue is set on construction', () {
      final debouncer = Debouncer<String>(
        minDuration: Duration.zero,
        onUpdate: (_) {},
        initialValue: 'initial',
      );
      check(debouncer.value).equals('initial');
    });

    test('maxDuration limits delay', () async {
      var last = '';
      final debouncer = Debouncer<String>(
        minDuration: const Duration(seconds: 10),
        maxDuration: Duration.zero,
        onUpdate: (value) {
          last = value;
        },
      );
      debouncer.add('x');
      await Future(() {});
      check(last).equals('x');
    });
  });
}
