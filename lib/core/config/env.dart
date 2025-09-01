import 'dart:io';

import 'package:flutter/foundation.dart';

class Env {
  /// "prod" | "dev" | "local"
  /// Default is "local" so run button works with your backend automatically.
  static const env = String.fromEnvironment('ENV', defaultValue: 'prod');

  /// Local development hosts
  static const localAuthHost =
      'http://127.0.0.1:8000'; // Auth Backend (Login, Registration)
  static const localSurveyHost = 'http://127.0.0.1:9000'; // Survey Backend

  /// Local development hosts for Emulator and Physical Devices
  static const localHostEmu = 'http://10.0.2.2:8000'; // Android Emulator
  static const localHostSim = 'http://127.0.0.1:8000'; // iOS Simulator
  static const localHostLan =
      'http://192.168.0.23:8000'; // Physical device (change this)

  // ===== Defaults by ENV =====
  static const _centralAuthByEnv = {
    'prod': 'https://api.shwapno.app', // Production API
    'dev': 'https://dev.shwapno.app', // Staging/Dev server
    'local': localAuthHost, // will be resolved at runtime
  };

  static const _surveyByEnv = {
    'prod': 'https://survey-backend.shwapno.app',
    'dev': 'https://survey-development.shwapno.app',
    'local':
        localSurveyHost, // Ensuring local survey API points to correct backend
  };

  // ===== Optional explicit overrides (take precedence) =====
  static const _centralAuthOverride = String.fromEnvironment(
    'CENTRAL_AUTH_BASE_URL',
    defaultValue: '',
  );
  static const _surveyOverride = String.fromEnvironment(
    'SURVEY_BASE_URL',
    defaultValue: '',
  );

  /// Logging toggle (default: true unless release/prod)
  static const _logNetworkOverride = String.fromEnvironment(
    'LOG_NETWORK',
    defaultValue: '',
  );
  static bool get logNetwork => _logNetworkOverride.isNotEmpty
      ? (_logNetworkOverride.toLowerCase() == 'true')
      : !kReleaseMode;

  static bool get isProd => env.toLowerCase() == 'prod';
  static bool get isDev => env.toLowerCase() == 'dev';
  static bool get isLocal => env.toLowerCase() == 'local';

  /// Choose local base (emulator/simulator/device)
  static String get _localBaseUrl {
    if (Platform.isAndroid) return localHostEmu;
    if (Platform.isIOS) return localHostSim;
    return localHostLan; // fallback for physical devices
  }

  // ===== Resolved base URLs =====
  static String get centralAuthBaseUrl {
    if (_centralAuthOverride.isNotEmpty) return _centralAuthOverride;

    if (isLocal) return _localBaseUrl;

    return _centralAuthByEnv[env.toLowerCase()] ?? _centralAuthByEnv['prod']!;
  }

  static String get surveyBaseUrl {
    if (_surveyOverride.isNotEmpty) return _surveyOverride;

    // For local environment, it should always use the Survey Host
    if (isLocal) return localSurveyHost;

    return _surveyByEnv[env.toLowerCase()] ?? _surveyByEnv['prod']!;
  }

  // ===== Endpoints =====
  static String get loginUrl => '$centralAuthBaseUrl/api/user/login';
  static String get registerUrl => '$centralAuthBaseUrl/api/user/register';
  static String get verifyOtpUrl => '$centralAuthBaseUrl/api/verify-otp';
}
