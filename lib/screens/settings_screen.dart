import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class _ProviderPreset {
  final String name;
  final String baseUrl;
  final String defaultModel;
  final String hint;

  const _ProviderPreset({
    required this.name,
    required this.baseUrl,
    required this.defaultModel,
    required this.hint,
  });
}

const _presets = [
  _ProviderPreset(
    name: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o',
    hint: '到 platform.openai.com → API Keys 取得',
  ),
  _ProviderPreset(
    name: 'Anthropic',
    baseUrl: 'https://api.anthropic.com/v1',
    defaultModel: 'claude-sonnet-4-20250514',
    hint: '到 console.anthropic.com → API Keys 取得',
  ),
  _ProviderPreset(
    name: 'Google Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    defaultModel: 'gemini-2.5-pro',
    hint: '到 aistudio.google.com → Get API Key 取得',
  ),
  _ProviderPreset(
    name: 'GitHub Copilot',
    baseUrl: 'https://api.githubcopilot.com',
    defaultModel: 'gpt-4o',
    hint: '需要 Copilot 訂閱，用 GitHub token',
  ),
  _ProviderPreset(
    name: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'anthropic/claude-sonnet-4',
    hint: '到 openrouter.ai → Keys 取得',
  ),
  _ProviderPreset(
    name: '自訂',
    baseUrl: '',
    defaultModel: '',
    hint: '手動輸入 Base URL',
  ),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  bool _obscureKey = true;
  int _selectedPresetIndex = 0;

  @override
  void initState() {
    super.initState();
    final chat = context.read<ChatProvider>();
    _apiKeyController = TextEditingController(text: chat.apiKey);
    _baseUrlController = TextEditingController(text: chat.baseUrl);
    _modelController = TextEditingController(text: chat.model);

    // Match current baseUrl to preset
    _selectedPresetIndex = _presets.length - 1; // default to 自訂
    for (int i = 0; i < _presets.length - 1; i++) {
      if (chat.baseUrl == _presets[i].baseUrl) {
        _selectedPresetIndex = i;
        break;
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _onPresetChanged(int index) {
    setState(() {
      _selectedPresetIndex = index;
      if (index < _presets.length - 1) {
        _baseUrlController.text = _presets[index].baseUrl;
        _modelController.text = _presets[index].defaultModel;
      }
    });
  }

  void _save() {
    context.read<ChatProvider>().updateSettings(
          apiKey: _apiKeyController.text.trim(),
          baseUrl: _baseUrlController.text.trim(),
          model: _modelController.text.trim(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('設定已儲存 ✅')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final preset = _presets[_selectedPresetIndex];
    final isCustom = _selectedPresetIndex == _presets.length - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('選擇 Provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Provider 選擇卡片
          ...List.generate(_presets.length, (i) {
            final p = _presets[i];
            final selected = i == _selectedPresetIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _onPresetChanged(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: selected
                        ? Theme.of(context).colorScheme.primaryContainer.withAlpha(80)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                            if (p.hint.isNotEmpty)
                              Text(p.hint,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).hintColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const Divider(height: 32),

          // API Key
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Base URL (顯示但非自訂時 readonly)
          TextField(
            controller: _baseUrlController,
            readOnly: !isCustom,
            decoration: InputDecoration(
              labelText: 'Base URL',
              border: const OutlineInputBorder(),
              filled: !isCustom,
              fillColor: !isCustom
                  ? Theme.of(context).disabledColor.withAlpha(20)
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Model
          TextField(
            controller: _modelController,
            decoration: InputDecoration(
              labelText: 'Model',
              hintText: preset.defaultModel.isNotEmpty
                  ? preset.defaultModel
                  : 'gpt-4o',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}
