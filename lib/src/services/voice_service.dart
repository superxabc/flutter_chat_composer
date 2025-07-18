import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecordingResult {
  final String filePath;
  final Duration duration;
  final int fileSize;

  const VoiceRecordingResult({
    required this.filePath,
    required this.duration,
    required this.fileSize,
  });
}

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

    final tempDir = await getTemporaryDirectory();
    _currentRecordingPath = '${tempDir.path}/temp_recording_${DateTime.now().millisecondsSinceEpoch}.aac';

    _currentRecordingDuration = Duration.zero;

    await _recorder!.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.aacADTS,
    );

    _recorderSubscription = _recorder!.onProgress!.listen((e) {
      _currentRecordingDuration = e.duration;
    });

    return _currentRecordingPath!;
  }

  Future<VoiceRecordingResult> stopRecording() async {
    if (!_isRecorderInitialized || _recorder!.isStopped) {
      throw Exception('没有正在进行的录音');
    }

    final path = await _recorder!.stopRecorder();
    await _recorderSubscription?.cancel();
    _recorderSubscription = null;

    if (path == null) {
      throw Exception('录音文件路径为空');
    }

    final file = File(path);
    final fileSize = await file.length();

    return VoiceRecordingResult(
      filePath: path,
      duration: _currentRecordingDuration ?? Duration.zero,
      fileSize: fileSize,
    );
  }

  Future<void> cancelRecording() async {
    if (!_isRecorderInitialized || _recorder!.isStopped) {
      return;
    }

    final path = await _recorder!.stopRecorder();
    await _recorderSubscription?.cancel();
    _recorderSubscription = null;

    _currentRecordingDuration = null;

    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> startPlayback(String filePath) async {
    if (!_isPlayerInitialized) {
      throw Exception('播放器未初始化');
    }
    if (_player!.isPlaying) {
      await _player!.stopPlayer();
    }

    await _player!.startPlayer(
      fromURI: filePath,
      codec: Codec.aacADTS,
    );

    _playerSubscription = _player!.onProgress!.listen((e) {
    });
  }

  Future<void> stopPlayback() async {
    if (!_isPlayerInitialized || _player!.isStopped) {
      return;
    }
    await _player!.stopPlayer();
    await _playerSubscription?.cancel();
    _playerSubscription = null;
  }

  void dispose() {
    _recorderSubscription?.cancel();
    _playerSubscription?.cancel();
    if (_isRecorderInitialized) {
      _recorder!.closeRecorder();
    }
    if (_isPlayerInitialized) {
      _player!.closePlayer();
    }
    _recorder = null;
    _player = null;
  }
}