# Flutter Chat Composer

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 简介

Flutter Chat Composer 是一个现代化、多功能的聊天输入组件，支持文字、语音、图片、文件等多种输入方式。组件采用简洁的设计，支持主题定制和多种交互模式。

## 特性

- ✅ **多模态输入**：文字、语音、图片、文件输入
- ✅ **三种输入模式**：空闲模式、文字模式、语音模式
- ✅ **自适应布局**：文本输入框自适应高度（2-6行）
- ✅ **主题定制**：完整的主题系统，支持扁平、简洁和自定义风格
- ✅ **SVG图标系统**：精美的自定义SVG图标，自动适配主题色
- ✅ **触觉反馈**：提供良好的用户体验
- ✅ **权限处理**：自动处理相机、麦克风、存储权限

## 安装

在 `pubspec.yaml` 文件中添加：

```yaml
dependencies:
  flutter_chat_composer: ^2.0.0
```

运行命令：
```bash
flutter pub get
```

## 基本用法

### 1. 最简单的使用

```dart
import 'package:flutter_chat_composer/flutter_chat_composer.dart';

ChatComposer(
  onSubmit: (ChatContent content) {
    // 处理用户提交的内容
    print('用户提交：${content.text}');
  },
)
```

### 2. 完整示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_composer/flutter_chat_composer.dart';
import 'package:flutter_chat_composer/src/chat_input_types.dart'; // 导入 ChatContent 和 ChatInputErrorType

// 假设的聊天消息模型
class ChatMessage {
  final String text;
  final ChatContentType type;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.type, required this.timestamp});
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Composer Example')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message.text),
                  subtitle: Text('${message.type.name} - ${message.timestamp.toLocal()}'),
                );
              },
            ),
          ),
          ChatComposer(
            onSubmit: _handleSubmit,
            onModeChange: (mode) {
              print('模式切换：$mode');
            },
            onTextChange: (text) {
              print('文本变化：$text');
            },
            onError: (error) {
              print('错误：${error.message}');
              // 根据错误类型进行处理，例如显示SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('错误: ${error.message}')),
              );
            },
            config: ChatComposerConfig(
              enableVoiceRecording: true, // 启用语音录制
              enableMoreActions: true,    // 启用更多操作面板
              enableHapticFeedback: true, // 启用触觉反馈
              maxTextLength: 500,         // 最大文本长度
              minTextLines: 2,            // 最小行数
              maxTextLines: 6,            // 最大行数
              maxRecordingDuration: Duration(minutes: 2), // 最大录制时长
            ),
            placeholder: '输入消息...',
            sendHintText: '发消息或按住说话',
            holdToTalkText: '按住 说话',
          ),
        ],
      ),
    );
  }
  
  void _handleSubmit(ChatContent content) {
    setState(() {
      _messages.add(ChatMessage(
        text: content.text ?? content.voiceFilePath ?? content.imageFilePath ?? content.filePath ?? '未知内容',
        type: content.type,
        timestamp: DateTime.now(),
      ));
    });
    // 实际应用中，这里会将消息发送到后端或进行其他处理
    print('提交内容: $content');
  }
}
```

## 核心概念

### 1. 输入模式 (ChatInputMode)

- **idle**：空闲状态，显示提示文字和功能按钮
- **text**：文字输入状态，显示文本输入框和工具栏
- **voice**：语音输入状态，显示语音录制界面

### 2. 内容类型 (ChatContentType)

- **text**：文本消息
- **voice**：语音消息
- **image**：图片消息
- **file**：文件消息

### 3. 主要属性

```dart
ChatComposer(
  // 必需回调
  onSubmit: (ChatContent content) {},
  
  // 可选回调
  onModeChange: (ChatInputMode mode) {},
  onTextChange: (String text) {},
  onError: (ChatInputError error) {},
  onStatusChange: (ChatInputStatus status) {},
  
  // 配置 (通过 ChatComposerConfig 对象进行配置)
  config: ChatComposerConfig(
    maxTextLength: 1000,           // 最大文本长度
    maxRecordingDuration: Duration(seconds: 60), // 最大语音时长(秒)
    enableVoiceRecording: true,    // 启用语音录制功能
    enableMoreActions: true,       // 启用更多功能面板
    enableHapticFeedback: true,    // 启用触觉反馈
    minTextLines: 2,               // 文本输入框最小行数
    maxTextLines: 6,               // 文本输入框最大行数
  ),
  
  // 文本配置
  placeholder: '输入消息...',
  sendHintText: '发消息或按住说话',
  holdToTalkText: '按住 说话',
  
  // 主题 (通过 themeStyle 或 theme 属性进行配置)
  themeStyle: ChatThemeStyle.flat, // 预设主题风格
  // theme: ChatComposerTheme.custom(...), // 自定义主题
)
```

## 主题定制

Flutter Chat Composer 提供了三种预设主题风格和完全自定义主题的能力。

### 1. 使用预设主题风格

通过 `themeStyle` 属性选择预设主题：

```dart
import 'package:flutter_chat_composer/flutter_chat_composer.dart';
import 'package:flutter_chat_composer/src/theme/chat_composer_theme.dart'; // 导入 ChatThemeStyle

