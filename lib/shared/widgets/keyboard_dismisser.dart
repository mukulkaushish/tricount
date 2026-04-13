import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// The gestures available to dismiss the keyboard with [KeyboardDismisser].
///
/// Note that these gestures are also the ones available in [GestureDetector]
/// from Flutter's widgets library, except for [onPanUpdateDownDirection],
/// [onPanUpdateUpDirection], [onPanUpdateLeftDirection] and
/// [onPanUpdateRightDirection], which are special types of
/// [onPanUpdateAnyDirection] (corresponding to [GestureDetector.onPanUpdate])
/// that will trigger the keyboard's dismissal when swiping only in the
/// specified direction (down, up, left and right, respectively).
///
/// Just like with [GestureDetector], pan and scale callbacks cannot be used
/// simultaneously, and horizontal and vertical drag callbacks cannot be used
/// simultaneously.
///
/// See also:
///
///   * [GestureDetector], which is a widget that detects gestures.
enum GestureType {
  /// A pointer that might cause a tap has contacted the screen.
  onTapDown,

  /// A pointer that will trigger a tap has stopped contacting the screen.
  onTapUp,

  /// A tap has occurred.
  onTap,

  /// The pointer that previously triggered [onTapDown] will not end up causing
  /// a tap.
  onTapCancel,

  /// A pointer that might cause a secondary tap has contacted the screen.
  onSecondaryTapDown,

  /// A pointer that will trigger a secondary tap has stopped contacting the
  /// screen.
  onSecondaryTapUp,

  /// The pointer that previously triggered [onSecondaryTapDown] will not end
  /// up causing a tap.
  onSecondaryTapCancel,

  /// A pointer that might cause a double tap has contacted the screen.
  onDoubleTap,

  /// A long press gesture has been recognized.
  onLongPress,

  /// A long press gesture has been recognized.
  onLongPressStart,

  /// A pointer has been drag-moved after a long-press.
  onLongPressMoveUpdate,

  /// A pointer that has triggered a long-press has stopped contacting the
  /// screen.
  onLongPressUp,

  /// A pointer that has triggered a long-press has stopped contacting the
  /// screen.
  onLongPressEnd,

  /// A pointer has contacted the screen and might begin to move vertically.
  onVerticalDragDown,

  /// A pointer has contacted the screen and has begun to move vertically.
  onVerticalDragStart,

  /// A pointer moving vertically has moved in the vertical direction.
  onVerticalDragUpdate,

  /// A pointer moving vertically is no longer in contact with the screen.
  onVerticalDragEnd,

  /// The pointer that previously triggered [onVerticalDragDown] did not
  /// complete.
  onVerticalDragCancel,

  /// A pointer has contacted the screen and might begin to move horizontally.
  onHorizontalDragDown,

  /// A pointer has contacted the screen and has begun to move horizontally.
  onHorizontalDragStart,

  /// A pointer moving horizontally has moved in the horizontal direction.
  onHorizontalDragUpdate,

  /// A pointer moving horizontally is no longer in contact with the screen.
  onHorizontalDragEnd,

  /// The pointer that previously triggered [onHorizontalDragDown] did not
  /// complete.
  onHorizontalDragCancel,

  /// A pointer has pressed with sufficient force to initiate a force press.
  onForcePressStart,

  /// A pointer has pressed with the maximum force.
  onForcePressPeak,

  /// A pointer in contact with force is moving or changing force.
  onForcePressUpdate,

  /// A pointer is no longer in contact with the screen.
  onForcePressEnd,

  /// A pointer has contacted the screen and might begin to move.
  onPanDown,

  /// A pointer has contacted the screen and has begun to move.
  onPanStart,

  /// A pointer in contact with the screen and moving has moved again (any
  /// direction).
  onPanUpdateAnyDirection,

  /// A pointer moving downward has moved again.
  onPanUpdateDownDirection,

  /// A pointer moving upward has moved again.
  onPanUpdateUpDirection,

  /// A pointer moving leftward has moved again.
  onPanUpdateLeftDirection,

  /// A pointer moving rightward has moved again.
  onPanUpdateRightDirection,

  /// A pointer in contact with the screen is no longer in contact.
  onPanEnd,

