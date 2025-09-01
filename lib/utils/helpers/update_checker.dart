// lib/utils/helpers/update_checker.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/router/root_nav_key.dart';
import '../../core/config/env.dart';
import '../../core/network/dio_provider.dart';
import '../../services/update_service.dart';

final updateCheckerProvider = Provider<UpdateChecker>((ref) {
  final dio = ref.read(dioProvider);
  return UpdateChecker(dio);
});

class UpdateChecker {
  final Dio _dio;
  UpdateChecker(this._dio);

  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;
      final currentName = info.version;

      final res = await _dio.get(
        '${Env.surveyBaseUrl}/survey/api/app/download/',
      );

      if (res.statusCode == 200) {
        final data = (res.data ?? const {})['data'] ?? const {};

        final latestCode = data['versionCode'] as int? ?? 0;
        final latestName = data['versionName'] as String? ?? '';
        final apkUrl = data['apkUrl'] as String? ?? '';
        final isMandatory = data['isMandatory'] as bool? ?? false;
        final minSupportedCode = data['minSupportedCode'] as int?; //
        final changelog =
            data['changelog'] as String? ?? 'Bug fixes and improvements';

        // Force update if either the API says so, or this build is below min supported.
        final force =
            (isMandatory == true) ||
            (minSupportedCode != null && currentCode < minSupportedCode);

        // New version available?
        if (latestCode > currentCode && apkUrl.isNotEmpty) {
          return {
            'isUpdateAvailable': true,
            'force': force, //  tell caller to block the app
            'isMandatory': isMandatory, // (kept for reference)
            'apkUrl': apkUrl,
            'changelog': changelog,
            'versionName': latestName,
            'currentVersion': currentName,
            'latestVersion': latestName,
          };
        } else {
          return {'isUpdateAvailable': false, 'message': 'App is up to date'};
        }
      }
    } catch (e) {
      debugPrint('❌ Update check error: $e');
      return {
        'isUpdateAvailable': false,
        'message': 'Failed to check for updates: $e',
      };
    }
    return null;
  }

  Future<void> showUpdateDialog(
      BuildContext context,
      bool isMandatory,
      String apkUrl,
      String changelog,
      String versionName,
      ) async {
    await showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      useRootNavigator: true,
      builder: (ctx) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('New version $versionName is available!'),
                  const SizedBox(height: 12),
                  const Text(
                    "What's new:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(changelog),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isMandatory
                        ? 'You must update to continue using the app.'
                        : 'Please update to enjoy the latest improvements.',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isMandatory)
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Later'),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _startUpdate(ctx, apkUrl);
                        },
                        child: const Text('Update Now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> showForcedUpdateDialog({
    required BuildContext context,
    required String apkUrl,
    required String changelog,
    required String versionName,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        return WillPopScope(
          onWillPop: () async => false, // block back
          child: AlertDialog(
            title: const Text('Update Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version $versionName is available.'),
                const SizedBox(height: 8),
                const Text(
                  "What's new:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(changelog),
                const SizedBox(height: 16),
                const Text('You must update to continue using the app.'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _startUpdate(ctx, apkUrl);
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }

  // UpdateChecker class

  void _startUpdate(BuildContext context, String apkUrl) async {
    // Prevent multiple dialogs
    if (_isUpdating) {
      print('⏸️ Update already in progress, skipping');
      return;
    }
    _isUpdating = true;

    print('🔄 Starting update process...');

    // Store context reference early to avoid disposed widget issues
    final BuildContext? safeContext = context.mounted ? context : rootNavigatorKey.currentContext;
    if (safeContext == null) {
      print('❌ No valid context available');
      _isUpdating = false;
      return;
    }

    // Show progress dialog
    showDialog(
      context: safeContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Downloading Update'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                StreamBuilder<double>(
                  stream: UpdateService.progressStream,
                  builder: (ctx, snap) {
                    if (snap.hasData) {
                      final pct = (snap.data! * 100).toStringAsFixed(1);
                      return Text('$pct% downloaded');
                    } else if (snap.hasError) {
                      return Text(
                        'Error: ${snap.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                    return const Text('Starting download...');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      print('✅ Proceeding with download...');
      await UpdateService.downloadAndInstallUpdate(apkUrl);

      print('✅ Update process completed successfully');

      // Use the stored context safely
      if (safeContext.mounted) {
        Navigator.of(safeContext, rootNavigator: true).pop();
      }

    } catch (e) {
      print('❌ Update failed with error: $e');

      // Use the stored context safely
      if (safeContext.mounted) {
        Navigator.of(safeContext, rootNavigator: true).pop();
        _showErrorDialog(safeContext, e.toString());
      }
    } finally {
      _isUpdating = false;
      print('🏁 Update process finished');
    }
  }

// Add this variable to track update state
  bool _isUpdating = false;

  void _showStoragePermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text('Please grant storage permission to download the update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showInstallPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Install Permission Required'),
        content: const Text('Please allow installation from unknown sources to install the update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }


  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Successful'),
        content: const Text('The app will restart after installation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Failed'),
        content: Text('Failed to download update: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
