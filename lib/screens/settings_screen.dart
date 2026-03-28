import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/chat_provider.dart';
import '../services/github_copilot_auth.dart';

class _ProviderPreset {
  final String name;
  final String baseUrl;
  final String defaultModel;
  final String hint;
  final bool hasOAuth;

  const _ProviderPreset({
    required this.name,
    required this.baseUrl,
    required this.defaultModel,
    required this.hint,
    this.hasOAuth = false,
  });
}

const _presets = [
  _ProviderPreset(
    name: 'GitHub Copilot',
    baseUrl: 'https://api.githubcopilot.com',
    defaultModel: 'gpt-4o',
    hint: '點「用 GitHub 登入」自動授權',
    hasOAuth: true,
  ),
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
    name: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'anthropic/claude-sonnet-4',
    hint: '到 openrouter.ai → Keys 取得',
  ),
  _ProviderPreset(
    name: '自訂',
    baseUrl: '',
    defaultModel: '',
    hint: '手動輸入 Base URL 和 API Key',
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
  bool _isOAuthLoading = false;
  String? _oauthStatus;

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

  Future<void> _startGitHubOAuth() async {
    setState(() {
      _isOAuthLoading = true;
      _oauthStatus = '正在請求授權碼...';
    });

    try {
      // Step 1: Get device code
      final deviceCode = await GitHubCopilotAuth.requestDeviceCode();

      setState(() {
        _oauthStatus = null;
      });

      if (!mounted) return;

      // Show dialog with user code
      final authorized = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _OAuthDeviceCodeDialog(
          userCode: deviceCode.userCode,
          verificationUri: deviceCode.verificationUri,
          deviceCode: deviceCode.deviceCode,
          interval: deviceCode.interval,
        ),
      );

      if (authorized == true && mounted) {
        setState(() {
          _oauthStatus = '✅ 授權成功！';
        });

        // Token was saved by the dialog, reload
        final chat = context.read<ChatProvider>();
        _apiKeyController.text = chat.apiKey;
        _baseUrlController.text = chat.baseUrl;
        _modelController.text = chat.model;
      } else {
        setState(() {
          _oauthStatus = '❌ 授權取消或逾時';
        });
      }
    } catch (e) {
      setState(() {
        _oauthStatus = '❌ 錯誤: $e';
      });
    } finally {
      setState(() {
        _isOAuthLoading = false;
      });
    }
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

          // Provider cards
          ...List.generate(_presets.length, (i) {
            final p = _presets[i];
            final selected = i == _selectedPresetIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _onPresetChanged(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: selected
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withAlpha(80)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16)),
                                if (p.hasOAuth) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withAlpha(40),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('OAuth',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
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

          // OAuth button for GitHub Copilot
          if (preset.hasOAuth) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isOAuthLoading ? null : _startGitHubOAuth,
              icon: _isOAuthLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login),
              label: Text(_isOAuthLoading ? '授權中...' : '用 GitHub 登入'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (_oauthStatus != null) ...[
              const SizedBox(height: 8),
              Text(_oauthStatus!,
                  style: TextStyle(
                    color: _oauthStatus!.startsWith('✅')
                        ? Colors.green
                        : _oauthStatus!.startsWith('❌')
                            ? Colors.red
                            : null,
                  )),
            ],
            const SizedBox(height: 8),
            const Divider(),
            const Text('或手動輸入 API Key：',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],

          const Divider(height: 24),

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

          // Base URL
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

/// Dialog showing device code + polling for authorization
class _OAuthDeviceCodeDialog extends StatefulWidget {
  final String userCode;
  final String verificationUri;
  final String deviceCode;
  final int interval;

  const _OAuthDeviceCodeDialog({
    required this.userCode,
    required this.verificationUri,
    required this.deviceCode,
    required this.interval,
  });

  @override
  State<_OAuthDeviceCodeDialog> createState() => _OAuthDeviceCodeDialogState();
}

class _OAuthDeviceCodeDialogState extends State<_OAuthDeviceCodeDialog> {
  bool _polling = true;
  String _status = '等待你在瀏覽器中授權...';

  @override
  void initState() {
    super.initState();
    _pollAndSave();
  }

  Future<void> _pollAndSave() async {
    final githubToken = await GitHubCopilotAuth.pollForToken(
      widget.deviceCode,
      widget.interval,
    );

    if (!mounted) return;

    if (githubToken == null) {
      setState(() {
        _polling = false;
        _status = '授權失敗或逾時';
      });
      return;
    }

    setState(() {
      _status = '已取得 GitHub token，正在取得 Copilot token...';
    });

    // Try to get Copilot-specific token
    final copilotToken = await GitHubCopilotAuth.getCopilotToken(githubToken);
    final finalToken = copilotToken ?? githubToken;

    if (!mounted) return;

    // Save to provider
    // ignore: use_build_context_synchronously
    context.read<ChatProvider>().updateSettings(
      apiKey: finalToken,
      baseUrl: 'https://api.githubcopilot.com',
      model: 'gpt-4o',
    );

    setState(() {
      _polling = false;
      _status = '✅ 授權成功！';
    });

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('GitHub 授權'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('請在瀏覽器中輸入以下驗證碼：'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.userCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已複製驗證碼')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Text(
                widget.userCode,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('（點擊可複製）',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(widget.verificationUri);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('開啟瀏覽器授權'),
          ),
          const SizedBox(height: 16),
          if (_polling)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('等待授權中...'),
              ],
            )
          else
            Text(_status),
        ],
      ),
      actions: [
        if (_polling)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
      ],
    );
  }
}