  /// The pointer that previously triggered [onPanDown] did not complete.
  onPanCancel,

  /// Pointers in contact with the screen have established a focal point.
  onScaleStart,

  /// Pointers have indicated a new focal point and/or scale.
  onScaleUpdate,

  /// Pointers are no longer in contact with the screen.
  onScaleEnd,
}

/// A widget that dismisses the keyboard when the user performs a gesture.
///
/// Wrap any page (typically its [Scaffold]) with this widget to get automatic
/// keyboard dismissal. The default gesture is [GestureType.onTap].
///
/// For form-heavy screens the recommended set is:
/// ```dart
/// KeyboardDismisser(
///   gestures: const [
///     GestureType.onTap,
///     GestureType.onPanUpdateDownDirection,
///     GestureType.onPanUpdateUpDirection,
///   ],
///   child: Scaffold(...),
/// )
/// ```
///
/// Wrapping at the [MaterialApp] level applies the behaviour globally — every
/// page will dismiss the keyboard on the specified gestures without per-screen
/// boilerplate.
///
/// Note that taps absorbed by child widgets (buttons, text fields, etc.) will
/// NOT trigger the dismissal, preserving normal interaction.
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({
    super.key,
    this.child,
    this.behavior,
    this.gestures = const [GestureType.onTap],
    this.dragStartBehavior = DragStartBehavior.start,
    this.excludeFromSemantics = false,
  });

  /// Gestures that will trigger keyboard dismissal.
  final List<GestureType> gestures;

  /// Determines when a drag formally starts.
  ///
  /// See [GestureDetector.dragStartBehavior].
  final DragStartBehavior dragStartBehavior;

  /// How the internal [GestureDetector] should behave during hit testing.
  ///
  /// See [GestureDetector.behavior].
  final HitTestBehavior? behavior;

  /// Whether to exclude these gestures from the semantics tree.
  ///
  /// See [GestureDetector.excludeFromSemantics].
  final bool excludeFromSemantics;

  /// The widget below this widget in the tree.
  final Widget? child;

  @override
  Widget build(final BuildContext context) => GestureDetector(
        excludeFromSemantics: excludeFromSemantics,
        dragStartBehavior: dragStartBehavior,
        behavior: behavior,
        onTap: gestures.contains(GestureType.onTap)
            ? () => _unfocus(context)
            : null,
        onTapDown: gestures.contains(GestureType.onTapDown)
            ? (_) => _unfocus(context)
            : null,
        onPanUpdate: gestures.contains(GestureType.onPanUpdateAnyDirection)
            ? (_) => _unfocus(context)
            : null,
        onTapUp: gestures.contains(GestureType.onTapUp)
            ? (_) => _unfocus(context)
            : null,
        onTapCancel: gestures.contains(GestureType.onTapCancel)
            ? () => _unfocus(context)
            : null,
        onSecondaryTapDown: gestures.contains(GestureType.onSecondaryTapDown)
            ? (_) => _unfocus(context)
            : null,
        onSecondaryTapUp: gestures.contains(GestureType.onSecondaryTapUp)
            ? (_) => _unfocus(context)
            : null,
        onSecondaryTapCancel:
            gestures.contains(GestureType.onSecondaryTapCancel)
                ? () => _unfocus(context)
                : null,
        onDoubleTap: gestures.contains(GestureType.onDoubleTap)
            ? () => _unfocus(context)
            : null,
        onLongPress: gestures.contains(GestureType.onLongPress)
            ? () => _unfocus(context)
            : null,
        onLongPressStart: gestures.contains(GestureType.onLongPressStart)
            ? (_) => _unfocus(context)
            : null,
        onLongPressMoveUpdate:
            gestures.contains(GestureType.onLongPressMoveUpdate)
                ? (_) => _unfocus(context)
                : null,
        onLongPressUp: gestures.contains(GestureType.onLongPressUp)
            ? () => _unfocus(context)
            : null,
        onLongPressEnd: gestures.contains(GestureType.onLongPressEnd)
            ? (_) => _unfocus(context)
            : null,
        onVerticalDragDown: gestures.contains(GestureType.onVerticalDragDown)
            ? (_) => _unfocus(context)
            : null,
        onVerticalDragStart: gestures.contains(GestureType.onVerticalDragStart)
            ? (_) => _unfocus(context)
            : null,
        onVerticalDragUpdate: _gesturesContainsDirectionalPanUpdate()
            ? (details) => _unfocusWithDetails(context, details)
            : null,
        onVerticalDragEnd: gestures.contains(GestureType.onVerticalDragEnd)
            ? (_) => _unfocus(context)
            : null,
        onVerticalDragCancel:
            gestures.contains(GestureType.onVerticalDragCancel)
                ? () => _unfocus(context)
                : null,
        onHorizontalDragDown:
            gestures.contains(GestureType.onHorizontalDragDown)
                ? (_) => _unfocus(context)
                : null,
        onHorizontalDragStart:
            gestures.contains(GestureType.onHorizontalDragStart)
                ? (_) => _unfocus(context)
                : null,
        onHorizontalDragUpdate: _gesturesContainsDirectionalPanUpdate()
            ? (details) => _unfocusWithDetails(context, details)
            : null,
        onHorizontalDragEnd: gestures.contains(GestureType.onHorizontalDragEnd)
            ? (_) => _unfocus(context)
            : null,
        onHorizontalDragCancel:
            gestures.contains(GestureType.onHorizontalDragCancel)
                ? () => _unfocus(context)
                : null,
        onForcePressStart: gestures.contains(GestureType.onForcePressStart)
            ? (_) => _unfocus(context)
            : null,
        onForcePressPeak: gestures.contains(GestureType.onForcePressPeak)
            ? (_) => _unfocus(context)
            : null,
        onForcePressUpdate: gestures.contains(GestureType.onForcePressUpdate)
            ? (_) => _unfocus(context)
            : null,
        onForcePressEnd: gestures.contains(GestureType.onForcePressEnd)
            ? (_) => _unfocus(context)
            : null,
        onPanDown: gestures.contains(GestureType.onPanDown)
            ? (_) => _unfocus(context)
            : null,
        onPanStart: gestures.contains(GestureType.onPanStart)
            ? (_) => _unfocus(context)
            : null,
        onPanEnd: gestures.contains(GestureType.onPanEnd)
            ? (_) => _unfocus(context)
            : null,
        onPanCancel: gestures.contains(GestureType.onPanCancel)
            ? () => _unfocus(context)
            : null,
        onScaleStart: gestures.contains(GestureType.onScaleStart)
            ? (_) => _unfocus(context)
            : null,
        onScaleUpdate: gestures.contains(GestureType.onScaleUpdate)
            ? (_) => _unfocus(context)
            : null,
        onScaleEnd: gestures.contains(GestureType.onScaleEnd)
            ? (_) => _unfocus(context)
            : null,
        child: child,
      );

  void _unfocus(final BuildContext context) =>
      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();

  void _unfocusWithDetails(
    final BuildContext context,
    final DragUpdateDetails details,
  ) {
    final dy = details.delta.dy;
    final dx = details.delta.dx;
    final isDragMainlyHorizontal = dx.abs() - dy.abs() > 0;
    if (gestures.contains(GestureType.onPanUpdateDownDirection) &&
        dy > 0 &&
        !isDragMainlyHorizontal) {
      _unfocus(context);
    } else if (gestures.contains(GestureType.onPanUpdateUpDirection) &&
        dy < 0 &&
        !isDragMainlyHorizontal) {
      _unfocus(context);
    } else if (gestures.contains(GestureType.onPanUpdateRightDirection) &&
        dx > 0 &&
        isDragMainlyHorizontal) {
      _unfocus(context);
    } else if (gestures.contains(GestureType.onPanUpdateLeftDirection) &&
        dx < 0 &&
        isDragMainlyHorizontal) {
      _unfocus(context);
    }
  }

  bool _gesturesContainsDirectionalPanUpdate() =>
      gestures.contains(GestureType.onPanUpdateDownDirection) ||
      gestures.contains(GestureType.onPanUpdateUpDirection) ||
      gestures.contains(GestureType.onPanUpdateRightDirection) ||
      gestures.contains(GestureType.onPanUpdateLeftDirection);
}
