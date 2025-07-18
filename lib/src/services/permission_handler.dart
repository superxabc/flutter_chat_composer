import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionType {
  microphone,
  camera,
  storage,
  photos,
}

enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
  unknown,
}

class PermissionException implements Exception {
  final String message;
  final PermissionResult result;
  
  const PermissionException(this.message, this.result);
  
  @override
  String toString() => 'PermissionException: $message';
}

class PermissionHandler {
  PermissionHandler._();

  static Permission _getPermission(PermissionType type) {
    switch (type) {
      case PermissionType.microphone:
        return Permission.microphone;
      case PermissionType.camera:
        return Permission.camera;
      case PermissionType.storage:
        if (Platform.isAndroid) {
          return Permission.manageExternalStorage;
        } else {
          return Permission.storage;
        }
      case PermissionType.photos:
        return Permission.photos;
    }
  }

  static Future<bool> requestPermission(PermissionType type) async {
    try {
      final permission = _getPermission(type);
      final status = await permission.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
    }
  }

  static Future<bool> checkPermission(PermissionType type) async {
    try {
      final permission = _getPermission(type);
      final status = await permission.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Permission check failed: $e');
      return false;
    }
  }

  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
  
  static bool get isVoiceRecordingSupported {
    if (kIsWeb) {
      return true;
    }
    
    return Platform.isIOS || Platform.isAndroid;
  }
} 