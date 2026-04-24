/// A lightweight reactive widget library for fine-grained Flutter UI updates.
///
/// This library exposes [Selector], a [StatefulWidget] that subscribes to any
/// [Listenable] — such as a [ChangeNotifier] or [ValueNotifier] — and
/// selectively rebuilds its subtree only when a derived value changes.
///
/// ## Motivation
///
/// Flutter's built-in [ListenableBuilder] and [AnimatedBuilder] rebuild their
/// subtrees on **every** notification from a [Listenable], even when the
/// portion of state the widget depends on has not changed. [Selector] solves
/// this by introducing a projection step:
///
/// 1. A [Selector.selector] function extracts a derived value of type `T` from
///    the [Listenable] on each notification.
/// 2. The new value is compared to the previous one — either via a custom
///    [Selector._shouldRebuild] predicate or by deep equality using
///    [DeepCollectionEquality].
/// 3. The [Selector.builder] is called **only** when the comparison determines
///    that the value has meaningfully changed.
///
/// This makes [Selector] particularly valuable when a single [ChangeNotifier]
/// manages multiple independent pieces of state and different parts of the
/// widget tree should respond to different slices of that state.
///
/// ## Usage
///
/// Import this library in your Dart/Flutter code:
///
/// ```dart
/// import 'package:selector_flutter/selector_flutter.dart';
/// ```
///
/// Then use [Selector] anywhere in your widget tree:
///
/// ```dart
/// Selector<String>(
///   listenable: myNotifier,
///   selector: (_) => myNotifier.userName,
///   builder: (context, name, child) => Text(name),
/// )
/// ```
///
/// See also:
///
/// - [Selector], the primary widget exported by this library.
/// - [ListenableBuilder], the Flutter built-in alternative without value
///   diffing.
/// - [ValueListenableBuilder], which serves a similar purpose but is limited
///   to [ValueListenable] sources.
library;

import 'package:collection/collection.dart' show DeepCollectionEquality;
import 'package:flutter/foundation.dart'
    show ChangeNotifier, Listenable, ValueListenable, ValueNotifier;
import 'package:flutter/widgets.dart'
    show
        AnimatedBuilder,
        ChangeNotifier,
        Listenable,
        ListenableBuilder,
        StatefulWidget,
        ValueListenableBuilder,
        ValueNotifier;
import 'package:selector_flutter/src/selector_flutter.dart' show Selector;

export 'src/selector_flutter.dart';
