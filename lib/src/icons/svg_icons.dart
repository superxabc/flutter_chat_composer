import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 发送图标的颜色映射器，只替换currentColor部分，保持白色箭头
class _SendIconColorMapper extends ColorMapper {
  final Color themeColor;
  
  const _SendIconColorMapper(this.themeColor);
  
  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    // 只对fill="currentColor"的元素应用主题色
    // 白色箭头(#FFFFFF)保持不变
    if (attributeName == 'fill' && color == const Color(0xFF000000)) {
      // currentColor在解析时通常被解析为黑色，这里替换为主题色
      return themeColor;
    }
    // 保持其他颜色不变，包括白色箭头
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
      if (usesCurrentColor && color != null) {
        // 对于使用currentColor的SVG，使用ColorFilter替代
        // flutter_svg的currentColor机制在某些情况下不够可靠
        return SvgPicture.asset(
          assetPath,
          package: 'flutter_chat_composer',
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
          placeholderBuilder: (BuildContext context) {
            return Icon(
              _getFallbackIcon(assetPath),
              size: iconSize,
              color: color,
            );
          },
        );
      } else {
        // 对于其他SVG，使用ColorFilter
        return SvgPicture.asset(
          assetPath,
          package: 'flutter_chat_composer',
          width: iconSize,
          height: iconSize,
          colorFilter: color != null 
              ? ColorFilter.mode(color!, BlendMode.srcIn)
              : null,
          placeholderBuilder: (BuildContext context) {
            return Icon(
              _getFallbackIcon(assetPath),
              size: iconSize,
              color: color,
            );
          },
        );
      }
    } catch (e) {
      return Icon(
        _getFallbackIcon(assetPath),
        size: iconSize,
        color: color,
      );
    }
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
  
  static Widget icon(String assetPath, {double? size, Color? color, bool usesCurrentColor = false}) {
    return SvgIcon(
      assetPath: assetPath,
      size: size,
      color: color,
      usesCurrentColor: usesCurrentColor,
    );
  }
  
  static Widget microphoneIcon({double? size, Color? color}) {
    return icon(microphone, size: size, color: color, usesCurrentColor: false);
  }
  
  static Widget keyboardIcon({double? size, Color? color}) {
    return icon(keyboard, size: size, color: color, usesCurrentColor: false);
  }
  
  static Widget sendIcon({double? size, Color? color}) {
    return Semantics(
      label: '发送',
      child: SvgPicture.asset(
        send,
        package: 'flutter_chat_composer',
        width: size ?? 24,
        height: size ?? 24,
        colorMapper: color != null ? _SendIconColorMapper(color) : null,
      ),
    );
  }
  
  static Widget cameraIcon({double? size, Color? color}) {
    return icon(camera, size: size, color: color, usesCurrentColor: false);
  }
  
  static Widget moreIcon({double? size, Color? color}) {
    return icon(more, size: size, color: color, usesCurrentColor: false);
  }
  
  static Widget soundIcon({double? size, Color? color}) {
    return icon(sound, size: size, color: color, usesCurrentColor: false);
  }
} 