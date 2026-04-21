import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvPressable extends StatefulWidget {
  final Widget Function(BuildContext context, bool focused) builder;
  final VoidCallback onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  const TvPressable({
    super.key,
    required this.builder,
    required this.onPressed,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<TvPressable> createState() => _TvPressableState();
}

class _TvPressableState extends State<TvPressable> {
  bool _focused = false;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: SystemMouseCursors.click,
      onFocusChange: (value) {
        setState(() {
          _focused = value;
        });
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: widget.focusNode,
        onKeyEvent: _handleKey,
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: widget.builder(context, _focused),
        ),
      ),
    );
  }
}