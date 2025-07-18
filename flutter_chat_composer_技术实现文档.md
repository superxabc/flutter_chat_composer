# Flutter Chat Composer 技术实现文档

## 文档说明

本文档专注于Flutter Chat Composer组件的技术实现，包含代码实现、API接口、架构设计、性能优化等开发层面的技术细节。

## 技术栈

- **Flutter**: 3.x+
- **Dart**: 3.x+
- **权限管理**: permission_handler
- **语音录制**: flutter_sound
- **图片处理**: image_picker
- **文件选择**: file_picker
- **SVG支持**: flutter_svg
- **网络监听**: connectivity_plus
- **动画系统**: Flutter Animation Framework

## 组件架构

### 主要组件结构

```
ChatComposer (StatefulWidget)
├── _ChatComposerState (状态管理 + TickerProviderStateMixin + WidgetsBindingObserver)
│   ├── ChatInputController (状态控制器)
│   ├── TextEditingController (文本输入控制)
│   ├── FocusNode (焦点管理)
│   ├── ChatComposerTheme (主题管理)
│   └── StreamSubscription (网络监听)
├── InputArea (输入区域 StatefulWidget)
│   ├── AnimationController (语音录制动画)
│   ├── 文本输入模式
│   ├── 语音录制模式  
│   ├── 空闲模式
│   └── 波点动画 (8个波点)
├── MoreArea (更多功能面板 StatelessWidget)
│   ├── 水平ListView
│   ├── 5个功能按钮
│   └── 响应式布局计算
├── ChatComposerTheme (主题系统)
│   ├── flat() 工厂方法
│   ├── clean() 工厂方法
│   ├── custom() 工厂方法
│   └── fromMaterial() 工厂方法
├── ChatInputController (状态控制器)
├── VoiceService (语音录制服务)
├── PermissionHandler (权限处理)
└── ChatErrorHandler (错误处理)
```

## 核心实现

### 1. 主组件实现

```dart
class ChatComposer extends StatefulWidget {
  // 必需回调
  final Function(ChatContent content) onSubmit;
  
  // 可选回调
  final Function(ChatInputMode mode)? onModeChange;
  final Function(VoiceRecordingState state)? onVoiceRecordingStateChange;
  final Function(String text)? onTextChange;
  final Function(ChatInputError error)? onError;
  final Function(ChatInputStatus status)? onStatusChange;
  
  // 主题风格
  final ChatThemeStyle themeStyle;
  final ChatComposerTheme? theme;
  
  // 配置参数
  final ChatComposerConfig config;
  
  // 文本配置
  final String? placeholder;
  final String sendHintText;
  final String holdToTalkText;
  
  // 控制器（可选，支持外部注入）
  final ChatInputController? controller;
  final TextEditingController? textController;
  final FocusNode? focusNode;
  
  // 更多按钮点击回调
  final VoidCallback? onMoreButtonTap;
  
  // 其他配置
  final String? initialText;
  final bool autoFocus;
  final bool enabled;
  final Color? backgroundColor;
  final int debounceDelay;

  const ChatComposer({
    Key? key,
    required this.onSubmit,
    this.themeStyle = ChatThemeStyle.flat,
    this.config = const ChatComposerConfig(),
    this.debounceDelay = 300,
    // ... 其他参数
  }) : super(key: key);
}
```

### 2. 状态管理架构

```dart
class _ChatComposerState extends State<ChatComposer> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // 核心控制器
  late ChatInputController _controller;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  
  // 主题管理
  late ChatComposerTheme _theme;
  
  // 工具类
  Timer? _debounceTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // 生命周期管理
  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _initializeTheme();
    _initializeListeners();
    _initializeConnectivity();
  }
  
  @override
  void dispose() {
    _disposeControllers();
    _disposeListeners();
    _disposeTimers();
    _disposeSubscriptions();
    super.dispose();
  }
}
```

### 3. 控制器模式实现

