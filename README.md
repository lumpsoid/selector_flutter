# listenable_selector

A Flutter widget that subscribes to any [`Listenable`](https://api.flutter.dev/flutter/foundation/Listenable-class.html) and rebuilds only when a **derived (selected) value** changes — without requiring a full state-management library.

## Features

- Works with any `Listenable`: `ValueNotifier`, `ChangeNotifier`, `AnimationController`, etc.
- Deep equality check via `collection` by default — no spurious rebuilds for equal collections.
- Optional `shouldRebuild` predicate for custom comparison logic.
- Supports a `child` passthrough to avoid rebuilding static subtrees.
- Automatically re-subscribes when the `listenable` reference changes.

## Installation

```yaml
dependencies:
  listenable_selector: ^0.1.0
```

## Usage

### Basic

```dart
import 'package:listenable_selector/listenable_selector.dart';

Selector<String>(
  listenable: myNotifier,
  selector: (_) => myNotifier.userName,
  builder: (context, name, child) {
    return Text(name);
  },
)
```

### With a static child

Pass expensive subtrees via `child` — they are built once and reused on every rebuild.

```dart
Selector<int>(
  listenable: counterNotifier,
  selector: (_) => counterNotifier.count,
  builder: (context, count, child) {
    return Column(
      children: [
        Text('Count: $count'),
        child!, // not rebuilt when count changes
      ],
    );
  },
  child: const HeavyStaticWidget(),
)
```

### Custom shouldRebuild

Override the equality check with your own predicate:

```dart
Selector<List<Item>>(
  listenable: myNotifier,
  selector: (_) => myNotifier.items,
  shouldRebuild: (previous, next) => previous.length != next.length,
  builder: (context, items, child) => ItemList(items: items),
)
```

## API Reference

| Parameter | Type | Required | Description |
|---|---|---|---|
| `listenable` | `Listenable` | ✅ | The object to subscribe to. |
| `selector` | `T Function(BuildContext)` | ✅ | Derives the value to watch from the current context. |
| `builder` | `ValueWidgetBuilder<T>` | ✅ | Builds the subtree from the selected value. |
| `shouldRebuild` | `bool Function(T prev, T next)?` | — | Custom equality predicate. Defaults to deep equality. |
| `child` | `Widget?` | — | Static subtree forwarded to `builder` unchanged. |

## How it works

1. On every `listenable` notification, `selector` is called.
2. If the result differs from the previous value (via `shouldRebuild` or `DeepCollectionEquality`), `builder` is called and its output is cached.
3. Subsequent notifications that produce the same value return the cached widget — no rebuild.

## License

MIT
