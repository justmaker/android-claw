import 'package:dio/dio.dart';

/// GitHub Copilot OAuth Device Flow
class GitHubCopilotAuth {
  static const _clientId = 'Iv1.b507a08c87ecfe98'; // GitHub Copilot VS Code client ID
  static final _dio = Dio();

  /// Step 1: Request device code
  static Future<DeviceCodeResponse> requestDeviceCode() async {
    final response = await _dio.post(
      'https://github.com/login/device/code',
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'client_id': _clientId,
        'scope': 'read:user',
      },
    );

    final data = response.data;
    return DeviceCodeResponse(
      deviceCode: data['device_code'],
      userCode: data['user_code'],
      verificationUri: data['verification_uri'],
      expiresIn: data['expires_in'],
      interval: data['interval'],
    );
  }

  /// Step 2: Poll for access token
  static Future<String?> pollForToken(String deviceCode, int interval) async {
    while (true) {
      await Future.delayed(Duration(seconds: interval));

      try {
        final response = await _dio.post(
          'https://github.com/login/oauth/access_token',
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'client_id': _clientId,
            'device_code': deviceCode,
            'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          },
        );

        final data = response.data;

        if (data['access_token'] != null) {
          return data['access_token'] as String;
        }

        final error = data['error'];
        if (error == 'authorization_pending') {
          continue; // keep polling
        } else if (error == 'slow_down') {
          await Future.delayed(const Duration(seconds: 5));
          continue;
        } else if (error == 'expired_token') {
          return null; // user didn't authorize in time
        } else if (error == 'access_denied') {
          return null;
        }
      } catch (_) {
        continue;
      }
    }
  }

  /// Step 3: Exchange GitHub token for Copilot token
  static Future<String?> getCopilotToken(String githubToken) async {
    try {
      final response = await _dio.get(
        'https://api.github.com/copilot_internal/v2/token',
        options: Options(
          headers: {
            'Authorization': 'token $githubToken',
            'Accept': 'application/json',
          },
        ),
      );
      return response.data['token'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class DeviceCodeResponse {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final int expiresIn;
  final int interval;

  DeviceCodeResponse({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });
}