```dart
class ChatInputController extends ChangeNotifier {
  // 核心状态
  ChatInputMode _currentMode = ChatInputMode.idle;
  ChatInputStatus _currentStatus = ChatInputStatus.idle;
  VoiceRecordingState _voiceRecordingState = VoiceRecordingState.idle;
  VoiceGestureState _voiceGestureState = VoiceGestureState.recording;
  
  // UI状态控制
  bool _showVoiceOverlay = false;
  bool _isRecording = false;
  bool _hasMicrophonePermission = false;
  bool _showMoreArea = false;
  
  // 状态记忆
  ChatInputMode? _preRecordingMode;
  
  // 服务依赖
  final VoiceService _voiceService = VoiceService();
  
  // 配置和回调
  final bool enableHapticFeedback;
  final int maxTextLength;
  final int maxVoiceDuration;
  final Function(ChatContent content)? onSubmit;
  final Function(ChatInputMode mode)? onModeChange;
  final Function(VoiceRecordingState state)? onVoiceRecordingStateChange;
  final Function(ChatInputError error)? onError;
  final Function(ChatInputStatus status)? onStatusChange;
  
  // 核心状态管理方法
  void switchToTextMode() {
    if (_currentMode != ChatInputMode.text) {
      _currentMode = ChatInputMode.text;
      onModeChange?.call(_currentMode);
      notifyListeners();
    }
  }
  
  void switchToVoiceMode() {
    if (_currentMode != ChatInputMode.voice) {
      _currentMode = ChatInputMode.voice;
      onModeChange?.call(_currentMode);
      notifyListeners();
    }
  }
  
  void switchToIdleMode() {
    if (_currentMode != ChatInputMode.idle) {
      _currentMode = ChatInputMode.idle;
      onModeChange?.call(_currentMode);
      notifyListeners();
    }
  }
  
  // MoreArea 状态管理
  void handleMoreButtonTap() {
    _showMoreArea = !_showMoreArea;
    notifyListeners();
  }
  
  void closeMoreArea() {
    if (_showMoreArea) {
      _showMoreArea = false;
      notifyListeners();
    }
  }
  
  // 文本提交逻辑
  Future<void> submitText(String text) async {
    if (text.trim().isEmpty) {
      switchToIdleMode();
      closeMoreArea();
      return;
    }
    
    _updateStatus(ChatInputStatus.sending);
    switchToIdleMode();
    closeMoreArea();
    
    final content = ChatContent(
      type: ChatContentType.text,
      text: text.trim(),
    );
    
    try {
      await onSubmit?.call(content);
      _updateStatus(ChatInputStatus.idle);
    } catch (e) {
      _handleError(ChatInputError(
        type: ChatInputErrorType.networkError,
        message: '发送失败: $e',
        originalError: e,
      ));
      _updateStatus(ChatInputStatus.idle);
    }
  }
}
```

### 4. 输入区域实现

```dart
class InputArea extends StatefulWidget {
  final ChatInputController controller;
  final ChatComposerTheme theme;
  final TextEditingController textController;
  final FocusNode focusNode;
  final String placeholder;
  final String sendHintText;
  final String holdToTalkText;
  final bool enabled;
  final VoidCallback? onCenterTap;
  final VoidCallback? onModeToggle;
  final VoidCallback? onCameraCapture;
  final VoidCallback? onMoreButtonTap;
  final VoidCallback? onSubmit;
}

class _InputAreaState extends State<InputArea> with TickerProviderStateMixin {
  late AnimationController _voiceAnimationController;
  late Animation<double> _voiceAnimation;
  
  @override
  void initState() {
    super.initState();
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _voiceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_voiceAnimationController);
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHintContainer(),
            _buildInputContainer(),
          ],
        );
      },
    );
  }
  
  Widget _buildInputContainer() {
    return GestureDetector(
      onTap: _handleCenterTap,
      onLongPressStart: _handleVoiceRecordingStart,
      onLongPressMoveUpdate: _handleVoiceRecordingUpdate,
      onLongPressEnd: _handleVoiceRecordingEnd,
      child: Container(
        decoration: widget.controller.showVoiceOverlay 
            ? _buildVoiceOverlayDecoration()
            : widget.theme.decorations.containerDecoration,
        child: widget.controller.showVoiceOverlay 
            ? _buildVoiceOverlayContent()
            : _buildInputContent(),
      ),
    );
  }
  
  Widget _buildInputContent() {
    switch (widget.controller.currentMode) {
      case ChatInputMode.text:
        return _buildTextInputMode();
      case ChatInputMode.voice:
        return _buildVoiceInputMode();
      default:
        return _buildIdleMode();
    }
  }
}
```

