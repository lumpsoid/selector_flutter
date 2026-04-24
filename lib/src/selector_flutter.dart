import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

/// {@template selector_flutter}
/// A widget that listens to a [Listenable] and selectively rebuilds based on
/// a derived value.
///
/// [Selector] subscribes to [listenable] and, on each notification, calls
/// [selector] to compute a derived value of type [T]. The widget only rebuilds
/// if that derived value has changed — determined either by a custom
/// [Selector._shouldRebuild] predicate or by deep equality via
/// [DeepCollectionEquality].
///
/// This is useful for fine-grained performance optimisation: instead of
/// rebuilding an entire subtree whenever a [ChangeNotifier] fires, you scope
/// rebuilds to the precise slice of state the widget cares about.
///
/// ## Example
///
/// ```dart
/// Selector<String>(
///   listenable: myNotifier,
///   selector: (_) => myNotifier.userName,
///   builder: (context, name, child) {
///     return Text(name);
///   },
/// )
/// ```
///
/// ### Custom rebuild predicate
///
/// ```dart
/// Selector<List<Item>>(
///   listenable: myNotifier,
///   selector: (_) => myNotifier.items,
///   shouldRebuild: (previous, next) => previous.length != next.length,
///   builder: (context, items, child) => ItemList(items: items),
/// )
/// ```
/// {@endtemplate}
class Selector<T> extends StatefulWidget {
  /// {@macro selector_flutter}
  const Selector({
    required this.builder,
    required this.selector,
    required this.listenable,
    bool Function(T previous, T next)? shouldRebuild,
    this.child,
    super.key,
  }) : _shouldRebuild = shouldRebuild;

  /// Builds the widget subtree using the selected value.
  ///
  /// Called whenever the cache is invalidated (i.e. the selected value has
  /// changed). The [child] passed here is the same widget provided via the
  /// [child] field — it is forwarded unchanged so that expensive subtrees can
  /// be built once and reused.
  final ValueWidgetBuilder<T> builder;

  /// Derives a value of type [T] from the current [BuildContext].
  ///
  /// This is called on every [listenable] notification. If the returned value
  /// differs from the previously cached one, [builder] is re-invoked.
  final T Function(BuildContext context) selector;

  /// The [Listenable] whose notifications drive the selector.
  final Listenable listenable;

  /// Optional predicate that decides whether a change in the selected value
  /// warrants a rebuild.
  ///
  /// When `null`, [DeepCollectionEquality] is used for equality checks.
  final bool Function(T previous, T next)? _shouldRebuild;

  /// An optional widget that is passed unchanged to [builder].
  ///
  /// Use this to pass expensive-to-build subtrees that do not depend on the
  /// selected value — they will not be rebuilt when the selector changes.
  final Widget? child;

  @override
  State<Selector<T>> createState() => _SelectorState<T>();
}

class _SelectorState<T> extends State<Selector<T>> {
  T? _value;
  Widget? _cache;
  Widget? _oldWidget;

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_onListenableChange);
  }

  @override
  void didUpdateWidget(Selector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listenable != oldWidget.listenable) {
      oldWidget.listenable.removeListener(_onListenableChange);
      widget.listenable.addListener(_onListenableChange);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onListenableChange);
    _cache = null;
    _oldWidget = null;
    _value = null;
    super.dispose();
  }

  void _onListenableChange() => setState(() {});

  bool _shouldInvalidateCache(T selected) {
    if (_oldWidget != widget) return true;

    if (widget._shouldRebuild != null) {
      return widget._shouldRebuild!(_value as T, selected);
    }

    return !const DeepCollectionEquality().equals(_value, selected);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selector(context);

    if (_shouldInvalidateCache(selected)) {
      _value = selected;
      _oldWidget = widget;
      _cache = Builder(
        builder: (context) => widget.builder(context, selected, widget.child),
      );
    }

    return _cache!;
  }
}
