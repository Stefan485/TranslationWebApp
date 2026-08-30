import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../model/chat-msg.dart';
import '../services/api-service.dart';
import '../services/audio-service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

final targetLangProvider = StateProvider<String>((ref) {
  return 'en';
});

final availableLanguagesProvider = FutureProvider<List<Language>>((ref) {
  return ref.read(apiServiceProvider).getSupportedLanguages();
});

final detectedSourceLangProvider = StateProvider<String?>((ref) {
  return null;
});

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(
    api: ref.read(apiServiceProvider),
    audio: ref.read(audioServiceProvider),
    getTargetLang: () => ref.read(targetLangProvider),
    getSourceLang: () => ref.read(detectedSourceLangProvider),
    setDetectedLang: (lang) {
      ref.read(detectedSourceLangProvider.notifier).state = lang;
    },
  );
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ApiService api;
  final AudioService audio;

  final String Function() getTargetLang;
  final String? Function() getSourceLang;
  final void Function(String?) setDetectedLang;

  final Uuid _uuid = const Uuid();

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
      for (final message in state)
        message.id == id ? update(message) : message,
    ];
  }

  List<String> _getTranslationContext() {
    final context = <String>[];

    for (final message in state.reversed) {
      if (!message.isUser) {
        continue;
      }

      if (message.originalText.trim().isEmpty) {
        continue;
      }

      context.add(message.originalText);

      if (context.length == 5) {
        break;
      }
    }

    return context.reversed.toList();
  }

  Future<void> sendTypedText(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    final context = _getTranslationContext();

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      type: MessageType.text,
      originalText: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _addMessage(userMessage);

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
      final result = await api.translateTextWithContext(
        text: text,
        sourceLang: getSourceLang() ?? 'en',
        targetLang: getTargetLang(),
        context: context,
      );

      _updateMessage(
        replyId,
        (message) => message.copyWith(
          translatedText: result.translatedText,
          status: MessageStatus.sent,
        ),
      );
    } catch (e) {
      print('Translation failed: $e');

      _updateMessage(
        replyId,
        (message) => message.copyWith(
          status: MessageStatus.error,
        ),
      );
    }
  }

  Future<void> sendVoiceMemo(File audioFile) async {
    final context = _getTranslationContext();

    final userMessageId = _uuid.v4();

    _addMessage(
      ChatMessage(
        id: userMessageId,
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
      final speech = await api.speechToText(
        audioFile: audioFile,
      );

      print('STT response: ${speech.text}');
      print('Detected language: ${speech.detectedLang}');

      setDetectedLang(speech.detectedLang);

      _updateMessage(
        userMessageId,
        (message) => message.copyWith(
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

      print(
        'TRANSLATE: '
        'text="${speech.text}", '
        'source="${speech.detectedLang}", '
        'target="${getTargetLang()}", '
        'context=$context',
      );

      final result = await api.translateTextWithContext(
        text: speech.text,
        sourceLang: speech.detectedLang!,
        targetLang: getTargetLang(),
        context: context,
      );

      print('TRANSLATION: ${result.translatedText}');

      String? ttsPath;

      try {
        final bytes = await api.textToSpeech(
          text: result.translatedText,
          targetLang: getTargetLang(),
        );

        ttsPath = await audio.saveAudioBytes(bytes);

        print('TTS audio saved: $ttsPath');
      } catch (e) {
        print('TTS failed: $e');
      }

      _updateMessage(
        replyId,
        (message) => message.copyWith(
          translatedText: result.translatedText,
          audioPath: ttsPath,
          status: MessageStatus.sent,
        ),
      );
    } catch (e) {
      print('Voice translation failed: $e');

      _updateMessage(
        userMessageId,
        (message) => message.copyWith(
          status: MessageStatus.error,
        ),
      );

      _updateMessage(
        replyId,
        (message) => message.copyWith(
          status: MessageStatus.error,
        ),
      );
    }
  }
}