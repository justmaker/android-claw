import 'dart:convert' show JsonDecoder;
import 'package:dio/dio.dart';

class OpenAICompatAdapter {
  final Dio _dio;
  String _apiKey;
  String _baseUrl;
  String _model;

  OpenAICompatAdapter({
    required String apiKey,
    String baseUrl = 'https://api.githubcopilot.com',
    String model = 'gpt-4o',
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _model = model,
        _dio = Dio();

  String get model => _model;
  String get baseUrl => _baseUrl;

  void updateConfig({String? apiKey, String? baseUrl, String? model}) {
    if (apiKey != null) _apiKey = apiKey;
    if (baseUrl != null) _baseUrl = baseUrl;
    if (model != null) _model = model;
  }

  /// Send chat messages and get a complete response (non-streaming).
  Future<String> chat(List<Map<String, dynamic>> messages) async {
    final response = await _dio.post(
      '$_baseUrl/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': _model,
        'messages': messages,
        'stream': false,
      },
    );

    final data = response.data;
    return data['choices'][0]['message']['content'] as String;
  }

  /// Stream chat responses chunk by chunk.
  Stream<String> chatStream(List<Map<String, dynamic>> messages) async* {
    final response = await _dio.post(
      '$_baseUrl/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
      data: {
        'model': _model,
        'messages': messages,
        'stream': true,
      },
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += String.fromCharCodes(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // keep incomplete line

      for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6).trim();
        if (payload == '[DONE]') return;

        try {
          // Manual JSON parse to avoid importing dart:convert in this simple case
          // Actually let's just use dart:convert
          final map = _parseJson(payload);
          final delta = map['choices']?[0]?['delta']?['content'];
          if (delta != null && delta is String && delta.isNotEmpty) {
            yield delta;
          }
        } catch (_) {
          // skip malformed chunks
        }
      }
    }
  }

  Map<String, dynamic> _parseJson(String json) {
    return Map<String, dynamic>.from(
      (const JsonDecoder().convert(json)) as Map,
    );
  }
}
