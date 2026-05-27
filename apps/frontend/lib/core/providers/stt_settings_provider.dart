import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SttSettings {
  final String? encoderPath;
  final String? decoderPath;
  final String? tokensPath;

  SttSettings({this.encoderPath, this.decoderPath, this.tokensPath});

  SttSettings copyWith({
    String? encoderPath,
    String? decoderPath,
    String? tokensPath,
  }) {
    return SttSettings(
      encoderPath: encoderPath ?? this.encoderPath,
      decoderPath: decoderPath ?? this.decoderPath,
      tokensPath: tokensPath ?? this.tokensPath,
    );
  }

  bool get isConfigured =>
      encoderPath != null && decoderPath != null && tokensPath != null;
}

class SttSettingsNotifier extends Notifier<SttSettings> {
  static const String _keyEncoder = 'stt_encoder_path';
  static const String _keyDecoder = 'stt_decoder_path';
  static const String _keyTokens = 'stt_tokens_path';

  @override
  SttSettings build() {
    _loadSettings();
    return SttSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final encoder = prefs.getString(_keyEncoder);
    final decoder = prefs.getString(_keyDecoder);
    final tokens = prefs.getString(_keyTokens);

    state = SttSettings(
      encoderPath: encoder,
      decoderPath: decoder,
      tokensPath: tokens,
    );
  }

  Future<void> setEncoderPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEncoder, path);
    state = state.copyWith(encoderPath: path);
  }

  Future<void> setDecoderPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDecoder, path);
    state = state.copyWith(decoderPath: path);
  }

  Future<void> setTokensPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTokens, path);
    state = state.copyWith(tokensPath: path);
  }

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEncoder);
    await prefs.remove(_keyDecoder);
    await prefs.remove(_keyTokens);
    state = SttSettings();
  }
}

final sttSettingsProvider = NotifierProvider<SttSettingsNotifier, SttSettings>(
  () {
    return SttSettingsNotifier();
  },
);