// 扁平风格 (默认)
ChatComposer(
  themeStyle: ChatThemeStyle.flat,
  onSubmit: (content) {},
)

// 简洁风格
ChatComposer(
  themeStyle: ChatThemeStyle.clean,
  onSubmit: (content) {},
)
```

### 2. 完全自定义主题

通过 `theme` 属性提供一个 `ChatComposerTheme` 实例进行完全自定义：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_composer/flutter_chat_composer.dart';
import 'package:flutter_chat_composer/src/theme/chat_composer_theme.dart'; // 导入 ChatComposerTheme

ChatComposer(
  themeStyle: ChatThemeStyle.custom, // 必须设置为 custom 才能使用 theme 属性
  theme: ChatComposerTheme.custom(
    primaryColor: Colors.deepPurple,
    backgroundColor: Colors.grey[100]!,
    surfaceColor: Colors.white,
    hasBorder: true,
    hasShadow: true,
    borderRadius: 12.0,
  ),
  onSubmit: (content) {},
)
```

## 功能配置

### 1. 配置对象 (ChatComposerConfig)

通过 `config` 属性传入 `ChatComposerConfig` 实例来配置组件的各项功能：

```dart
ChatComposer(
  config: ChatComposerConfig(
    enableVoiceRecording: true,       // 启用语音录制 (默认 true)
    enableMoreActions: true,          // 启用更多操作面板 (默认 true)
    enableHapticFeedback: true,       // 启用触觉反馈 (默认 true)
    maxTextLength: 500,               // 最大文本长度 (默认 1000)
    minTextLines: 2,                  // 文本输入框最小行数 (默认 2)
    maxTextLines: 6,                  // 文本输入框最大行数 (默认 6)
    maxRecordingDuration: Duration(minutes: 2),  // 最大录制时长 (默认 2分钟)
    // allowedFileTypes: ['pdf', 'doc', 'txt'], // 允许的文件类型 (目前未实现，文档已移除)
    // maxFileSize: 10,                  // 最大文件大小(MB) (目前未实现，文档已移除)
  ),
  onSubmit: (content) {},
)
```

### 2. 自定义更多操作

通过 `customMoreActions` 属性提供自定义的更多操作项：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_composer/flutter_chat_composer.dart';
import 'package:flutter_chat_composer/src/chat_input_types.dart'; // 导入 MoreActionItem

ChatComposer(
  customMoreActions: [
    MoreActionItem(
      icon: Icons.location_on,
      label: '位置',
      onTap: () {
        // 处理位置分享逻辑
        print('分享位置');
      },
    ),
    MoreActionItem(
      icon: Icons.gif,
      label: 'GIF',
      onTap: () {
        // 处理GIF选择逻辑
        print('选择GIF');
      },
    ),
  ],
  onSubmit: (content) {},
)
```

## 错误处理

组件通过 `onError` 回调报告内部发生的错误，例如权限拒绝、录音失败等。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_composer/flutter_chat_composer.dart';
import 'package:flutter_chat_composer/src/chat_input_types.dart'; // 导入 ChatInputErrorType

ChatComposer(
  onError: (ChatInputError error) {
    switch (error.type) {
      case ChatInputErrorType.permissionDenied:
        // 权限被拒绝，可以引导用户到设置页面
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('权限被拒绝'),
            content: Text('需要相应权限才能使用该功能。请前往应用设置启用。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('确定'),
              ),
            ],
          ),
        );
        break;
      case ChatInputErrorType.fileTooLarge:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件过大')),
        );
        break;
      case ChatInputErrorType.networkError:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('网络错误，请检查您的网络连接。')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发生未知错误: ${error.message}')),
        );
    }
  },
  onSubmit: (content) {},
)
```

## 兼容性

- Flutter 3.0+
- Dart 3.0+
- Android API 21+
- iOS 12.0+

## 权限配置

为了使用语音录制、相机和图片选择功能，您需要在项目的 `AndroidManifest.xml` (Android) 和 `Info.plist` (iOS) 文件中配置相应的权限。

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限录制语音消息</string>
<key>NSCameraUsageDescription</key>
<string>需要相机权限拍摄照片</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要相册权限选择照片</string>
```

## 常见问题

### Q: 如何处理权限问题？
A: 组件会自动请求所需权限。您只需要在 `onError` 回调中处理用户拒绝权限的情况，例如提示用户前往应用设置手动启用权限。

### Q: 如何禁用某些功能？
A: 通过 `ChatComposerConfig` 对象来禁用相应功能：
```dart
ChatComposer(
  config: ChatComposerConfig(
    enableVoiceRecording: false, // 禁用语音录制
    enableMoreActions: false,    // 禁用更多功能面板
    // enableCamera 属性目前在 ChatComposerConfig 中不存在，相机功能由 MoreActionItem 控制
  ),
  onSubmit: (content) {},
)
```

## 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解详细的版本更新信息。

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**注意**：本组件需要 Flutter 3.0+ 和 Dart 3.0+。
