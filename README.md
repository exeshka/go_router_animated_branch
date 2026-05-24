# go_router_animated_branch

Animated cross-fade container for [go_router](https://pub.dev/packages/go_router) [`StatefulShellRoute`](https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html) branch navigators.

When switching bottom-navigation tabs, the default `navigatorContainerBuilder` uses an [`IndexedStack`](https://api.flutter.dev/flutter/widgets/IndexedStack-class.html) with no transition. This package provides [`AnimatedBranchContainer`](lib/src/animated_branch_container.dart), which:

- cross-fades between branches with an ease-in-out cubic curve (280 ms by default);
- applies a subtle scale-up (0.97 → 1.0) on the incoming tab;
- keeps **every branch mounted** so branch `GlobalKey`s are never duplicated and navigation state is preserved;
- disables pointer events and tickers on hidden branches to avoid unnecessary work.

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  go_router_animated_branch: ^0.1.0
  go_router: ^14.0.0
```

## Usage

Pass `AnimatedBranchContainer` from `navigatorContainerBuilder`:

```dart
import 'package:go_router/go_router.dart';
import 'package:go_router_animated_branch/go_router_animated_branch.dart';

final router = GoRouter(
  routes: [
    StatefulShellRoute(
      pageBuilder: (context, state, navigationShell) {
        return NoTransitionPage(
          child: ScaffoldWithNavBar(navigationShell: navigationShell),
        );
      },
      navigatorContainerBuilder: (context, navigationShell, children) {
        return AnimatedBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
```

### Custom duration

```dart
AnimatedBranchContainer(
  currentIndex: navigationShell.currentIndex,
  duration: const Duration(milliseconds: 400),
  children: children,
)
```

## How it works

Each branch navigator is placed in a [`Stack`](https://api.flutter.dev/flutter/widgets/Stack-class.html) layer. On tab change, opacity is interpolated between the outgoing and incoming layers. Hidden layers use [`IgnorePointer`](https://api.flutter.dev/flutter/widgets/IgnorePointer-class.html) and [`TickerMode`](https://api.flutter.dev/flutter/widgets/TickerMode-class.html) so they do not receive touches or run animations.

Unlike rebuilding branch widgets on every switch, this approach mounts each child once for the lifetime of the shell route.

## License

MIT — see [LICENSE](LICENSE).
