import 'package:flutter/material.dart';

/// Basic widget with the behavior to generate a scrollable screen
class AppScreenScroll extends StatelessWidget {
  /// If the scrollable behavior is enabled
  final bool isScrollable;

  /// If app bar is enabled
  final bool isToolbarActive;

  /// If required a safe area from [child]
  final bool activeSafeArea;

  /// Body for screen
  final Widget? child;

  const AppScreenScroll({
    super.key,
    this.isScrollable = true,
    this.isToolbarActive = true,
    this.activeSafeArea = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return activeSafeArea
        ? SafeArea(bottom: false, child: _getLayout(context))
        : _getLayout(context);
  }

  /// Widget with scrollable behavior
  Widget _getLayout(BuildContext context) {
    return isScrollable
        ? ScrollConfiguration(
          behavior: AppBackgroundScrollBehavior(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            scrollDirection: Axis.vertical,
            child: _getBody(context),
          ),
        )
        : _getBody(context);
  }

  /// Widget with the body of screen
  Widget _getBody(BuildContext context) {
    return SizedBox(height: _getHeight(context), child: child);
  }

  /// Current height from screen according to [isToolbarActive] and [isScrollable]
  double _getHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    if (!isScrollable && !isToolbarActive) {
      return height;
    }

    if (!isScrollable) {
      return height - kToolbarHeight;
    }

    final safePadding = MediaQueryData.fromView(View.of(context)).padding;
    if (!isToolbarActive) {
      return height - safePadding.top;
    }

    return height - safePadding.top - kToolbarHeight;
  }
}

/// Single scroll behavior for `AppScreenScroll`
class AppBackgroundScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
