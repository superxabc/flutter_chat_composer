import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 支持基于 id 精准替换 SVG 元素颜色
class IdBasedColorMapper extends ColorMapper {
  final Color themeColor;
  final Set<String> idTargets;

  const IdBasedColorMapper({
    required this.themeColor,
    this.idTargets = const {'background'},
  });

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    // 不修改白色箭头
    if (color == const Color(0xFFFFFFFF)) return color;

    // 优先基于 ID 替换
    if (id != null && idTargets.contains(id)) {
      return themeColor;
    }

    // fallback: 兼容 fill="currentColor" 被解析为黑色
    if (attributeName == 'fill' && color == const Color(0xFF000000)) {
      return themeColor;
    }

    return color;
  }
}

class SvgIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;
  final bool usesCurrentColor;

  const SvgIcon({
    Key? key,
    required this.assetPath,
    this.size,
    this.color,
    this.usesCurrentColor = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24;

    try {
      return SvgPicture.asset(
        assetPath,
        package: 'flutter_chat_composer',
        width: iconSize,
        height: iconSize,
        colorFilter: (usesCurrentColor && color != null)
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : (color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null),
        placeholderBuilder: (context) => _fallbackIcon(iconSize),
      );
    } catch (e) {
      return _fallbackIcon(iconSize);
    }
  }

  Widget _fallbackIcon(double iconSize) {
    return Icon(
      _getFallbackIcon(assetPath),
      size: iconSize,
      color: color,
    );
  }

  IconData _getFallbackIcon(String assetPath) {
    if (assetPath.contains('voice')) return Icons.mic;
    if (assetPath.contains('keyboard')) return Icons.keyboard;
    if (assetPath.contains('send')) return Icons.send;
    if (assetPath.contains('camera')) return Icons.camera_alt;
    if (assetPath.contains('more')) return Icons.add;
    if (assetPath.contains('sound')) return Icons.graphic_eq;
    return Icons.help;
  }
}

class ChatComposerSvgIcons {
  const ChatComposerSvgIcons._();

  static const String _basePath = 'assets/icons/';

  static const String microphone = '${_basePath}custom_voice.svg';
  static const String keyboard = '${_basePath}custom_keyboard.svg';
  static const String send = '${_basePath}custom_send.svg';
  static const String camera = '${_basePath}custom_camera.svg';
  static const String more = '${_basePath}custom_more.svg';
  static const String sound = '${_basePath}custom_sound.svg';

  static Widget icon(
    String assetPath, {
    double? size,
    Color? color,
    bool usesCurrentColor = false,
  }) {
    return SvgIcon(
      assetPath: assetPath,
      size: size,
      color: color,
      usesCurrentColor: usesCurrentColor,
    );
  }

  static Widget microphoneIcon({double? size, Color? color}) {
    return icon(microphone, size: size, color: color);
  }

  static Widget keyboardIcon({double? size, Color? color}) {
    return icon(keyboard, size: size, color: color);
  }

  static Widget sendIcon({double? size, Color? color}) {
    return Semantics(
      label: '发送',
      child: SvgPicture.asset(
        send,
        package: 'flutter_chat_composer',
        width: size ?? 24,
        height: size ?? 24,
        colorMapper: color != null
            ? IdBasedColorMapper(themeColor: color)
            : null,
      ),
    );
  }

  static Widget cameraIcon({double? size, Color? color}) {
    return icon(camera, size: size, color: color);
  }

  static Widget moreIcon({double? size, Color? color}) {
    return icon(more, size: size, color: color);
  }

  static Widget soundIcon({double? size, Color? color}) {
    return icon(sound, size: size, color: color);
  }
}

