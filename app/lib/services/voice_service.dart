import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Voice for Anchor: speech-to-text (you talk) + text-to-speech (Anchor talks).
/// Singleton so init happens once. Typing is always available as a fallback.
class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<bool> init() async {
    if (_ready) return true;
    _ready = await _speech.initialize(onError: (_) {}, onStatus: (_) {});
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    return _ready;
  }

  bool get isListening => _speech.isListening;

  /// Start listening. [onPartial] fires as words are recognised; [onFinal] fires
  /// once with the final transcript.
  Future<bool> listen({
    required void Function(String text) onPartial,
    required void Function(String text) onFinal,
  }) async {
    if (!await init()) return false;
    await _speech.listen(
      onResult: (r) {
        onPartial(r.recognizedWords);
        if (r.finalResult) onFinal(r.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(partialResults: true),
    );
    return true;
  }

  Future<void> stop() async => _speech.stop();

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> hush() async => _tts.stop();
}
