/// A key for dependency injection. Each [Provider] identifies a single value
/// in the [Scope] hierarchy.
///
/// Use [Provider] to define a lazy singleton:
/// ```dart
/// final myProvider = Provider<MyService>((scope) => MyService());
/// ```
/// Use [Provider.late] to declare a provider that must be explicitly [Scope.add]ed
/// before first read.
abstract class Provider<T> {
  factory Provider(T Function(Scope scope) create) = LazyProvider;

  factory Provider.late() {
    return Provider((scope) => throw AssertionError('Provider not in scope'));
  }

  ProviderNode<T> createNode(Scope scope);
}

/// Hierarchical scope for dependency injection.
///
/// Values are registered via [add] / [replace] and retrieved via [read].
/// A [RootScope] owns the root DI container; [OverrideScope] layers overrides
/// on top of a parent without mutating it.
abstract class Scope {
  void add<T>(Provider<T> provider, T value);
  void replace<T>(Provider<T> provider, T value);
  T read<T>(Provider<T> provider);
}

/// A scope that delegates all calls to a [parent] scope.
///
/// Subclasses can override specific methods to intercept or modify scope
/// operations without affecting the parent.
abstract class ProxyScope implements Scope {
  Scope get parent;

  @override
  void add<V>(Provider<V> provider, V value) => parent.add(provider, value);

  @override
  void replace<V>(Provider<V> provider, V value) => parent.replace(provider, value);

  @override
  V read<V>(Provider<V> provider) => parent.read(provider);
}

/// A [ProxyScope] that holds a single lazily-created value for a [Provider].
///
/// Created by [Provider.createNode] and cached in [RootScope] on first read.
abstract class ProviderNode<T> extends ProxyScope {
  ProviderNode(this.parent);

  @override
  final Scope parent;

  T get value;
  Provider<T> get provider;

  void dispose() {}
}

class LazyProvider<T> implements Provider<T> {
  LazyProvider(this.create);

  final T Function(Scope scope) create;

  @override
  ProviderNode<T> createNode(Scope scope) {
    return LazyProviderNode<T>(scope, this);
  }
}

class LazyProviderNode<T> extends ProviderNode<T> {
  LazyProviderNode(super.parent, this.provider);

  @override
  final LazyProvider<T> provider;

  @override
  late final value = provider.create(this);
}

/// The root DI container that owns all provider nodes and overrides.
///
/// Caches [ProviderNode]s on first read and supports replacing values at
/// runtime via [replace].
class RootScope extends Scope {
  final nodes = <Provider<Object?>, ProviderNode<Object?>>{};
  final overrides = <Provider<Object?>, Object?>{};

  @override
  void add<T>(Provider<T> provider, T value) {
    overrides[provider] = value;
  }

  @override
  void replace<T>(Provider<T> provider, T value) {
    assert(overrides.containsKey(provider) || nodes.containsKey(provider));
    overrides[provider] = value;
    final node = nodes[provider];
    if (node != null) {
      node.dispose();
      nodes.remove(provider);
    }
  }

  @override
  T read<T>(Provider<T> provider) {
    if (overrides.containsKey(provider)) {
      return overrides[provider] as T;
    }
    final node = nodes[provider] ??= provider.createNode(this);
    return node.value as T;
  }
}

/// A scope that overlays overrides on top of a [parent] scope.
///
/// Reads check local overrides first, then delegate to [parent].
/// [replace] only mutates the parent if no local override exists.
class OverrideScope extends Scope {
  OverrideScope({required this.parent});

  final Scope parent;

  final overrides = <Provider<Object?>, Object?>{};

  @override
  void add<T>(Provider<T> provider, T value) {
    overrides[provider] = value;
  }

  @override
  void replace<T>(Provider<T> provider, T value) {
    if (overrides.containsKey(provider)) {
      overrides[provider] = value;
      return;
    }
    parent.replace(provider, value);
  }

  @override
  T read<T>(Provider<T> provider) {
    if (overrides.containsKey(provider)) {
      return overrides[provider] as T;
    }
    return parent.read<T>(provider);
  }
}
