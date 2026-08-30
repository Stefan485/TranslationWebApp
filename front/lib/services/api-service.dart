import 'dart:io';
import 'package:dio/dio.dart';

class Language{
    final String code;
    final String name;
    const Language({required this.code, required this.name});
}

class TranslationResult{
    final String translatedText;
    final String? detectedLang;
    const TranslationResult({required this.translatedText, this.detectedLang});
}

class SpeechResult{
    final String text;
    final String? detectedLang;
    const SpeechResult({required this.text, this.detectedLang});
}

class ApiService{
    final Dio _dio;

    ApiService({String baseUrl = 'http://10.0.2.2:8000'}) //insert appropriate url
    :_dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
    ));

    Future<List<Language>> getSupportedLanguages() async{
        final response = await _dio.get('/languages');
        final data = response.data as List;
        return data
            .map((e) => Language(code: e['code'] as String, name: e['name'] as String))
            .toList();
    }

    Future<TranslationResult> translateText({
        required String text,
        required String targetLang,
    }) async{
        final response = await _dio.post('/translate', data:{
            'text': text,
            'target_lang': targetLang,
        });
        return TranslationResult(
            translatedText: response.data['translated_text'] as String,
            detectedLang: response.data['detected_lang'] as String?,
        );
    }

    Future<SpeechResult> speechToText({
        required File audioFile,
    }) async{
        final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(
                audioFile.path,
                filename: 'memo.m4a',
            ),
        });
        final response = await _dio.post('/transcribe', data: formData);
        return SpeechResult(
            text: response.data['text'] as String,
            detectedLang: response.data['language'] as String?,
        );
    }

    Future<List<int>> textToSpeech({
        required String text,
        required String targetLang,
    }) async{
        final response = await _dio.post<List<int>>(
            '/tts-audio',
            data: {'text': text, 'language': targetLang},
            options: Options(responseType: ResponseType.bytes),
        );
        return response.data!;
    }
}