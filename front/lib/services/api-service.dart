import 'dart:io';
import 'package:dio/dio.dart';

class Language {
  final String code;
  final String name;

  const Language({
    required this.code,
    required this.name,
  });
}

class TranslationResult {
  final String translatedText;
  final String? detectedLang;

  const TranslationResult({
    required this.translatedText,
    this.detectedLang,
  });
}

class SpeechResult {
  final String text;
  final String? detectedLang;

  const SpeechResult({
    required this.text,
    this.detectedLang,
  });
}

class ApiService {
  final Dio _dio;

  static const String sttUrl = 'http://localhost:8001';
  static const String translationUrl = 'http://localhost:8002';
  static const String ttsUrl = 'http://localhost:8003';

  ApiService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

  Future<List<Language>> getSupportedLanguages() async {
    final response = await _dio.get('$ttsUrl/languages');

    final data = response.data as List;

    return data
        .map(
          (e) => Language(
            code: e['code'] as String,
            name: e['name'] as String,
          ),
        )
        .toList();
  }

    Future<TranslationResult> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
    }) async {
    try {
        print(
        'TRANSLATE: text="$text", '
        'source="$sourceLang", '
        'target="$targetLang"',
        );

        final response = await _dio.post(
        '$translationUrl/translate',
        data: {
            'text': text,
            'source_language': sourceLang,
            'target_language': targetLang,
        },
        );

        print('TRANSLATION response: ${response.data}');

        return TranslationResult(
        translatedText: response.data['translation'] as String,
        detectedLang: response.data['source_language'] as String?,
        );
    } on DioException catch (e) {
        print('TRANSLATION ERROR: ${e.response?.statusCode}');
        print('TRANSLATION ERROR BODY: ${e.response?.data}');
        rethrow;
    }
    }

    Future<SpeechResult> speechToText({
    required File audioFile,
    }) async {
    final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
        audioFile.path,
        filename: 'memo.m4a',
        ),
    });

    try {
        final response = await _dio.post(
        '$sttUrl/transcribe',
        data: formData,
        );

        print('STT response: ${response.data}');

        return SpeechResult(
        text: response.data['text'] as String,
        detectedLang: response.data['language'] as String?,
        );
    } on DioException catch (e) {
        print('STT ERROR: ${e.response?.statusCode}');
        print('STT ERROR BODY: ${e.response?.data}');
        rethrow;
    }
    }
    
    Future<List<int>> textToSpeech({
    required String text,
    required String targetLang,
    }) async {
    try {
        print(
        'TTS: text="$text", '
        'language="$targetLang"',
        );

        final response = await _dio.post<List<int>>(
        '$ttsUrl/tts-audio',
        data: {
            'text': text,
            'language': targetLang,
        },
        options: Options(
            responseType: ResponseType.bytes,
        ),
        );

        print('TTS response received');

        return response.data!;
    } on DioException catch (e) {
        print('TTS ERROR: ${e.response?.statusCode}');
        print('TTS ERROR BODY: ${e.response?.data}');
        rethrow;
    }
    }
}