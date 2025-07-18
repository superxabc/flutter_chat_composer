import 'package:flutter/material.dart';
import '../chat_input_types.dart';
import '../services/permission_handler.dart';

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
  
  static void _handleNetworkError(
    BuildContext context,
    ChatInputError error,
    VoidCallback? onRetry,
    bool showDialog,
    Duration? snackBarDuration,
  ) {
    // 网络错误使用toast提示
    _showToast(context, error.message, snackBarDuration);
  }
  
  static void _handlePermissionError(
    BuildContext context,
    ChatInputError error,
    bool showDialog,
  ) {
    // 权限错误始终使用弹窗引导用户
    _showPermissionDialog(context, error);
  }
  
  static void _handleRecordingError(
    BuildContext context,
    ChatInputError error,
    bool showDialog,
    Duration? snackBarDuration,
  ) {
    // 录音错误使用toast提示
    _showToast(context, error.message, snackBarDuration);
  }
  
  static void _handleFileSizeError(
    BuildContext context,
    ChatInputError error,
    bool showDialog,
    Duration? snackBarDuration,
  ) {
    // 文件大小错误使用toast提示
    _showToast(context, error.message, snackBarDuration);
  }
  
  static void _handleValidationError(
    BuildContext context,
    ChatInputError error,
    bool showDialog,
    Duration? snackBarDuration,
  ) {
    // 验证错误使用toast提示
    _showToast(context, error.message, snackBarDuration);
  }
  
  static void _handleUnknownError(
    BuildContext context,
    ChatInputError error,
    bool showDialog,
    Duration? snackBarDuration,
  ) {
    // 未知错误使用toast提示
    _showToast(context, error.message, snackBarDuration);
  }
  
  static void _showPermissionDialog(BuildContext context, ChatInputError error) {
    final permissionName = _getPermissionName(error.permissionType);
    final permissionIcon = _getPermissionIcon(error.permissionType);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: [
            Icon(
              permissionIcon,
              color: Colors.orange,
              size: 24.0,
            ),
            const SizedBox(width: 12.0),
            Text('需要$permissionName权限'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.message,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      '请在系统设置中找到本应用，并开启$permissionName权限',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后再说'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openSettings(context, error);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              '去设置',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration? duration,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.clearSnackBars();
    
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.grey[800],
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: action,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
  
  static Future<void> _openSettings(BuildContext context, ChatInputError error) async {
    try {
      await PermissionHandler.openSettings();
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          message: '无法打开设置页面',
          isError: true,
        );
      }
    }
  }
  
  static String _getPermissionName(ChatPermissionType? permissionType) {
    switch (permissionType) {
      case ChatPermissionType.microphone:
        return '麦克风';
      case ChatPermissionType.camera:
        return '相机';
      case ChatPermissionType.photos:
        return '相册';
      case ChatPermissionType.storage:
        return '存储';
      default:
        return '权限';
    }
  }
  
  static IconData _getPermissionIcon(ChatPermissionType? permissionType) {
    switch (permissionType) {
      case ChatPermissionType.microphone:
        return Icons.mic;
      case ChatPermissionType.camera:
        return Icons.camera_alt;
      case ChatPermissionType.photos:
        return Icons.photo_library;
      case ChatPermissionType.storage:
        return Icons.storage;
      default:
        return Icons.security;
    }
  }
  
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _showSnackBar(
      context,
      message: message,
      isError: false,
      duration: duration ?? const Duration(seconds: 2),
    );
  }
  
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _showSnackBar(
      context,
      message: message,
      isError: false,
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  static void _showToast(BuildContext context, String message, Duration? duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.0,
          ),
        ),
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(16.0),
        elevation: 6.0,
      ),
    );
  }
}

class RetryHelper {
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }
        
        await Future.delayed(delay);
      }
    }
    
    throw Exception('重试失败');
  }
  
  static Future<T> retryNetworkOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    return retry(
      operation,
      maxRetries: maxRetries,
      delay: delay,
      shouldRetry: (error) {
        return error.toString().contains('network') ||
               error.toString().contains('timeout') ||
               error.toString().contains('connection');
      },
    );
  }
} 