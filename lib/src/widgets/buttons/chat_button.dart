import 'package:flutter/material.dart';
import '../../theme/chat_composer_theme.dart';

class ChatButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final double? size;
  final String? semanticLabel;
  final ChatComposerTheme? theme;
  final bool showPressedState;

  const ChatButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.enabled = true,
    this.size,
    this.semanticLabel,
    this.theme,
    this.showPressedState = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveTheme =
        theme ?? ChatComposerTheme.fromMaterial(Theme.of(context));
    final isEnabled = enabled && onPressed != null;
    final buttonSize = size ?? effectiveTheme.sizes.buttonSize;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Semantics(
        button: true,
        enabled: isEnabled,
        label: semanticLabel,
        child: _ButtonGestureDetector(
          onPressed: isEnabled ? onPressed : null,
          showPressedState: showPressedState,
          theme: effectiveTheme,
          size: buttonSize,
          child: _ButtonContent(
            icon: icon,
            isEnabled: isEnabled,
            theme: effectiveTheme,
          ),
        ),
      ),
    );
  }
}

class _ButtonGestureDetector extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool showPressedState;
  final ChatComposerTheme theme;
  final double size;
  final Widget child;

  const _ButtonGestureDetector({
    required this.onPressed,
    required this.showPressedState,
    required this.theme,
    required this.size,
    required this.child,
  });

  @override
  State<_ButtonGestureDetector> createState() => _ButtonGestureDetectorState();
}

class _ButtonGestureDetectorState extends State<_ButtonGestureDetector> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && widget.showPressedState) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
    }
  }

  void _handleTap() {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed != null ? _handleTap : null,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.theme.colors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.size / 2),
        ),
        child: widget.child,
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final Widget icon;
  final bool isEnabled;
  final ChatComposerTheme theme;

  const _ButtonContent({
    required this.icon,
    required this.isEnabled,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: theme.sizes.iconSize,
      height: theme.sizes.iconSize,
      child: icon,
    );
  }
}

class ChatButtonBuilder {
  static Widget icon({
    required IconData iconData,
    VoidCallback? onPressed,
    bool enabled = true,
    double? size,
    String? semanticLabel,
    ChatComposerTheme? theme,
    bool showPressedState = false,
  }) {
    return ChatButton(
      icon: Icon(iconData),
      onPressed: onPressed,
      enabled: enabled,
      size: size,
      semanticLabel: semanticLabel,
      theme: theme,
      showPressedState: showPressedState,
    );
  }

  static Widget themed({
    Key? key,
    required Widget Function(BuildContext context, {double? size, Color? color})
        iconBuilder,
    required BuildContext context,
    VoidCallback? onPressed,
    bool enabled = true,
    double? size,
    String? semanticLabel,
    ChatComposerTheme? theme,
    bool showPressedState = false,
  }) {
    final effectiveTheme =
        theme ?? ChatComposerTheme.fromMaterial(Theme.of(context));
    final iconColor = enabled
        ? effectiveTheme.colors.primary
        : effectiveTheme.colors.primary.withOpacity(0.3);

    return ChatButton(
      key: key,
      icon: iconBuilder(
        context,
        size: effectiveTheme.sizes.iconSize,
        color: iconColor,
      ),
      onPressed: onPressed,
      enabled: enabled,
      size: size,
      semanticLabel: semanticLabel,
      theme: theme,
      showPressedState: showPressedState,
    );
  }
}
