import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/services/stt_service.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VoiceInputButton extends ConsumerStatefulWidget {
  final TextEditingController controller;

  const VoiceInputButton({super.key, required this.controller});

  @override
  ConsumerState<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends ConsumerState<VoiceInputButton> {
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isModelLoading = false;
  Timer? _recordingTimer;
  Timer? _amplitudeTimer;
  int _recordingDuration = 0;
  double _currentAmplitude = 0.0; // 0.0 - 1.0

  /// Normalize dBFS amplitude (-160 to 0) → 0.0 - 1.0
  double _normalizeAmplitude(double dbFS) {
    const double minDb = -50.0;
    const double maxDb = -5.0;
    final clamped = dbFS.clamp(minDb, maxDb);
    return (clamped - minDb) / (maxDb - minDb);
  }

  Future<void> _startRecording() async {
    final sttService = ref.read(sttServiceProvider);

    // Auto-initialize model
    if (!sttService.isReady) {
      setState(() => _isModelLoading = true);
      await sttService.init();
      if (mounted) setState(() => _isModelLoading = false);

      if (!sttService.isReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not initialize speech recognition model'),
            ),
          );
        }
        return;
      }
    }

    final hasPermission = await sttService.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone access is required to use this feature',
            ),
          ),
        );
      }
      return;
    }

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/voice_record.wav';

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
      _currentAmplitude = 0.0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _recordingDuration++);
    });

    await sttService.startRecording(path);

    // Poll amplitude every 80ms
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _pollAmplitude(),
    );
  }

  Future<void> _pollAmplitude() async {
    if (!_isRecording) return;
    final sttService = ref.read(sttServiceProvider);
    try {
      final amplitude = await sttService.getAmplitude();
      final normalized = _normalizeAmplitude(amplitude.current);
      if (mounted) {
        setState(() {
          // Smooth transition: lerp toward target
          _currentAmplitude += (normalized - _currentAmplitude) * 0.4;
        });
      }
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    final sttService = ref.read(sttServiceProvider);
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();

    final path = await sttService.stopRecording();

    setState(() {
      _isRecording = false;
      _isTranscribing = true;
      _currentAmplitude = 0.0;
    });

    if (path != null) {
      try {
        final text = await sttService.transcribe(path);
        if (text.isNotEmpty && mounted) {
          final currentText = widget.controller.text;
          final newText = currentText.isEmpty ? text : '$currentText $text';
          widget.controller.text = newText;
          widget.controller.selection = TextSelection.collapsed(
            offset: newText.length,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Recognition error: $e')));
        }
      }
    }

    if (mounted) setState(() => _isTranscribing = false);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isModelLoading) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Circle scale: base 1.0, grows up to 1.8 based on amplitude
    final circleScale = _isRecording ? 1.0 + _currentAmplitude * 0.8 : 0.0;

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Amplitude-responsive circle
            if (_isRecording)
              AnimatedScale(
                scale: circleScale,
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // Duration label
            if (_isRecording)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_recordingDuration}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Mic button
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red
                    : (_isTranscribing
                          ? AppPallete.getPrimaryColor(
                              context,
                            ).withValues(alpha: 0.5)
                          : AppPallete.getSecondarySurface(context)),
                shape: BoxShape.circle,
              ),
              child: _isTranscribing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: _isRecording
                          ? Colors.white
                          : AppPallete.getTextSecondary(context),
                      size: 22,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
