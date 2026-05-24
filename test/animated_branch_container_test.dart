import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_animated_branch/go_router_animated_branch.dart';

class _TestHarness extends StatefulWidget {
  const _TestHarness({
    super.key,
    required this.initialIndex,
    required this.duration,
    required this.children,
  });

  final int initialIndex;
  final Duration duration;
  final List<Widget> children;

  @override
  State<_TestHarness> createState() => _TestHarnessState();
}

class _TestHarnessState extends State<_TestHarness> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void switchTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return AnimatedBranchContainer(
      currentIndex: _index,
      duration: widget.duration,
      children: widget.children,
    );
  }
}

Opacity _opacityAround(WidgetTester tester, String text) {
  return tester.widget<Opacity>(
    find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
  );
}

void main() {
  group('AnimatedBranchContainer', () {
    testWidgets('shows only the branch at currentIndex', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedBranchContainer(
            currentIndex: 1,
            duration: Duration.zero,
            children: [Text('branch-0'), Text('branch-1')],
          ),
        ),
      );

      expect(find.text('branch-0'), findsOneWidget);
      expect(find.text('branch-1'), findsOneWidget);
      expect(_opacityAround(tester, 'branch-0').opacity, 0);
      expect(_opacityAround(tester, 'branch-1').opacity, 1);
    });

    testWidgets('animates opacity when currentIndex changes', (tester) async {
      final harnessKey = GlobalKey<_TestHarnessState>();

      await tester.pumpWidget(
        MaterialApp(
          home: _TestHarness(
            key: harnessKey,
            initialIndex: 0,
            duration: const Duration(milliseconds: 100),
            children: const [Text('branch-0'), Text('branch-1')],
          ),
        ),
      );

      harnessKey.currentState!.switchTo(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(_opacityAround(tester, 'branch-0').opacity, greaterThan(0));
      expect(_opacityAround(tester, 'branch-0').opacity, lessThan(1));
      expect(_opacityAround(tester, 'branch-1').opacity, greaterThan(0));
      expect(_opacityAround(tester, 'branch-1').opacity, lessThan(1));

      await tester.pumpAndSettle();

      expect(_opacityAround(tester, 'branch-0').opacity, 0);
      expect(_opacityAround(tester, 'branch-1').opacity, 1);
    });

    testWidgets('ignores pointer events on hidden branch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AnimatedBranchContainer(
            currentIndex: 0,
            duration: Duration.zero,
            children: [
              GestureDetector(onTap: () {}, child: const Text('branch-0')),
              GestureDetector(onTap: () {}, child: const Text('branch-1')),
            ],
          ),
        ),
      );

      final branchLayers = tester
          .widgetList<TickerMode>(
            find.descendant(
              of: find.byType(Stack),
              matching: find.byType(TickerMode),
            ),
          )
          .toList();

      expect(branchLayers, hasLength(2));
      expect(branchLayers[0].enabled, isTrue);
      expect(branchLayers[1].enabled, isFalse);
    });
  });
}
