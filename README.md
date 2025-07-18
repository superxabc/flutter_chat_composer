# Flutter Chat Composer

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 简介

Flutter Chat Composer 是一个功能丰富、高度可定制的多模态聊天输入组件，专为 Flutter 应用程序设计，旨在提供直观且流畅的用户体验。它支持文字、语音、图片和文件等多种输入方式，并具备智能自适应布局和顺畅的交互。

## 特性

- **多模态输入**：支持文字、语音、图片和文件等多种输入方式。
- **自适应高度**：文本输入区域支持自适应高度调节（2-6行）。
- **分层布局**：采用上下分层结构，输入区域和工具栏分离。
- **流畅交互**：简化的模式切换和智能的状态恢复机制。
- **统一底部动画**：无需依赖 `Scaffold.resizeToAvoidBottomInset`，即可实现系统键盘与自定义功能面板（MoreArea）之间的无缝平滑切换，并自动处理底部安全区域适配。
- **主题定制**：支持 `flat`、`clean` 预设主题和完全自定义主题。
- **语音录制**：直观的长按录制功能，支持手势识别（滑动取消）和丰富的视觉反馈（覆盖层、波点动画）。
- **错误处理**：提供全面的错误分类和用户友好的提示，涵盖网络、权限、录制和文件相关问题。
- **性能优化**：利用 `RepaintBoundary`、`AnimatedBuilder` 和防抖技术，确保动画流畅并高效更新状态。
- **SVG 图标系统**：内置精美的自定义 SVG 图标，并能自动适配主题色。
- **触觉反馈**：提供良好的用户体验。
- **权限处理**：自动检查和请求相机、麦克风、存储权限。

## 安装

将此组件添加为本地包或 Git 依赖项到您的 `pubspec.yaml` 中：

```yaml
dependencies:
  flutter_chat_composer:
    path: path/to/your/local/flutter_chat_composer_directory
    # 或者从 Git:
    # git:
    #   url: https://github.com/your-repo/flutter_chat_composer.git
    #   ref: main # 或特定分支/标签
```

添加后，运行 `flutter pub get`。

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

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Composer Example')),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('Your chat messages will appear here.'),
            ),
          ),
          ChatComposer(
            onSubmit: (content) {
              switch (content.type) {
                case ChatContentType.text:
                  print('Text message: ${content.text}');
                  // 处理文本消息提交
                  break;
                case ChatContentType.voice:
                  print('Voice message: ${content.voiceFilePath}, Duration: ${content.voiceDuration}');
                  // 处理语音消息提交
                  break;
                case ChatContentType.image:
                  print('Image message: ${content.imageFilePath}');
                  // 处理图片消息提交
                  break;
                case ChatContentType.file:
                  print('File message: ${content.filePath}');
                  // 处理文件消息提交
                  break;
              }
            },
            onModeChange: (mode) {
              print('模式切换: $mode');
            },
            onVoiceRecordingStateChange: (state) {
              print('语音录制状态: $state');
            },
            onTextChange: (text) {
              print('文本变化: $text');
            },
            onError: (error) {
              print('Chat Composer 错误: ${error.message}');
              // 根据错误类型进行处理，例如显示 SnackBar 或 Dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('错误: ${error.message}')),
              );
            },
            onStatusChange: (status) {
              print('组件状态: $status');
            },
            config: const ChatComposerConfig(
              enableVoice: true,          // 启用语音输入
              enableCamera: true,         // 启用相机功能
              enableMoreButton: true,     // 启用更多功能按钮
              enableHapticFeedback: true, // 启用触觉反馈
              maxTextLength: 500,         // 最大文本长度
              minTextLines: 2,            // 最小行数
              maxTextLines: 6,            // 最大行数
              maxVoiceDuration: 60,       // 最大语音录制时长 (秒)
            ),
            placeholder: '输入消息...',
            sendHintText: '发消息或按住说话',
            holdToTalkText: '按住 说话',
            autoFocus: false,
            enabled: true,
            debounceDelay: 300,
          ),
        ],
      ),
    );
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
  onVoiceRecordingStateChange: (VoiceRecordingState state) {},
  onTextChange: (String text) {},
  onError: (ChatInputError error) {},
  onStatusChange: (ChatInputStatus status) {},
  
  // 配置 (通过 ChatComposerConfig 对象进行配置)
  config: const ChatComposerConfig(
    maxTextLength: 1000,           // 最大文本长度
    maxVoiceDuration: 60,          // 最大语音时长(秒)
    enableVoice: true,             // 启用语音输入功能
    enableCamera: true,            // 启用相机功能
    enableMoreButton: true,        // 启用更多功能面板
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
  
  // 控制器 (可选，用于外部控制)
  // controller: ChatInputController(),
  // textController: TextEditingController(),
  // focusNode: FocusNode(),
  
  // 更多按钮点击回调
  // onMoreButtonTap: () {},
  
  // 初始文本
  // initialText: 'Hello',
  
  // 是否自动聚焦
  // autoFocus: false,
  
  // 是否启用
  // enabled: true,
  
  // 背景颜色
  // backgroundColor: Colors.grey[100],
  
  // 防抖延迟
  // debounceDelay: 300,
)
```

## 主题定制

Flutter Chat Composer 提供了三种预设主题风格和完全自定义主题的能力。

### 1. 使用预设主题风格

通过 `themeStyle` 属性选择预设主题：

```dart
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