### 5. 主题系统实现

```dart
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
  
  /// Flat主题 - 科技蓝边框风格
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
          border: Border.all(color: techBlue, width: 1.0),
          borderRadius: BorderRadius.circular(16.0),
        ),
        shadowDecoration: null,
      ),
    );
  }
  
  /// Clean主题 - 90%黑色无边框阴影风格
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
  
  /// Custom主题 - 完全自定义
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
          border: hasBorder ? Border.all(color: primaryColor, width: 1.0) : null,
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
  
  /// 基于Material主题创建
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
```

### 6. 波点动画实现

```dart
Widget _buildWavePointAnimation() {
  return AnimatedBuilder(
    animation: _voiceAnimation,
    builder: (context, child) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(8, (index) {
          // 为每个波点创建不同的动画相位
          final animationValue = (_voiceAnimation.value + index * 0.15) % 1.0;
          final scale = 0.4 + (sin(animationValue * 2 * pi) * 0.5 + 0.5) * 0.6;
          final opacity = 0.4 + (sin(animationValue * 2 * pi) * 0.5 + 0.5) * 0.6;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(opacity),
                ),
              ),
            ),
          );
        }),
      );
    },
  );
}
```

### 7. 键盘与功能面板的统一切换与动画实现

组件的核心亮点之一是其优雅处理软键盘与自定义功能面板（`MoreArea`）之间切换的动画方案。它不依赖于`Scaffold.resizeToAvoidBottomInset`，而是通过一套独立的、基于隐式动画的机制，实现了高度统一且性能优越的交互体验。

该方案可以解构成四个协同工作的核心组件：

1.  **`AnimatedContainer` (动画容器)**
    *   **职责**: 作为"升降机"，通过改变自身`height`属性，为下方的键盘或`MoreArea`提供占位空间，从而将上方的`InputArea`向上推。
    *   **智能变速**: 当切换目标是系统键盘时，其`duration`设置为`Duration.zero`，实现与系统动画的瞬时同步；当切换目标是`MoreArea`时，则使用主题预设的`duration`和`curve`，实现平滑的自定义动画。

2.  **`AnimatedSwitcher` (内容切换器)**
    *   **职责**: 负责在"空内容"（一个`key`为`'empty'`的`Container`）和"`MoreArea`"之间进行带动画的切换。
    *   **性能优化**: 为了避免动画启动时的卡顿，`MoreArea`和空`Container`都在`build`方法中被提前构建为`final`变量。`AnimatedSwitcher`只负责在这两个预构建的实例之间切换，消除了在动画第一帧即时构建复杂组件所带来的性能开销。

3.  **`OverflowBox` (布局约束"欺骗"器)**
    *   **职责**: 这是解决动画过程中布局异常的关键。它包裹`MoreArea`，并为其提供一个固定的、有界的`maxHeight`约束（其值等于`MoreArea`的完整高度）。
    *   **解决的问题**: 它允许`MoreArea`在`AnimatedContainer`高度从0开始增长的动画过程中，始终以其最终的、完整的尺寸进行布局，从而避免了因接收到过小的临时高度约束而导致的`RenderFlex overflowed`和`unbounded height`异常。

4.  **`ClipRect` (内容裁剪器)**
    *   **职责**: 包裹在`AnimatedContainer`内部，负责将`OverflowBox`中超出`AnimatedContainer`当前动画高度的`MoreArea`部分进行裁剪。
    *   **视觉效果**: 正是`ClipRect`的存在，使得用户看到的是`MoreArea`随着`AnimatedContainer`的扩张而平滑"滑入"或"展开"的视觉效果，而不是突然出现。

