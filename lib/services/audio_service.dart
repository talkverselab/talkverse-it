import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../core/platform.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  Map<String, String> _wordMap = const {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    if (isIOS) {
      // 무음 스위치에서도 학습 음성이 나오게
      await AudioPlayer.global.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.duckOthers},
        ),
        android: const AudioContextAndroid(),
      ));
    }
    try {
      final raw = await rootBundle.loadString('assets/data/audio_manifest.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final words = (data['words'] as Map<String, dynamic>?) ?? {};
      _wordMap = words.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _wordMap = const {};
    }
    _loaded = true;
  }

  bool hasWord(String word) {
    return _wordMap.containsKey(word);
  }

  Future<bool> playWord(String word) async {
    await ensureLoaded();
    final path = _wordMap[word];
    if (path == null) return false;
    final assetPath = path.startsWith('assets/') ? path.substring('assets/'.length) : path;
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() async {
    await _player.dispose();
  }
}
