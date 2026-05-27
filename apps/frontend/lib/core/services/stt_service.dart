import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sttServiceProvider = Provider<SttService>((ref) {
  return SttService();
});

class SttService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isInitialized = false;

  /// No longer uses local ONNX models
  Future<void> init() async {
    _isInitialized = true;
    debugPrint('SttService initialized (ONNX disabled)');
  }

  bool get isReady => _isInitialized;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording(String path) async {
    if (await hasPermission()) {
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 16000,
        numChannels: 1,
      );
      await _recorder.start(config, path: path);
    }
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path;
  }

  /// Get current amplitude for waveform visualization
  Future<Amplitude> getAmplitude() async {
    return await _recorder.getAmplitude();
  }

  /// Stub for transcription. In the future, this can call an online API.
  Future<String> transcribe(String audioPath) async {
    debugPrint('Transcription requested for: $audioPath (STT disabled)');
    return '';
  }

  void dispose() {
    _recorder.dispose();
  }
}