**最终实现代码结构如下**: 

```dart
// 1. 在build方法中提前构建两个切换状态的Widget
final Widget moreAreaWidget = OverflowBox(
  key: const ValueKey('more_area'),
  minHeight: 0.0,
  maxHeight: moreGridItemHeight,
  alignment: Alignment.topCenter,
  child: MoreArea(...),
);

final Widget emptyWidget = Container(
  key: const ValueKey('empty'),
  height: 0,
);

// 2. 计算底部容器高度
double bottomContainerHeight;
if (_controller.currentMode == ChatInputMode.text) {
  bottomContainerHeight = keyboardHeight;
} else if (shouldShowMoreArea) {
  bottomContainerHeight = moreGridItemHeight;
} else {
  bottomContainerHeight = 0.0;
}

// 3. 在布局中使用动画组件
Column(
  children: [
    InputArea(...),
    if (shouldShowMoreArea && _controller.currentMode != ChatInputMode.text)
      const SizedBox(height: 16.0), // 间距
    AnimatedContainer( // 动画容器
      duration: _controller.currentMode == ChatInputMode.text
          ? Duration.zero // 文本模式跟随键盘，无动画延迟
          : _theme.styles.animationDuration, // 其他模式使用主题动画时长
      curve: Curves.decelerate,
      height: bottomContainerHeight,
      child: ClipRect( // 裁剪器
        child: AnimatedSwitcher( // 内容切换器
          duration: _controller.currentMode == ChatInputMode.text
              ? Duration.zero
              : _theme.styles.animationDuration,
          switchInCurve: Curves.decelerate,
          switchOutCurve: Curves.decelerate,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0), // 从下方开始
                end: Offset.zero, // 滑到正常位置
              ).animate(animation),
              child: child,
            );
          },
          child: shouldShowMoreArea && _controller.currentMode != ChatInputMode.text
              ? moreAreaWidget : emptyWidget, // 使用预构建的Widget
        ),
      ),
    ),
  ],
)
```

这个方案通过职责分离和精巧的组件组合，将**容器的视觉动画**与**内容的实际布局**彻底解耦，最终实现了稳定、流畅且高性能的切换效果。

### 8. MoreArea响应式布局

```dart
class MoreArea extends StatelessWidget {
  final ChatComposerTheme theme;
  final Function(String action) onActionSelected;
  final double itemContentWidth;
  final double moreAreaListViewPadding;
  final double itemSpacing;

  @override
  Widget build(BuildContext context) {
    final List<_MoreItem> items = [
      _MoreItem(icon: Icons.photo_library_outlined, label: '相册', onTap: () => onActionSelected('album')),
      _MoreItem(icon: Icons.folder_outlined, label: '文件', onTap: () => onActionSelected('file')),
      _MoreItem(icon: Icons.scanner_outlined, label: '扫描', onTap: () => onActionSelected('scan')),
      _MoreItem(icon: Icons.call_outlined, label: '通话', onTap: () => onActionSelected('call')),
      _MoreItem(icon: Icons.more_horiz_outlined, label: '更多', onTap: () => onActionSelected('more')),
    ];

    return Container(
      color: Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        padding: EdgeInsets.only(left: moreAreaListViewPadding, right: moreAreaListViewPadding),
        itemBuilder: (context, index) {
          return SizedBox(
            width: itemContentWidth,
            child: _MoreGridItem(
              item: items[index],
              theme: theme,
              itemSize: itemContentWidth,
            ),
          );
        },
        separatorBuilder: (context, index) {
          return SizedBox(width: itemSpacing);
        },
      ),
    );
  }
}
```

## 数据类型定义

### 1. 核心枚举

