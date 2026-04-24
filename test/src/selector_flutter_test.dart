import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selector_flutter/selector_flutter.dart';

void main() {
  group('Selector', () {
    testWidgets('builds with the initial selected value', (tester) async {
      final notifier = ValueNotifier<int>(0);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Selector<int>(
            listenable: notifier,
            selector: (_) => notifier.value,
            builder: (_, value, _) => Text('$value'),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('rebuilds when the selected value changes', (tester) async {
      final notifier = ValueNotifier<int>(0);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Selector<int>(
            listenable: notifier,
            selector: (_) => notifier.value,
            builder: (_, value, _) => Text('$value'),
          ),
        ),
      );

      notifier.value = 42;
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('does not rebuild when selected value is unchanged', (
      tester,
    ) async {
      final notifier = ValueNotifier<int>(0);
      addTearDown(notifier.dispose);

      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Selector<String>(
            listenable: notifier,
            selector: (_) => 'constant',
            builder: (_, value, _) {
              buildCount++;
              return Text(value);
            },
          ),
        ),
      );

      expect(buildCount, 1);

      notifier.value = 99; // listenable fires, but selector returns same value
      await tester.pump();

      expect(
        buildCount,
        1,
        reason: 'Should not rebuild for unchanged selector',
      );
    });

    testWidgets('respects custom shouldRebuild predicate', (tester) async {
      final notifier = ValueNotifier<List<int>>([1, 2, 3]);
      addTearDown(notifier.dispose);

      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Selector<List<int>>(
            listenable: notifier,
            selector: (_) => notifier.value,
            // Only rebuild if the length changes
            shouldRebuild: (prev, next) => prev.length != next.length,
            builder: (_, value, _) {
              buildCount++;
              return Text('${value.length}');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      // Same length — should NOT rebuild
      notifier.value = [4, 5, 6];
      await tester.pump();
      expect(buildCount, 1);

      // Different length — SHOULD rebuild
      notifier.value = [1, 2, 3, 4];
      await tester.pump();
      expect(buildCount, 2);
    });

    testWidgets('switches listenable when widget is updated', (tester) async {
      final notifierA = ValueNotifier<int>(1);
      final notifierB = ValueNotifier<int>(100);
      addTearDown(notifierA.dispose);
      addTearDown(notifierB.dispose);

      var active = notifierA;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Selector<int>(
                    listenable: active,
                    selector: (_) => active.value,
                    builder: (_, value, _) => Text('$value'),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => active = notifierB),
                    child: const Text('switch'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('switch'));
      await tester.pump();

      expect(find.text('100'), findsOneWidget);

      // notifierA should no longer trigger rebuilds
      notifierA.value = 999;
      await tester.pump();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('passes child widget through to builder', (tester) async {
      final notifier = ValueNotifier<int>(0);
      addTearDown(notifier.dispose);

      const childKey = Key('child');
      const child = SizedBox(key: childKey);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Selector<int>(
            listenable: notifier,
            selector: (_) => notifier.value,
            child: child,
            builder: (_, _, passedChild) => passedChild!,
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
    });

    testWidgets('deep equality is used when shouldRebuild is null', (
      tester,
    ) async {
      final notifier = ValueNotifier<Map<String, int>>({'a': 1});
      addTearDown(notifier.dispose);

      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Selector<Map<String, int>>(
            listenable: notifier,
            selector: (_) => notifier.value,
            builder: (_, value, _) {
              buildCount++;
              return Text('$buildCount');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      // Deeply equal map — should NOT rebuild
      notifier.value = {'a': 1};
      await tester.pump();
      expect(buildCount, 1);

      // Changed value — SHOULD rebuild
      notifier.value = {'a': 2};
      await tester.pump();
      expect(buildCount, 2);
    });
  });
}
