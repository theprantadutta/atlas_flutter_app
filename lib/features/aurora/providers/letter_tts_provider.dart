import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:atlas_flutter_app/core/logging/app_logger.dart';

final _log = AppLog('LetterTts');

/// Where reading the letter aloud has got to.
class LetterTtsState {
  const LetterTtsState({
    this.playing = false,
    this.offset = 0,
    this.length = 0,
    this.textId,
  });

  final bool playing;

  /// Character offset reached in the text being read.
  final int offset;
  final int length;

  /// Which text this progress belongs to (the letter's id).
  final String? textId;

  double get progress => length == 0 ? 0 : (offset / length).clamp(0.0, 1.0);

  LetterTtsState copyWith({bool? playing, int? offset, int? length, String? textId}) =>
      LetterTtsState(
        playing: playing ?? this.playing,
        offset: offset ?? this.offset,
        length: length ?? this.length,
        textId: textId ?? this.textId,
      );
}

/// Reads Aurora's letter aloud with the platform voice. Pausing remembers
/// the position and resuming continues from the start of that sentence, so
/// it works the same on every platform (not all support native pause).
class LetterTtsNotifier extends Notifier<LetterTtsState> {
  FlutterTts? _tts;
  String _text = '';
  int _base = 0; // offset of the chunk currently being spoken

  @override
  LetterTtsState build() {
    ref.onDispose(() => _tts?.stop());
    return const LetterTtsState();
  }

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    try {
      await tts.awaitSpeakCompletion(false);
      await tts.setSpeechRate(.47);
      await tts.setPitch(1.0);
    } catch (e) {
      _log.w('TTS setup failed: $e');
    }
    tts.setProgressHandler((text, start, end, word) {
      state = state.copyWith(offset: _base + end);
    });
    tts.setCompletionHandler(() {
      state = state.copyWith(playing: false, offset: state.length);
    });
    tts.setCancelHandler(() => state = state.copyWith(playing: false));
    tts.setErrorHandler((msg) {
      _log.w('TTS error: $msg');
      state = state.copyWith(playing: false);
    });
    return _tts = tts;
  }

  /// Play [text] (or resume it if it's the same [id]).
  Future<void> play(String id, String text) async {
    final tts = await _engine();
    if (state.textId != id || state.offset >= state.length) {
      _text = text;
      state = LetterTtsState(playing: true, offset: 0, length: text.length, textId: id);
      _base = 0;
    } else {
      // Resume from the start of the sentence we stopped in.
      final before = _text.substring(0, state.offset.clamp(0, _text.length));
      final cut = before.lastIndexOf(RegExp(r'[.!?]\s'));
      _base = cut < 0 ? 0 : cut + 2;
      state = state.copyWith(playing: true, offset: _base);
    }
    final result = await tts.speak(_text.substring(_base));
    if (result != 1) state = state.copyWith(playing: false);
  }

  Future<void> pause() async {
    await _tts?.stop();
    state = state.copyWith(playing: false);
  }

  Future<void> stop() async {
    await _tts?.stop();
    state = const LetterTtsState();
  }
}

final letterTtsProvider =
    NotifierProvider<LetterTtsNotifier, LetterTtsState>(LetterTtsNotifier.new);
