import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/chat_input_controller.dart';
import '../theme/chat_composer_theme.dart';
import '../chat_input_types.dart';
import '../widgets/buttons/chat_button.dart';
import '../icons/svg_icons.dart';

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
  
  const InputArea({
    Key? key,
    required this.controller,
    required this.theme,
    required this.textController,
    required this.focusNode,
    this.placeholder = '发消息',
    this.sendHintText = '发消息或按住说话',
    this.holdToTalkText = '按住 说话',
    this.enabled = true,
    this.onCenterTap,
    this.onModeToggle,
    this.onCameraCapture,
    this.onMoreButtonTap,
    this.onSubmit,
  }) : super(key: key);

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> with TickerProviderStateMixin {
  late AnimationController _voiceAnimationController;
  late Animation<double> _voiceAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeListeners();
  }
  
  void _initializeAnimations() {
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _voiceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _voiceAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _initializeListeners() {
    widget.controller.addListener(_handleControllerChange);
  }
  
  void _handleControllerChange() {
    // 当切换到文本模式时，自动弹起键盘
    // 但如果MoreArea正在显示，则不自动聚焦，避免冲突
    if (widget.controller.currentMode == ChatInputMode.text && !widget.controller.showMoreArea) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.focusNode.hasFocus) {
          widget.focusNode.requestFocus();
        }
      });
    }
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _voiceAnimationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, widget.textController]),
      builder: (context, child) {
        // 根据录制状态控制动画
        if (widget.controller.isRecording) {
          _voiceAnimationController.repeat();
        } else {
          _voiceAnimationController.stop();
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 提示文案容器
            _buildHintContainer(),
            
            // 输入区域容器
            _buildInputContainer(),
          
          ],
        );
      },
    );
  }
  
  Widget _buildHintContainer() {
    return Container(
      height: 25.0,
      margin: const EdgeInsets.only(bottom: 4.0),
      child: widget.controller.showVoiceOverlay
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.5),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                widget.controller.getVoiceGestureText(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0,
                  height: 1.0,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
  
  Widget _buildInputContainer() {
    return GestureDetector(
      onTap: (widget.enabled && widget.controller.currentMode == ChatInputMode.idle) 
          ? _handleCenterTap 
          : null,
      onLongPressStart: (widget.controller.currentMode == ChatInputMode.idle || 
                          (widget.controller.currentMode == ChatInputMode.voice && 
                           !widget.controller.isRecording))
          ? _handleVoiceRecordingStart 
          : null,
      onLongPressMoveUpdate: widget.controller.isRecording 
          ? _handleVoiceRecordingUpdate 
          : null,
      onLongPressEnd: widget.controller.isRecording 
          ? _handleVoiceRecordingEnd 
          : null,
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
  
  BoxDecoration _buildVoiceOverlayDecoration() {
    final color = widget.controller.voiceGestureState == VoiceGestureState.cancelMode 
        ? widget.theme.colors.error 
        : widget.theme.colors.primary;
    
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(widget.theme.sizes.borderRadius),
    );
  }
  
  Widget _buildVoiceOverlayContent() {
    return Container(
      height: widget.theme.sizes.inputContainerHeight,
      child: Stack(
        children: [
          Opacity(
            opacity: 0.0,
            child: _buildInputContent(),
          ),
          Positioned.fill(
            child: Center(
              child: _buildWavePointAnimation(),
            ),
          ),
        ],
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
  
  Widget _buildIdleMode() {
    return Container(
      height: widget.theme.sizes.inputContainerHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildButtonLayout(),
          _buildCenterText(widget.sendHintText),
        ],
      ),
    );
  }
  
  Widget _buildTextInputMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextInputField(),
        _buildToolbar(),
      ],
    );
  }
  
  Widget _buildVoiceInputMode() {
    return Container(
      height: widget.theme.sizes.inputContainerHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildButtonLayout(),
          _buildCenterText(widget.holdToTalkText),
        ],
      ),
    );
  }
  
  Widget _buildButtonLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildModeToggleButton(),
        const Expanded(child: SizedBox.shrink()),
        _buildRightButtons(),
      ],
    );
  }
  
  Widget _buildRightButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCameraButton(),
        const SizedBox(width: 16),
        _buildMoreButton(),
      ],
    );
  }
  
  Widget _buildModeToggleButton() {
    return _buildIconButton(
      icon: widget.controller.currentMode == ChatInputMode.voice 
          ? ChatComposerSvgIcons.keyboardIcon(
              size: widget.theme.sizes.iconSize,
              color: widget.theme.colors.primary,
            )
          : ChatComposerSvgIcons.microphoneIcon(
              size: widget.theme.sizes.iconSize,
              color: widget.theme.colors.primary,
            ),
      onPressed: widget.onModeToggle,
      semanticLabel: widget.controller.currentMode == ChatInputMode.voice ? '键盘' : '麦克风',
    );
  }
  
  Widget _buildCameraButton() {
    return _buildIconButton(
      icon: ChatComposerSvgIcons.cameraIcon(
        size: widget.theme.sizes.iconSize,
        color: widget.theme.colors.primary,
      ),
      onPressed: widget.onCameraCapture,
      semanticLabel: '相机',
    );
  }
  
  Widget _buildMoreButton() {
    return _buildIconButton(
      icon: ChatComposerSvgIcons.moreIcon(
        size: widget.theme.sizes.iconSize,
        color: widget.theme.colors.primary,
      ),
      onPressed: widget.onMoreButtonTap,
      semanticLabel: '更多',
    );
  }
  
  Widget _buildSendButton() {
    final hasText = widget.textController.text.trim().isNotEmpty;
    final isEnabled = widget.enabled && hasText;
    
    return _buildIconButton(
      icon: ChatComposerSvgIcons.sendIcon(
        size: widget.theme.sizes.iconSize,
        color: isEnabled ? widget.theme.colors.primary : widget.theme.colors.disabled,
      ),
      onPressed: isEnabled ? widget.onSubmit : null,
      semanticLabel: '发送',
    );
  }
  

  
  Widget _buildIconButton({
    Widget? icon,
    IconData? materialIcon,
    required VoidCallback? onPressed,
    required String semanticLabel,
  }) {
    Widget iconWidget;
    if (icon != null) {
      iconWidget = icon;
    } else if (materialIcon != null) {
      iconWidget = Icon(materialIcon);
    } else {
      iconWidget = const Icon(Icons.help);
    }
    
    return ChatButton(
      icon: iconWidget,
      onPressed: onPressed,
      enabled: widget.enabled && onPressed != null,
      size: widget.theme.sizes.buttonSize,
      semanticLabel: semanticLabel,
      theme: widget.theme,
      showPressedState: false,
    );
  }
  
  Widget _buildCenterText(String text) {
    return Positioned.fill(
      child: Container(
        alignment: widget.controller.currentMode == ChatInputMode.idle 
            ? Alignment.centerLeft 
            : Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        margin: EdgeInsets.only(
          left: widget.controller.currentMode == ChatInputMode.idle 
              ? widget.theme.sizes.buttonSize + 8.0  // 减少左侧间距
              : 0,
          right: widget.controller.currentMode == ChatInputMode.idle 
              ? _calculateRightButtonsWidth() + 8.0   // 减少右侧间距
              : 0,
        ),
        child: Text(
          text,
          style: widget.theme.styles.hintText.copyWith(
            color: widget.controller.currentMode == ChatInputMode.voice 
                ? widget.theme.colors.primary 
                : widget.theme.colors.hint,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextInputField() {
    return Container(
      constraints: BoxConstraints(
        minHeight: widget.theme.sizes.lineHeight * 2 + 16,
        maxHeight: widget.theme.sizes.lineHeight * 6 + 24,
      ),
      child: TextField(
        controller: widget.textController,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        maxLines: 6,
        minLines: 2,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => widget.onSubmit?.call(),
        style: widget.theme.styles.inputText.copyWith(
          color: widget.theme.colors.onSurface,
        ),
        cursorColor: widget.theme.colors.primary,
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: widget.theme.styles.hintText.copyWith(
            color: widget.theme.colors.hint,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 16.0,
          ),
          counterText: "",
        ),
      ),
    );
  }
  
  Widget _buildToolbar() {
    return Container(
      height: widget.theme.sizes.inputToolbarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox.shrink(),
          const Expanded(child: SizedBox.shrink()),
          _buildMoreButton(),
          const SizedBox(width: 16),
          _buildSendButton(),
        ],
      ),
    );
  }
  
  Widget _buildWavePointAnimation() {
    return AnimatedBuilder(
      animation: _voiceAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(8, (index) {
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
  
  void _handleCenterTap() {
    widget.onCenterTap?.call();
    if (widget.controller.currentMode == ChatInputMode.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.focusNode.requestFocus();
        }
      });
    }
  }
  
  void _handleVoiceRecordingStart(LongPressStartDetails details) {
    widget.controller.startVoiceRecording();
  }
  
  void _handleVoiceRecordingUpdate(LongPressMoveUpdateDetails details) {
    widget.controller.updateVoiceGesture(details.localPosition.dy);
  }
  
  void _handleVoiceRecordingEnd(LongPressEndDetails details) {
    if (widget.controller.voiceGestureState == VoiceGestureState.recording) {
      widget.controller.finishVoiceRecording();
    } else {
      widget.controller.cancelVoiceRecording();
    }
  }
  
  double _calculateRightButtonsWidth() {
    return widget.theme.sizes.buttonSize * 2 + widget.theme.sizes.buttonGap * 2;
  }
} 