### 3. 基于Material主题

```dart
ChatComposer(
  theme: ChatComposerTheme.fromMaterial(Theme.of(context)),
  onSubmit: (content) {},
)
```

## 功能配置

### 1. 配置对象 (ChatComposerConfig)

通过 `config` 属性传入 `ChatComposerConfig` 实例来配置组件的各项功能：

```dart
ChatComposer(
  config: const ChatComposerConfig(
    enableVoice: true,          // 启用语音输入 (默认 true)
    enableCamera: true,         // 启用相机功能 (默认 true)
    enableMoreButton: true,     // 启用更多功能按钮 (默认 true)
    enableHapticFeedback: true, // 启用触觉反馈 (默认 true)
    maxTextLength: 1000,        // 最大文本长度 (默认 1000)
    minTextLines: 2,            // 文本输入框最小行数 (默认 2)
    maxTextLines: 6,            // 文本输入框最大行数 (默认 6)
    maxVoiceDuration: 60,       // 最大语音录制时长 (秒，默认 60)
  ),
  onSubmit: (content) {},
)
```

## 外部控制器

组件支持外部控制器来实现程序化控制：

```dart
class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatInputController _chatController;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _chatController = ChatInputController();
    _textController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ... 其他内容
          ChatComposer(
            controller: _chatController,
            textController: _textController,
            focusNode: _focusNode,
            onSubmit: (content) {
              // 处理提交
            },
          ),
          // 外部控制按钮
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _chatController.switchToTextMode(),
                child: Text('切换到文本模式'),
              ),
              ElevatedButton(
                onPressed: () => _chatController.closeMoreArea(),
                child: Text('关闭更多面板'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## 错误处理

组件通过 `onError` 回调报告内部发生的错误，例如权限拒绝、录音失败等。

```dart
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
  config: const ChatComposerConfig(
    enableVoice: false,    // 禁用语音输入
    enableMoreButton: false, // 禁用更多功能面板
    enableCamera: false,   // 禁用相机功能
  ),
  onSubmit: (content) {},
)
```

### Q: 如何自定义更多面板的功能？
A: 可以通过 `onMoreButtonTap` 回调来自定义更多按钮的行为，或者监听组件内部的功能面板操作：
```dart
ChatComposer(
  onMoreButtonTap: () {
    // 自定义更多按钮点击行为
    print('更多按钮被点击');
  },
  onSubmit: (content) {
    // 处理从更多面板选择的内容
    if (content.metadata?['source'] == 'gallery') {
      print('从相册选择的图片');
    }
  },
)
```

### Q: 组件是否支持键盘适配？
A: 是的，组件有独立的键盘适配系统，无需依赖 `Scaffold.resizeToAvoidBottomInset`。它会自动处理键盘弹出时的布局调整，确保输入区域始终可见。

## 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解详细的版本更新信息。

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**注意**：本组件需要 Flutter 3.0+ 和 Dart 3.0+。