```dart
enum ChatInputMode {
  idle,    // 空闲状态
  text,    // 文字输入模式
  voice,   // 语音输入模式
}

enum ChatInputStatus {
  idle,       // 空闲状态
  inputting,  // 输入中
  sending,    // 发送中
  processing, // 处理中
}

enum VoiceRecordingState {
  idle,       // 空闲
  recording,  // 录制中
  paused,     // 暂停
  completed,  // 完成
  cancelled,  // 取消
  error,      // 错误
}

enum VoiceGestureState {
  recording,   // 正常录制
  cancelMode,  // 取消模式
}

enum ChatContentType {
  text,   // 文本消息
  voice,  // 语音消息
  image,  // 图片消息
  file,   // 文件消息
}

enum ChatThemeStyle {
  flat,   // 扁平风格主题
  clean,  // 简洁风格主题
  custom, // 自定义主题
}
```

### 2. 内容类型

```dart
class ChatContent {
  final ChatContentType type;
  final String? text;
  final String? voiceFilePath;
  final Duration? voiceDuration;
  final String? imageFilePath;
  final String? filePath;
  final Map<String, dynamic>? metadata;
  
  const ChatContent({
    required this.type,
    this.text,
    this.voiceFilePath,
    this.voiceDuration,
    this.imageFilePath,
    this.filePath,
    this.metadata,
  });
}

class ChatInputError {
  final ChatInputErrorType type;
  final String message;
  final dynamic originalError;
  final ChatPermissionType? permissionType;
  final int? maxFileSize;
  final int? actualFileSize;
  
  const ChatInputError({
    required this.type,
    required this.message,
    this.originalError,
    this.permissionType,
    this.maxFileSize,
    this.actualFileSize,
  });
}
```

### 3. 配置类型

```dart
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
```

## 服务层实现

### 1. 语音服务

```dart
class VoiceService {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  String? _currentRecordingPath;
  StreamSubscription? _recorderSubscription;
  StreamSubscription? _playerSubscription;
  Duration? _currentRecordingDuration;

  VoiceService() {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _init();
  }

  Future<void> _init() async {
    await _recorder!.openRecorder();
    _isRecorderInitialized = true;
    await _player!.openPlayer();
    _isPlayerInitialized = true;
  }

  Future<String> startRecording() async {
    if (!_isRecorderInitialized) {
      throw Exception('录音器未初始化');
    }

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('麦克风权限未授予');
    }
    
    // 实现具体录音逻辑
  }
}
```

### 2. 权限处理

```dart
class PermissionHandler {
  static Future<bool> checkMicrophonePermission() async {
    final permission = await Permission.microphone.status;
    return permission.isGranted;
  }
  
  static Future<bool> requestMicrophonePermission() async {
    final permission = await Permission.microphone.request();
    return permission.isGranted;
  }
  
  static Future<bool> checkCameraPermission() async {
    final permission = await Permission.camera.status;
    return permission.isGranted;
  }
  
  static Future<bool> requestCameraPermission() async {
    final permission = await Permission.camera.request();
    return permission.isGranted;
  }
}
```

### 3. 错误处理

```dart
class ChatErrorHandler {
  static void handleError(
    BuildContext context,
    ChatInputError error, {
    VoidCallback? onRetry,
    bool showDialog = false,
    Duration? snackBarDuration,
  }) {
    switch (error.type) {
      case ChatInputErrorType.networkError:
        _handleNetworkError(context, error, onRetry, showDialog, snackBarDuration);
        break;
      case ChatInputErrorType.permissionDenied:
        _handlePermissionError(context, error, showDialog);
        break;
      case ChatInputErrorType.recordingFailed:
        _handleRecordingError(context, error, showDialog, snackBarDuration);
        break;
      case ChatInputErrorType.fileTooLarge:
        _handleFileSizeError(context, error, showDialog, snackBarDuration);
        break;
      case ChatInputErrorType.validationError:
        _handleValidationError(context, error, showDialog, snackBarDuration);
        break;
      case ChatInputErrorType.unknown:
        _handleUnknownError(context, error, showDialog, snackBarDuration);
        break;
    }
  }
  
  static void _handleNetworkError(/* ... */) {
    _showToast(context, error.message, snackBarDuration);
  }
  
  static void _handlePermissionError(/* ... */) {
    if (showDialog) {
      _showPermissionDialog(context, error);
    } else {
      _showToast(context, error.message, snackBarDuration);
    }
  }
}
```

