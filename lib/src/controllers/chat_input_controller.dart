import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../chat_input_types.dart';
import '../services/voice_service.dart';
import '../services/permission_handler.dart';

class ChatInputController extends ChangeNotifier {
  ChatInputMode _currentMode = ChatInputMode.idle;
  ChatInputStatus _currentStatus = ChatInputStatus.idle;
  VoiceRecordingState _voiceRecordingState = VoiceRecordingState.idle;
  VoiceGestureState _voiceGestureState = VoiceGestureState.recording;

  bool _showVoiceOverlay = false;
  bool _isRecording = false;
  bool _hasMicrophonePermission = false;
  bool _showMoreArea = false;

  ChatInputMode? _preRecordingMode;

  final VoiceService _voiceService = VoiceService();

  final bool enableHapticFeedback;
  final int maxTextLength;
  final int maxVoiceDuration;

  final Function(ChatContent content)? onSubmit;
  final Function(ChatInputMode mode)? onModeChange;
  final Function(VoiceRecordingState state)? onVoiceRecordingStateChange;
  final Function(ChatInputError error)? onError;
  final Function(ChatInputStatus status)? onStatusChange;

  ChatInputController({
    this.enableHapticFeedback = true,
    this.maxTextLength = 1000,
    this.maxVoiceDuration = 60,
    this.onSubmit,
    this.onModeChange,
    this.onVoiceRecordingStateChange,
    this.onError,
    this.onStatusChange,
  }) {
    _initializeController();
  }

  ChatInputMode get currentMode => _currentMode;
  ChatInputStatus get currentStatus => _currentStatus;
  VoiceRecordingState get voiceRecordingState => _voiceRecordingState;
  VoiceGestureState get voiceGestureState => _voiceGestureState;
  bool get showVoiceOverlay => _showVoiceOverlay;
  bool get isRecording => _isRecording;
  bool get hasMicrophonePermission => _hasMicrophonePermission;
  bool get showMoreArea => _showMoreArea;

  void _initializeController() {
    _checkMicrophonePermission();
  }

  Future<void> _checkMicrophonePermission() async {
    try {
      final hasPermission = await PermissionHandler.checkPermission(
        PermissionType.microphone,
      );
      _hasMicrophonePermission = hasPermission;
      notifyListeners();
    } catch (e) {
      _hasMicrophonePermission = false;
      notifyListeners();
    }
  }

  void switchToTextMode() {
    if (_currentMode == ChatInputMode.text) return;

    _currentMode = ChatInputMode.text;
    _showVoiceOverlay = false;

    // 进入文本模式时自动展示MoreArea
    _showMoreArea = true;

    notifyListeners();
    onModeChange?.call(_currentMode);
  }

  void switchToVoiceMode() {
    if (_currentMode == ChatInputMode.voice) return;

    _currentMode = ChatInputMode.voice;
    _showVoiceOverlay = false;

    notifyListeners();
    onModeChange?.call(_currentMode);
  }

  void switchToIdleMode() {
    if (_currentMode == ChatInputMode.idle) return;

    _currentMode = ChatInputMode.idle;
    _showVoiceOverlay = false;

    notifyListeners();
    onModeChange?.call(_currentMode);
  }

  void restorePreRecordingState() {
    final targetMode = _preRecordingMode ?? ChatInputMode.idle;

    switch (targetMode) {
      case ChatInputMode.idle:
        switchToIdleMode();
        break;
      case ChatInputMode.voice:
        switchToVoiceMode();
        break;
      case ChatInputMode.text:
        switchToIdleMode();
        break;
    }

    _preRecordingMode = null;
  }

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

