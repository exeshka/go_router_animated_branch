import 'package:flutter/material.dart';

/// Animated container for [StatefulShellRoute] branch navigators.
///
/// Use this widget as the return value of
/// [StatefulShellRoute.navigatorContainerBuilder] to cross-fade between tab
/// branches with a subtle scale animation, while keeping every branch mounted
/// for the entire session.
///
/// ## Why not [IndexedStack]?
///
/// [IndexedStack] shows one child at a time but provides no transition. A
/// naive animated swap that rebuilds branch navigators on every tab change can
/// duplicate [GlobalKey]s and break navigation state. [AnimatedBranchContainer]
/// avoids that by mounting each branch exactly once and only animating opacity
/// and scale between the outgoing and incoming layers.
///
/// ## Example
///
/// ```dart
/// StatefulShellRoute(
///   navigatorContainerBuilder: (context, navigationShell, children) {
///     return AnimatedBranchContainer(
///       currentIndex: navigationShell.currentIndex,
///       children: children,
///     );
///   },
///   branches: [
///     // ...
///   ],
/// )
/// ```
///
/// See also:
///
/// * [StatefulShellRoute], the go_router API this widget is designed for.
/// * [StatefulNavigationShell.currentIndex], the index to pass as
///   [currentIndex].
class AnimatedBranchContainer extends StatefulWidget {
  /// Creates an animated branch container.
  ///
  /// [currentIndex] must be in the range `0..children.length - 1`.
  /// [children] are typically the branch navigator widgets supplied by
  /// [StatefulShellRoute.navigatorContainerBuilder].
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 280),
  });

  /// The index of the branch that should be visible and interactive.
  ///
  /// Usually [StatefulNavigationShell.currentIndex]. When this value changes,
  /// the widget cross-fades from the previous branch to the new one.
  final int currentIndex;

  /// Branch navigator widgets, one per [StatefulShellBranch].
  ///
  /// The list length must stay stable across rebuilds so that each branch
  /// keeps its element tree and [GlobalKey] associations.
  final List<Widget> children;

  /// Duration of the cross-fade and scale transition between branches.
  final Duration duration;

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  /// Index of the branch fading out during a transition.
  int _fromIndex = 0;

  /// Index of the branch fading in during a transition.
  int _toIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _toIndex = widget.currentIndex;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.value = 1;
    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  /// Commits the transition once the animation completes so only the target
  /// branch stays in the interactive layer.
  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    setState(() => _fromIndex = _toIndex);
  }

  @override
  void didUpdateWidget(AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentIndex == oldWidget.currentIndex) {
      return;
    }

    _controller.duration = widget.duration;
    _fromIndex = oldWidget.currentIndex;
    _toIndex = widget.currentIndex;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onAnimationStatusChanged)
      ..dispose();
    super.dispose();
  }

  bool get _isTransitioning => _fromIndex != _toIndex;

  /// Opacity for [index]: 1 for the active branch, 0 for hidden branches,
  /// interpolated during transitions.
  double _opacityFor(int index) {
    if (!_isTransitioning) {
      return index == widget.currentIndex ? 1 : 0;
    }

    if (index == _fromIndex) {
      return 1 - _progress.value;
    }
    if (index == _toIndex) {
      return _progress.value;
    }
    return 0;
  }

  /// Subtle scale-up on the incoming branch (0.97 → 1.0) during transition.
  double _scaleFor(int index) {
    if (!_isTransitioning || index != _toIndex) {
      return 1;
    }

    return 0.97 + (0.03 * _progress.value);
  }

  /// Only the visible (or incoming) branch accepts pointer events and runs
  /// tickers; hidden branches are paused to save work.
  bool _isInteractive(int index) {
    if (!_isTransitioning) {
      return index == widget.currentIndex;
    }
    return index == _toIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (index) {
            final opacity = _opacityFor(index);
            if (opacity <= 0) {
              return _BranchLayer(
                enabled: false,
                opacity: 0,
                child: widget.children[index],
              );
            }

            return _BranchLayer(
              enabled: _isInteractive(index),
              opacity: opacity,
              scale: _scaleFor(index),
              child: widget.children[index],
            );
          }),
        );
      },
    );
  }
}

/// Single branch layer: visibility, hit-testing, and ticker control.
class _BranchLayer extends StatelessWidget {
  const _BranchLayer({
    required this.enabled,
    required this.opacity,
    required this.child,
    this.scale = 1,
  });

  final bool enabled;
  final double opacity;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: TickerMode(
        enabled: enabled,
        child: Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.scale(scale: scale, child: child),
        ),
      ),
    );
  }
}