## 图标系统

### SVG图标实现

```dart
class ChatComposerSvgIcons {
  static const String _basePath = 'assets/icons/';
  
  static const String microphone = '${_basePath}custom_voice.svg';
  static const String keyboard = '${_basePath}custom_keyboard.svg';
  static const String send = '${_basePath}custom_send.svg';
  static const String camera = '${_basePath}custom_camera.svg';
  static const String more = '${_basePath}custom_more.svg';
  static const String sound = '${_basePath}custom_sound.svg';
  
  static Widget microphoneIcon({double? size, Color? color}) {
    return SvgIcon(
      assetPath: microphone,
      size: size,
      color: color,
      usesCurrentColor: false,
    );
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
  
  // 其他图标方法...
}

class SvgIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;
  final bool usesCurrentColor;
  
  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24;
    
    try {
      return SvgPicture.asset(
        assetPath,
        package: 'flutter_chat_composer',
        width: iconSize,
        height: iconSize,
        colorFilter: (!usesCurrentColor && color != null) 
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (BuildContext context) {
          return Icon(_getFallbackIcon(assetPath), size: iconSize, color: color);
        },
      );
    } catch (e) {
      return Icon(_getFallbackIcon(assetPath), size: iconSize, color: color);
    }
  }
}
```

## 性能优化

### 1. 渲染性能

```dart
// 动画区域隔离
Widget _buildWavePointAnimation() {
  return RepaintBoundary(
    child: AnimatedBuilder(
      animation: _voiceAnimation,
      builder: (context, child) {
        // 波点动画实现
      },
    ),
  );
}

// 状态更新优化
@override
Widget build(BuildContext context) {
  return AnimatedBuilder(
    animation: widget.controller,
    builder: (context, child) {
      // 只有控制器状态变化时才重建
    },
  );
}
```

### 2. Widget选择优化

组件在设计时遵循了Flutter性能最佳实践：

**SizedBox vs Container优化：**
```dart
// ✅ 优化后 - 仅需要尺寸约束时使用SizedBox
Widget _buildIdleMode() {
  return SizedBox(
    height: widget.theme.sizes.inputContainerHeight,
    child: Stack(...),
  );
}

// ❌ 避免 - 不要为简单尺寸约束使用Container
Widget _buildIdleMode() {
  return Container(
    height: widget.theme.sizes.inputContainerHeight,
    child: Stack(...),
  );
}
```

**Const构造函数优化：**
```dart
// 所有可能的地方都使用const构造函数
const ChatContent(
  type: ChatContentType.image,
  imageFilePath: 'path/to/image.jpg',
  metadata: {'source': 'gallery'},
);

const TextStyle(
  color: Colors.white,
  fontSize: 16,
  fontWeight: FontWeight.w500,
);
```

### 3. 内存管理

```dart
@override
void dispose() {
  // 控制器清理
  _disposeControllers();
  
  // 监听器清理
  WidgetsBinding.instance.removeObserver(this);
  _controller.removeListener(_handleControllerChange);
  
  // 定时器清理
  _debounceTimer?.cancel();
  
  // 订阅清理
  _connectivitySubscription?.cancel();
  
  super.dispose();
}
```

### 4. 防抖处理

```dart
void _handleTextChange() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: widget.debounceDelay), () {
    widget.onTextChange?.call(_textController.text);
  });
}
```

## 使用示例

### 1. 基本使用

```dart
ChatComposer(
  onSubmit: (content) {
    switch (content.type) {
      case ChatContentType.text:
        handleTextMessage(content.text!);
        break;
      case ChatContentType.voice:
        handleVoiceMessage(content.voiceFilePath!, content.voiceDuration!);
        break;
      case ChatContentType.image:
        handleImageMessage(content.imageFilePath!);
        break;
      case ChatContentType.file:
        handleFileMessage(content.filePath!);
        break;
    }
  },
  onError: (error) {
    showErrorDialog(error.message);
  },
)
```

