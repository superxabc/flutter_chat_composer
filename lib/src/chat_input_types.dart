

enum ChatInputMode {
  idle,
  text,
  voice,
}

enum ChatInputStatus {
  idle,
  inputting,
  sending,
  processing,
}

enum VoiceRecordingState {
  idle,
  recording,
  paused,
  completed,
  cancelled,
  error,
}

enum ChatContentType {
  text,
  voice,
  image,
  file,
}

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

  @override
  String toString() {
    return 'ChatContent{type: $type, text: $text, voiceFilePath: $voiceFilePath, voiceDuration: $voiceDuration, imageFilePath: $imageFilePath, filePath: $filePath, metadata: $metadata}';
  }
}

enum ChatInputErrorType {
  permissionDenied,
  recordingFailed,
  fileTooLarge,
  networkError,
  validationError,
  unknown,
}

enum ChatPermissionType {
  microphone,
  camera,
  storage,
  photos,
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

  @override
  String toString() {
    return 'ChatInputError{type: $type, message: $message, originalError: $originalError, permissionType: $permissionType}';
  }
}

enum TextInputState {
  collapsed,
}

enum VoiceGestureState {
  recording,
  cancelMode,
}

enum AudioFormat {
  aac,
  mp3,
  wav,
  m4a,
}

class VoiceRecordingConfig {
  final Duration minRecordingDuration;
  final Duration maxRecordingDuration;
  final int sampleRate;
  final int bitRate;
  final bool enableWaveform;
  final bool enableNoiseReduction;
  final AudioFormat audioFormat;
  
  const VoiceRecordingConfig({
    this.minRecordingDuration = const Duration(seconds: 1),
    this.maxRecordingDuration = const Duration(minutes: 2),
    this.sampleRate = 16000,
    this.bitRate = 128000,
    this.enableWaveform = true,
    this.enableNoiseReduction = true,
    this.audioFormat = AudioFormat.aac,
  });
}

 