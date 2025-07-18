import 'package:flutter/material.dart';

class ChatComposerTheme {
  final ChatThemeColors colors;
  final ChatThemeSizes sizes;
  final ChatThemeStyles styles;
  final ChatThemeDecorations decorations;
  
  const ChatComposerTheme({
    required this.colors,
    required this.sizes,
    required this.styles,
    required this.decorations,
  });
  
  static ChatComposerTheme flat() {
    const techBlue = Color(0xFF007AFF);
    return ChatComposerTheme(
      colors: ChatThemeColors(
        primary: techBlue,
        background: Colors.transparent,
        surface: Colors.white,
        onSurface: const Color(0xFF1D1D1F),
        hint: techBlue.withOpacity(0.3),
        disabled: techBlue.withOpacity(0.3),
        error: const Color(0xFFFF3B30),
      ),
      sizes: const ChatThemeSizes(),
      styles: const ChatThemeStyles(),
      decorations: ChatThemeDecorations(
        containerDecoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: techBlue,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        shadowDecoration: null,
      ),
    );
  }
  
  static ChatComposerTheme clean() {
    const darkGray = Color(0xFF1A1A1A);
    return ChatComposerTheme(
      colors: ChatThemeColors(
        primary: darkGray,
        background: Colors.transparent,
        surface: Colors.white,
        onSurface: darkGray,
        hint: darkGray.withOpacity(0.3),
        disabled: darkGray.withOpacity(0.3),
        error: const Color(0xFFFF3B30),
      ),
      sizes: const ChatThemeSizes(),
      styles: const ChatThemeStyles(),
      decorations: ChatThemeDecorations(
        containerDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        shadowDecoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
  
  static ChatComposerTheme custom({
    required Color primaryColor,
    Color backgroundColor = Colors.transparent,
    Color surfaceColor = Colors.white,
    bool hasBorder = true,
    bool hasShadow = false,
    double borderRadius = 16.0,
  }) {
    return ChatComposerTheme(
      colors: ChatThemeColors(
        primary: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        onSurface: primaryColor,
        hint: primaryColor.withOpacity(0.3),
        disabled: primaryColor.withOpacity(0.3),
        error: const Color(0xFFFF3B30),
      ),
      sizes: const ChatThemeSizes(),
      styles: const ChatThemeStyles(),
      decorations: ChatThemeDecorations(
        containerDecoration: BoxDecoration(
          color: surfaceColor,
          border: hasBorder ? Border.all(
            color: primaryColor,
            width: 1.0,
          ) : null,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: hasShadow ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        shadowDecoration: hasShadow ? BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ) : null,
      ),
    );
  }
  
  factory ChatComposerTheme.fromMaterial(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    
    return ChatComposerTheme(
      colors: ChatThemeColors(
        primary: primaryColor,
        background: Colors.transparent,
        surface: theme.colorScheme.surface,
        onSurface: theme.colorScheme.onSurface,
        hint: primaryColor.withOpacity(0.3),
        disabled: theme.disabledColor,
        error: theme.colorScheme.error,
      ),
      sizes: const ChatThemeSizes(),
      styles: const ChatThemeStyles(),
      decorations: ChatThemeDecorations(
        containerDecoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: primaryColor,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        shadowDecoration: isDark ? null : BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatThemeColors {
  final Color primary;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color hint;
  final Color disabled;
  final Color error;
  
  const ChatThemeColors({
    required this.primary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.hint,
    required this.disabled,
    required this.error,
  });
}

class ChatThemeSizes {
  final double inputContainerHeight;
  final double inputToolbarHeight;
  final double buttonSize;
  final double iconSize;
  final double borderRadius;
  final double buttonGap;
  final double lineHeight;
  final EdgeInsets containerInset;
  
  const ChatThemeSizes({
    this.inputContainerHeight = 60.0,
    this.inputToolbarHeight = 48.0,
    this.buttonSize = 44.0,
    this.iconSize = 24.0,
    this.borderRadius = 16.0,
    this.buttonGap = 2.0,
    this.lineHeight = 24.0,
    this.containerInset = const EdgeInsets.all(16.0),
  });
}

class ChatThemeStyles {
  final TextStyle inputText;
  final TextStyle hintText;
  final TextStyle buttonText;
  final Duration animationDuration;
  final Curve animationCurve;
  
  const ChatThemeStyles({
    this.inputText = const TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    this.hintText = const TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    this.buttonText = const TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
    ),
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeInOut,
  });
}

class ChatThemeDecorations {
  final BoxDecoration containerDecoration;
  final BoxDecoration? shadowDecoration;
  
  const ChatThemeDecorations({
    required this.containerDecoration,
    this.shadowDecoration,
  });
}

class ChatComposerConfig {
  final bool enableVoice;
  final bool enableCamera;
  final bool enableMoreButton;
  final bool enableHapticFeedback;
  final int maxTextLength;
  final int minTextLines;
  final int maxTextLines;
  final int maxVoiceDuration;
  
  const ChatComposerConfig({
    this.enableVoice = true,
    this.enableCamera = true,
    this.enableMoreButton = true,
    this.enableHapticFeedback = true,
    this.maxTextLength = 1000,
    this.minTextLines = 2,
    this.maxTextLines = 6,
    this.maxVoiceDuration = 60,
  });
}

enum ChatThemeStyle {
  flat,
  clean,
  custom,
} 