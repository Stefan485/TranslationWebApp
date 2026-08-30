import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../model/chat-msg.dart';
import '../services/api-service.dart';
import '../services/audio-service.dart';

final apiServiceProvider = Provider((ref) => ApiService());
final audioServiceProvider = Provider((ref) => AudioService());

final targetLangProvider = StateProvider<String>((ref) => 'en');

final availableLanguagesProvider = FutureProvider<List<Language>>((ref) {
  return ref.read(apiServiceProvider).getSupportedLanguages();
});

final detectedSourceLangProvider = StateProvider<String?>((ref) => null);

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(
    api: ref.read(apiServiceProvider),
    audio: ref.read(audioServiceProvider),
    getTargetLang: () => ref.read(targetLangProvider),
    getSourceLang: () => ref.read(detectedSourceLangProvider),
    setDetectedLang: (lang) =>
        ref.read(detectedSourceLangProvider.notifier).state = lang,
  );
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ApiService api;
  final AudioService audio;
  final String Function() getTargetLang;
  final String? Function() getSourceLang;
  final void Function(String?) setDetectedLang;

  final _uuid = const Uuid();

  ChatNotifier({
    required this.api,
    required this.audio,
    required this.getTargetLang,
    required this.getSourceLang,
    required this.setDetectedLang,
  }) : super([]);

  void _addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void _updateMessage(
    String id,
    ChatMessage Function(ChatMessage) update,
  ) {
    state = [
      for (final m in state)
        if (m.id == id) update(m) else m,
    ];
  }

  Future<void> sendTypedText(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      type: MessageType.text,
      originalText: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _addMessage(userMsg);

    final replyId = _uuid.v4();

    _addMessage(
      ChatMessage(
        id: replyId,
        type: MessageType.text,
        originalText: '',
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      ),
    );

    try {
      final result = await api.translateText(
        text: text,
        sourceLang: getSourceLang() ?? 'en',
        targetLang: getTargetLang(),
      );

      setDetectedLang(result.detectedLang);

      _updateMessage(
        replyId,
        (m) => m.copyWith(
          translatedText: result.translatedText,
          status: MessageStatus.sent,
        ),
      );
    } catch (e) {
      print('Translation failed: $e');

      _updateMessage(
        replyId,
        (m) => m.copyWith(
          status: MessageStatus.error,
        ),
      );
    }
  }

  Future<void> sendVoiceMemo(File audioFile) async {
    final userMsgId = _uuid.v4();

    _addMessage(
      ChatMessage(
        id: userMsgId,
        type: MessageType.voice,
        originalText: '',
        audioPath: audioFile.path,
        isUser: true,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      ),
    );

    final replyId = _uuid.v4();

    try {
      // STT detects the source language.
      final speech = await api.speechToText(
        audioFile: audioFile,
      );

      setDetectedLang(speech.detectedLang);

      _updateMessage(
        userMsgId,
        (m) => m.copyWith(
          originalText: speech.text,
          status: MessageStatus.sent,
        ),
      );

      _addMessage(
        ChatMessage(
          id: replyId,
          type: MessageType.text,
          originalText: '',
          isUser: false,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
        ),
      );

      // Use the language detected by STT.
      final result = await api.translateText(
        text: speech.text,
        sourceLang: speech.detectedLang!,
        targetLang: getTargetLang(),
      );

      String? ttsPath;

      try {
        final bytes = await api.textToSpeech(
          text: result.translatedText,
          targetLang: getTargetLang(),
        );

        ttsPath = await audio.saveAudioBytes(bytes);
      } catch (e) {
        print('TTS failed: $e');
      }

      _updateMessage(
        replyId,
        (m) => m.copyWith(
          translatedText: result.translatedText,
          audioPath: ttsPath,
          status: MessageStatus.sent,
        ),
      );
    } catch (e) {
      print('Voice translation failed: $e');

      _updateMessage(
        userMsgId,
        (m) => m.copyWith(
          status: MessageStatus.error,
        ),
      );
    }
  }
}