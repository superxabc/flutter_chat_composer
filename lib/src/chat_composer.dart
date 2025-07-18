import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

import 'widgets/more_area.dart';
import 'controllers/chat_input_controller.dart';
import 'widgets/input_area.dart';

import 'theme/chat_composer_theme.dart';
import 'utils/error_handler.dart';
import 'chat_input_types.dart';

/// 重构后的聊天组件
class ChatComposer extends StatefulWidget {
  /// 必需回调 - 内容提交
  final Function(ChatContent content) onSubmit;
  
  /// 可选回调
  final Function(ChatInputMode mode)? onModeChange;
  final Function(VoiceRecordingState state)? onVoiceRecordingStateChange;
  final Function(String text)? onTextChange;
  final Function(ChatInputError error)? onError;
  final Function(ChatInputStatus status)? onStatusChange;
  
  /// 主题风格
  final ChatThemeStyle themeStyle;
  
  /// 自定义主题（当themeStyle为custom时使用）
  final ChatComposerTheme? theme;
  
  /// 配置
  final ChatComposerConfig config;
  
  /// 文本配置
  final String? placeholder;
  final String sendHintText;
  final String holdToTalkText;
  
  /// 控制器（可选，用于外部控制）
  final ChatInputController? controller;
  
  /// 文本控制器（可选）
  final TextEditingController? textController;
  
  /// 焦点节点（可选）
  final FocusNode? focusNode;
  
  /// 更多按钮点击回调
  final VoidCallback? onMoreButtonTap;
  
  /// 初始文本
  final String? initialText;
  
  /// 是否自动聚焦
  final bool autoFocus;
  
  /// 是否启用
  final bool enabled;
  
  /// 背景颜色（支持纯色或透明）
  final Color? backgroundColor;
  
  /// 防抖延迟
  final int debounceDelay;

  const ChatComposer({
    Key? key,
    required this.onSubmit,
    this.onModeChange,
    this.onVoiceRecordingStateChange,
    this.onTextChange,
    this.onError,
    this.onStatusChange,
    this.themeStyle = ChatThemeStyle.flat,
    this.theme,
    this.config = const ChatComposerConfig(),
    this.placeholder,
    this.sendHintText = '发消息或按住说话',
    this.holdToTalkText = '按住 说话',
    this.controller,
    this.textController,
    this.focusNode,
    this.onMoreButtonTap,
    this.initialText,
    this.autoFocus = false,
    this.enabled = true,
    this.backgroundColor,
    this.debounceDelay = 300,
  }) : super(key: key);

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  late ChatInputController _controller;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  
  late ChatComposerTheme _theme;
  
  Timer? _debounceTimer;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  


  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _initializeTheme();