  Future<void> submitText(String text) async {
    if (text.trim().isEmpty) {
      // 空内容时：退出编辑模式 + 关闭MoreArea
      switchToIdleMode();
      closeMoreArea();
      return;
    }

    _updateStatus(ChatInputStatus.sending);

    // 立即切换状态，不等待发送完成
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

  Future<void> startVoiceRecording() async {
    if (!_hasMicrophonePermission) {
      await _requestMicrophonePermission();
      return;
    }

    try {
      _preRecordingMode = _currentMode;
      _isRecording = true;
      _showVoiceOverlay = true;
      _voiceRecordingState = VoiceRecordingState.recording;
      _voiceGestureState = VoiceGestureState.recording;

      notifyListeners();

      await _voiceService.startRecording();

      if (enableHapticFeedback) {
        HapticFeedback.heavyImpact();
      }

      onVoiceRecordingStateChange?.call(_voiceRecordingState);
    } catch (e) {
      _handleError(ChatInputError(
        type: ChatInputErrorType.recordingFailed,
        message: '开始录音失败: $e',
        originalError: e,
      ));
    }
  }

  void updateVoiceGesture(double dy) {
    if (!_isRecording) return;

    const threshold = 50.0;
    VoiceGestureState newGestureState;

    if (dy < -threshold || dy > threshold) {
      newGestureState = VoiceGestureState.cancelMode;
    } else {
      newGestureState = VoiceGestureState.recording;
    }

    if (_voiceGestureState != newGestureState) {
      _voiceGestureState = newGestureState;
      notifyListeners();

      if (enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> finishVoiceRecording() async {
    if (!_isRecording) return;

    try {
      _isRecording = false;
      _showVoiceOverlay = false;
      _voiceRecordingState = VoiceRecordingState.completed;

      notifyListeners();

      final recordingResult = await _voiceService.stopRecording();

      if (recordingResult.duration.inSeconds < 1) {
        if (enableHapticFeedback) {
          HapticFeedback.heavyImpact();
        }

        _handleError(const ChatInputError(
          type: ChatInputErrorType.recordingFailed,
          message: '录音时间太短',
        ));
        return;
      }

      if (enableHapticFeedback) {
        HapticFeedback.mediumImpact();
      }

      final content = ChatContent(
        type: ChatContentType.voice,
        voiceFilePath: recordingResult.filePath,
        voiceDuration: recordingResult.duration,
        metadata: {
          'format': 'aac',
          'duration': recordingResult.duration.inSeconds,
          'fileSize': recordingResult.fileSize,
        },
      );

      try {
        await onSubmit?.call(content);
        restorePreRecordingState();
      } catch (submitError) {
        _handleError(ChatInputError(
          type: ChatInputErrorType.networkError,
          message: '发送语音失败: $submitError',
          originalError: submitError,
        ));
      }

      onVoiceRecordingStateChange?.call(_voiceRecordingState);
    } catch (e) {
      _handleError(ChatInputError(
        type: ChatInputErrorType.recordingFailed,
        message: '录音完成失败: $e',
        originalError: e,
      ));
    }
  }

  Future<void> cancelVoiceRecording() async {
    if (!_isRecording) return;

    try {
      _isRecording = false;
      _showVoiceOverlay = false;
      _voiceRecordingState = VoiceRecordingState.cancelled;

      notifyListeners();

      await _voiceService.cancelRecording();

      if (enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }

      restorePreRecordingState();
      onVoiceRecordingStateChange?.call(_voiceRecordingState);
    } catch (e) {
      _handleError(ChatInputError(
        type: ChatInputErrorType.recordingFailed,
        message: '取消录音失败: $e',
        originalError: e,
      ));
    }
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      final hasPermission = await PermissionHandler.requestPermission(
        PermissionType.microphone,
      );

      _hasMicrophonePermission = hasPermission;
      notifyListeners();

      if (!hasPermission) {
        _handleError(const ChatInputError(
          type: ChatInputErrorType.permissionDenied,
          message: '麦克风权限被拒绝',
          permissionType: ChatPermissionType.microphone,
        ));
      }
    } catch (e) {
      _handleError(ChatInputError(
        type: ChatInputErrorType.permissionDenied,
        message: '请求麦克风权限失败: $e',
        originalError: e,
      ));
    }
  }

  void _updateStatus(ChatInputStatus status) {
    if (_currentStatus == status) return;

    _currentStatus = status;
    notifyListeners();
    onStatusChange?.call(status);
  }

  void _handleError(ChatInputError error) {
    onError?.call(error);
  }

  String getVoiceGestureText() {
    switch (_voiceGestureState) {
      case VoiceGestureState.recording:
        return "松手发送，滑动取消";
      case VoiceGestureState.cancelMode:
        return "松开取消";
      default:
        return "松手发送，滑动取消";
    }
  }
}
