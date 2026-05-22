import 'package:checks/checks.dart';
import 'package:puro/src/provider.dart';
import 'package:test/test.dart';

void main() {
  group('RootScope', () {
    test('read throws when nothing is registered', () {
      final scope = RootScope();
      final p = Provider<int>((_) => 42);
      check(() => scope.read(p)).returnsNormally();
    });

    test('add then read returns the added value', () {
      final scope = RootScope();
      final p = Provider((_) => 0);
      scope.add(p, 99);
      check(scope.read(p)).equals(99);
    });

    test('replace updates value and disposes old node', () {
      final scope = RootScope();
      final p = Provider((_) => 1);
      scope.add(p, 1);
      scope.replace(p, 2);
      check(scope.read(p)).equals(2);
    });

    test('lazy provider calls factory on first read', () {
      var callCount = 0;
      final scope = RootScope();
      final p = Provider<int>((_) {
        callCount++;
        return 99;
      });
      check(scope.read(p)).equals(99);
      check(callCount).equals(1);
    });

    test('lazy provider caches value across reads', () {
      var callCount = 0;
      final scope = RootScope();
      final p = Provider<int>((_) {
        callCount++;
        return 99;
      });
      scope.read(p);
      scope.read(p);
      check(callCount).equals(1);
    });

    test('override scopes override add', () {
      final root = RootScope();
      final p = Provider((_) => 'root');
      root.add(p, 'root');

      final child = OverrideScope(parent: root);
      child.add(p, 'child');
      check(child.read(p)).equals('child');
      check(root.read(p)).equals('root');
    });

    test('override scopes fall through to parent when not overridden', () {
      final root = RootScope();
      final p = Provider((_) => 'root');
      root.add(p, 'root');

      final child = OverrideScope(parent: root);
      check(child.read(p)).equals('root');
    });
  });

  group('Provider.late', () {
    test('throws on read when not added', () {
      final scope = RootScope();
      final p = Provider<String>.late();
      check(() => scope.read(p)).throws<AssertionError>();
    });

    test('returns value after add', () {
      final scope = RootScope();
      final p = Provider<String>.late();
      scope.add(p, 'hello');
      check(scope.read(p)).equals('hello');
    });
  });

  group('ProxyScope', () {
    test('delegates read to parent when no local override', () {
      final root = RootScope();
      final p = Provider<int>((_) => 42);
      root.add(p, 42);

      final proxy = _TestProxyScope(root);
      check(proxy.read(p)).equals(42);
    });
  });

  group('ProviderNode', () {
    test('dispose is a no-op by default', () {
      final scope = RootScope();
      final p = Provider<int>((_) => 42);
      final node = p.createNode(scope);
      check(() => node.dispose()).returnsNormally();
    });
  });
}

class _TestProxyScope extends ProxyScope {
  _TestProxyScope(this.parent);

  @override
  Scope parent;
}