### 2. 高级配置

```dart
ChatComposer(
  themeStyle: ChatThemeStyle.flat,
  config: ChatComposerConfig(
    enableVoice: true,
    enableCamera: true,
    enableMoreButton: true,
    enableHapticFeedback: true,
    maxTextLength: 1000,
    minTextLines: 2,
    maxTextLines: 6,
    maxVoiceDuration: 60,
  ),
  placeholder: '请输入消息',
  sendHintText: '发消息或按住说话',
  holdToTalkText: '按住 说话',
  autoFocus: false,
  enabled: true,
  debounceDelay: 300,
  onSubmit: (content) => handleSubmit(content),
  onModeChange: (mode) => handleModeChange(mode),
  onTextChange: (text) => handleTextChange(text),
  onError: (error) => handleError(error),
)
```

### 3. 自定义主题

```dart
ChatComposer(
  themeStyle: ChatThemeStyle.custom,
  theme: ChatComposerTheme.custom(
    primaryColor: Colors.blue,
    backgroundColor: Colors.grey[100]!,
    surfaceColor: Colors.white,
    hasBorder: true,
    hasShadow: false,
    borderRadius: 16.0,
  ),
  // ...
)
```

## 最佳实践

### 1. 错误处理

```dart
ChatComposer(
  onSubmit: (content) async {
    try {
      await sendMessage(content);
    } catch (e) {
      showErrorSnackBar('发送失败，请重试');
    }
  },
  onError: (error) {
    switch (error.type) {
      case ChatInputErrorType.permissionDenied:
        showPermissionDialog();
        break;
      case ChatInputErrorType.fileTooLarge:
        showFileSizeDialog();
        break;
      default:
        showGenericError(error.message);
    }
  },
)
```

### 2. 状态管理

```dart
// 使用外部控制器
final controller = ChatInputController();

ChatComposer(
  controller: controller,
  onSubmit: (content) {
    // 处理提交
  },
)

// 在需要时控制组件状态
controller.switchToTextMode();
controller.closeMoreArea();
```

### 3. 性能优化

```dart
// 使用防抖减少频繁回调
ChatComposer(
  debounceDelay: 300,
  onTextChange: (text) {
    updateDraftMessage(text);
  },
)

// 合理使用自动聚焦
ChatComposer(
  autoFocus: shouldAutoFocus,
  // ...
)
```

## 总结

Flutter Chat Composer组件提供了完整的多模态输入解决方案，具有以下技术特点：

### 架构优势
- **分层设计**：清晰的组件分层和职责划分
- **控制器模式**：集中的状态管理和外部控制支持
- **响应式布局**：基于屏幕尺寸的动态布局计算
- **独立键盘适配**：不依赖外部Scaffold的键盘处理

### 性能特点
- **动画优化**：RepaintBoundary隔离和精确的重建控制
- **内存管理**：完整的dispose机制和资源清理
- **防抖处理**：减少频繁的状态更新和回调
- **懒加载**：按需初始化和延迟加载

### 扩展性
- **主题系统**：完整的主题定制和运行时切换
- **回调机制**：丰富的事件回调和状态监听
- **服务注入**：支持外部服务的注入和替换
- **错误处理**：分类的错误处理和用户友好的提示

### 代码质量
- **零警告**：通过Flutter Analyze全面检查，无任何代码质量警告
- **性能优化**：使用SizedBox替代Container进行空白布局，优化渲染性能
- **Const优化**：所有可能的构造函数都使用const关键字，减少重建开销
- **内存管理**：完整的dispose机制，避免内存泄漏
- **代码简洁**：移除了所有演示代码、调试语句和未使用的类型定义

这个组件为Flutter应用提供了专业级的聊天输入体验，适合各种聊天场景的应用需求。 