    _initializeListeners();
    _initializeConnectivity();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeTheme();
  }
  
  @override
  void didUpdateWidget(ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeStyle != widget.themeStyle ||
        oldWidget.theme != widget.theme) {
      _initializeTheme();
    }
  }
  
  void _initializeComponents() {
    _controller = widget.controller ?? ChatInputController(
      enableHapticFeedback: widget.config.enableHapticFeedback,
      maxTextLength: widget.config.maxTextLength,
      maxVoiceDuration: widget.config.maxVoiceDuration,
      onSubmit: widget.onSubmit,
      onModeChange: widget.onModeChange,
      onVoiceRecordingStateChange: widget.onVoiceRecordingStateChange,
      onError: _handleError,
      onStatusChange: widget.onStatusChange,
    );
    
    _textController = widget.textController ?? TextEditingController(
      text: widget.initialText,
    );
    
    _focusNode = widget.focusNode ?? FocusNode();
  }
  
  void _initializeTheme() {
    if (widget.theme != null) {
      _theme = widget.theme!;
    } else {
      switch (widget.themeStyle) {
        case ChatThemeStyle.flat:
          _theme = ChatComposerTheme.flat();
          break;
        case ChatThemeStyle.clean:
          _theme = ChatComposerTheme.clean();
          break;
        case ChatThemeStyle.custom:
          _theme = ChatComposerTheme.flat(); // 默认使用flat
          break;
      }
    }
    
    // 应用背景色覆盖
    if (widget.backgroundColor != null) {
      _theme = ChatComposerTheme.custom(
        primaryColor: _theme.colors.primary,
        backgroundColor: widget.backgroundColor!,
        surfaceColor: _theme.colors.surface,
        hasBorder: widget.themeStyle == ChatThemeStyle.flat,
        hasShadow: widget.themeStyle == ChatThemeStyle.clean,
      );
    }
  }
  

  
  void _initializeListeners() {
    WidgetsBinding.instance.addObserver(this);
    _textController.addListener(_handleTextChange);
    _focusNode.addListener(_handleFocusChange);
    
    _controller.addListener(_handleControllerChange);
    
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }
  
  void _initializeConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        if (result == ConnectivityResult.none) {
          _showNetworkError();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused) {
      if (_controller.isRecording) {
        _controller.cancelVoiceRecording();
      }
    }
  }
  
  @override
  void dispose() {
    _disposeControllers();

    _disposeListeners();
    _disposeTimers();
    _disposeSubscriptions();
    super.dispose();
  }
  
  void _disposeControllers() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.textController == null) {
    _textController.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
  }
  

  
  void _disposeListeners() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleControllerChange);
  }
  
  void _disposeTimers() {
    _debounceTimer?.cancel();
  }
  
  void _disposeSubscriptions() {
    _connectivitySubscription?.cancel();
  }
  
  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // Calculate MoreArea's dynamic height
    final double screenWidth = MediaQuery.of(context).size.width;
    final double chatComposerHorizontalPadding = _theme.sizes.containerInset.horizontal;
    final double availableWidthForMoreArea = screenWidth - chatComposerHorizontalPadding;

    const double moreAreaListViewPadding = 0.0;
    const double itemSpacing = 16.0;
    const int itemCount = 5;

    final double widthForItemsAndInternalSpacing = availableWidthForMoreArea - (2 * moreAreaListViewPadding);
    final double itemContentWidth = (widthForItemsAndInternalSpacing - (itemCount - 1) * itemSpacing) / itemCount;
    
    final double textHeight = 11.0 * 1.2;
    final double safetyMargin = 6.0;
    final double moreGridItemHeight = itemContentWidth + 6.0 + textHeight + safetyMargin;
    
    final bool shouldShowMoreArea = _controller.showMoreArea;

    // 提前构建MoreArea和空容器，避免在AnimatedSwitcher中即时构建，并保持代码一致性
    final Widget moreAreaWidget = OverflowBox(
      key: const ValueKey('more_area'),
      minHeight: 0.0,
      maxHeight: moreGridItemHeight,
      alignment: Alignment.topCenter,
      child: MoreArea(
        theme: _theme,
        onActionSelected: (action) {
          _handleMoreAreaAction(action);
        },
        itemContentWidth: itemContentWidth,
        moreAreaListViewPadding: moreAreaListViewPadding,
        itemSpacing: itemSpacing,
      ),
    );

    final Widget emptyWidget = Container(
      key: const ValueKey('empty'),
      height: 0,
    );
    
    // 计算底部容器的总高度
    double bottomContainerHeight;
    if (_controller.currentMode == ChatInputMode.text) {
      // 文本模式：显示键盘高度
      bottomContainerHeight = keyboardHeight;
    } else if (shouldShowMoreArea) {
      // idle/voice模式且显示MoreArea：仅为MoreArea的高度
      bottomContainerHeight = moreGridItemHeight;
    } else {
      // idle/voice模式且不显示MoreArea：无额外高度
      bottomContainerHeight = 0.0;
    }

    return Container(
      color: _theme.colors.background,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: _theme.sizes.containerInset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputArea(
                controller: _controller,
                textController: _textController,
                focusNode: _focusNode,
                theme: _theme,
                placeholder: widget.placeholder ?? '请输入消息',
                sendHintText: widget.sendHintText,
                holdToTalkText: widget.holdToTalkText,
                onCenterTap: _handleCenterTap,
                onModeToggle: _handleModeToggle,
                onCameraCapture: _handleCameraCapture,
                onMoreButtonTap: _handleMoreButtonTap,
                onSubmit: _handleSubmit,
                enabled: widget.enabled,
              ),
              // 仅在MoreArea显示时才添加间距
              if (shouldShowMoreArea && _controller.currentMode != ChatInputMode.text)
                const SizedBox(height: 16.0),
              // 统一的底部动画容器
              AnimatedContainer(
                duration: _controller.currentMode == ChatInputMode.text
                    ? Duration.zero // 文本模式跟随键盘，无动画延迟
                    : _theme.styles.animationDuration, // 其他模式使用主题动画时长
                curve: Curves.decelerate, // 统一使用减速曲线，以获得更和谐的动画效果
                height: bottomContainerHeight,
                child: ClipRect(
                  child: AnimatedSwitcher(
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
                        ? moreAreaWidget
                        : emptyWidget, // 空容器，但保持动画连续性
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 事件处理方法
  void _handleCenterTap() {
    if (!widget.enabled) return;
    _controller.switchToTextMode();
  }
  
  void _handleModeToggle() {
    if (!widget.enabled) return;
    
    switch (_controller.currentMode) {
      case ChatInputMode.idle:
        _controller.switchToVoiceMode();
        break;
      case ChatInputMode.text:
        _controller.switchToVoiceMode();
        break;
      case ChatInputMode.voice:
        _controller.switchToIdleMode();
        break;
    }
  }
  
  Future<void> _handleCameraCapture() async {
    if (!widget.enabled) return;
    
    try {
      // 这里实现相机功能，可以选择拍照或从相册选择
      // 为了演示，我们创建一个简单的选择对话框
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择图片'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        ),
      );
      
      if (action != null) {
        // 这里可以调用相机或相册功能
        // 示例：创建一个图片内容对象
        final content = ChatContent(
          type: ChatContentType.image,
          imageFilePath: 'path/to/selected/image.jpg', // 实际使用时替换为真实路径
          metadata: {'source': action},
        );
        
        // 提交图片内容
        widget.onSubmit(content);
      }
    } catch (e) {
      _handleError(ChatInputError(
        type: ChatInputErrorType.unknown,
        message: '相机功能出错: $e',
        originalError: e,
      ));
    }
  }

  void _handleMoreButtonTap() {
    if (!widget.enabled) return;

    // 检查是否处于文本输入模式
    if (_controller.currentMode == ChatInputMode.text) {
      // 如果处于文本输入模式，先退出文本输入模式并收起键盘
      // MoreArea保持当前状态（应该是展示状态）
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
      _controller.switchToIdleMode();
    } else {
      // 如果没有处于文本输入模式，直接根据MoreArea的展开/关闭状态进行取反操作
      _controller.handleMoreButtonTap();
      
      // 如果MoreArea现在是可见的，确保键盘收起
      if (_controller.showMoreArea) {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      }
    }
    
    widget.onMoreButtonTap?.call();
  }
  
  void _handleSubmit() {
    if (!widget.enabled) return;
    
    final text = _textController.text;
    
    // 使用控制器的提交逻辑
    _controller.submitText(text);
    
    // 清空文本控制器
    _textController.clear();

  }

  void _handleTextChange() {
    final text = _textController.text;
    
    // 防抖处理
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceDelay), () {
      widget.onTextChange?.call(text);
    });
  }
  
  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      // 如果MoreArea显示，不执行任何模式切换，保持当前状态
      if (_controller.showMoreArea) {
        return;
      }
      
      // 如果MoreArea未显示且当前不是文本模式，则切换到文本模式
      if (_controller.currentMode != ChatInputMode.text) {
        _controller.switchToTextMode();
      }
    } else {
      // 如果焦点丢失且MoreArea未显示，且当前是文本模式，则切换回idle模式
      if (!_controller.showMoreArea && _controller.currentMode == ChatInputMode.text) {
        _controller.switchToIdleMode();
      }
    }
  }
  
  void _handleControllerChange() {
    setState(() {
    });
  }
  
  void _handleError(ChatInputError error) {
    ChatErrorHandler.handleError(
      context,
      error,
      onRetry: _getRetryCallback(error),
    );
    
    widget.onError?.call(error);
  }
  
  VoidCallback? _getRetryCallback(ChatInputError error) {
    // 根据错误类型提供重试回调
    switch (error.type) {
      case ChatInputErrorType.networkError:
        return () {
          // 重试网络操作
          _handleSubmit();
        };
      case ChatInputErrorType.permissionDenied:
        return () {
        };
      default:
        return null;
    }
  }
  
  void _showNetworkError() {
    if (!mounted) return;
    
    _handleError(const ChatInputError(
      type: ChatInputErrorType.networkError,
      message: '网络连接已断开',
    ));
  }

  void _handleMoreAreaAction(String action) {
    switch (action) {
      case 'album':
        _handleGallerySelection();
        break;
      case 'file':
        _handleFileSelection();
        break;
      case 'scan':
        _handleScanFunction();
        break;
      case 'call':
        _handleCallFunction();
        break;
      case 'more':
        _handleMoreFunction();
        break;
      default:
        print('Unknown action: $action');
    }
  }
  
  Future<void> _handleGallerySelection() async {
    try {
      // 从相册选择图片的逻辑
      final content = ChatContent(
        type: ChatContentType.image,
        imageFilePath: 'path/to/gallery/image.jpg',
        metadata: {'source': 'gallery'},
      );
      widget.onSubmit(content);
    } catch (e) {
      _handleError(ChatInputError(
        type: ChatInputErrorType.unknown,
        message: '选择图片失败: $e',
        originalError: e,
      ));
    }
  }
  
  Future<void> _handleFileSelection() async {
    try {
      // 文件选择逻辑
      final content = ChatContent(
        type: ChatContentType.file,
        filePath: 'path/to/selected/file.pdf',
        metadata: {'source': 'file_picker'},
      );
      widget.onSubmit(content);
    } catch (e) {
      _handleError(ChatInputError(
        type: ChatInputErrorType.unknown,
        message: '选择文件失败: $e',
        originalError: e,
      ));
    }
  }
  
  void _handleScanFunction() {
    // 扫描功能逻辑
    _showToast('扫描功能开发中');
  }
  
  void _handleCallFunction() {
    // 通话功能逻辑
    _showToast('通话功能开发中');
  }
  
  void _handleMoreFunction() {
    // 更多功能逻辑
    _showToast('更多功能开发中');
  }
  
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(16.0),
      ),
    );
  }
} 
