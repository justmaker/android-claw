import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../services/openai_compat_adapter.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  OpenAICompatAdapter? _adapter;

  // Settings
  String _apiKey = '';
  String _baseUrl = 'https://api.githubcopilot.com';
  String _model = 'gpt-4o';

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get model => _model;
  bool get isConfigured => _apiKey.isNotEmpty;

  ChatProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key') ?? '';
    _baseUrl = prefs.getString('base_url') ?? 'https://api.githubcopilot.com';
    _model = prefs.getString('model') ?? 'gpt-4o';
    _initAdapter();
    notifyListeners();
  }

  Future<void> updateSettings({
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {
    _apiKey = apiKey;
    _baseUrl = baseUrl;
    _model = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', apiKey);
    await prefs.setString('base_url', baseUrl);
    await prefs.setString('model', model);
    _initAdapter();
    notifyListeners();
  }

  void _initAdapter() {
    if (_apiKey.isNotEmpty) {
      _adapter = OpenAICompatAdapter(
        apiKey: _apiKey,
        baseUrl: _baseUrl,
        model: _model,
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (_adapter == null) {
      _error = '請先在設定中填入 API Key';
      notifyListeners();
      return;
    }

    _error = null;
    _messages.add(Message(role: MessageRole.user, content: content));
    _isLoading = true;
    notifyListeners();

    try {
      final apiMessages = _messages.map((m) => m.toApiMessage()).toList();

      // Use streaming
      final assistantMsg = Message(role: MessageRole.assistant, content: '');
      _messages.add(assistantMsg);
      notifyListeners();

      final buffer = StringBuffer();
      await for (final chunk in _adapter!.chatStream(apiMessages.sublist(0, apiMessages.length - 1))) {
        buffer.write(chunk);
        // Replace last message with updated content
        _messages[_messages.length - 1] = Message(
          id: assistantMsg.id,
          role: MessageRole.assistant,
          content: buffer.toString(),
          timestamp: assistantMsg.timestamp,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      // Remove the empty assistant message if error
      if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant && _messages.last.content.isEmpty) {
        _messages.removeLast();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }
}
