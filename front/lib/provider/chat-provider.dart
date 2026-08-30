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

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
    return ChatNotifier(
        api: ref.read(apiServiceProvider),
        audio: ref.read(audioServiceProvider),
        getTargetLang: () => ref.read(targetLangProvider),
        setDetectedLang: (lang) =>
            ref.read(detectedSourceLangProvider.notifier).state = lang,
    );
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
    final ApiService api;
    final AudioService audio;
    final String Function() getTargetLang;
    final void Function(String?) setDetectedLang;
    final _uuid = const Uuid();

    ChatNotifier({
        required this.api,
        required this.audio,
        required this.getTargetLang,
        required this.setDetectedLang,
    }) : super([]);

    void _addMessage(ChatMessage message){
        state = [...state, message];
    }

    void _updateMessage(String id, ChatMessage Function(ChatMessage) update){
        state = [
            for(final m in state)
                if(m.id == id) update(m) else m,
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
    _addMessage(ChatMessage(
      id: replyId,
      type: MessageType.text,
      originalText: '',
      isUser: false,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    ));

    try {
      final result = await api.translateText(
        text: text,
        targetLang: getTargetLang(),
      );
      setDetectedLang(result.detectedLang);
      _updateMessage(replyId, (m) => m.copyWith(
            translatedText: result.translatedText,
            status: MessageStatus.sent,
          ));
    } catch (e) {
      _updateMessage(replyId, (m) => m.copyWith(status: MessageStatus.error));
    }
  }

  Future<void> sendVoiceMemo(File audioFile) async {
    final userMsgId = _uuid.v4();
    _addMessage(ChatMessage(
      id: userMsgId,
      type: MessageType.voice,
      originalText: '',
      audioPath: audioFile.path,
      isUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    ));

    final replyId = _uuid.v4();

    try {
      final speech = await api.speechToText(audioFile: audioFile);
      setDetectedLang(speech.detectedLang);
      _updateMessage(userMsgId, (m) => m.copyWith(
            originalText: speech.text,
            status: MessageStatus.sent,
          ));

      _addMessage(ChatMessage(
        id: replyId,
        type: MessageType.text,
        originalText: '',
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      ));

      final result = await api.translateText(
        text: speech.text,
        targetLang: getTargetLang(),
      );

      String? ttsPath;
      try {
        final bytes = await api.textToSpeech(
          text: result.translatedText,
          targetLang: getTargetLang(),
        );
        ttsPath = await audio.saveAudioBytes(bytes);
      } catch (_) {}

      _updateMessage(replyId, (m) => m.copyWith(
            translatedText: result.translatedText,
            audioPath: ttsPath,
            status: MessageStatus.sent,
          ));
    } catch (e) {
      _updateMessage(userMsgId, (m) => m.copyWith(status: MessageStatus.error));
    }
  }
}