// lib/services/update_service.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter_app_installer/flutter_app_installer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart'; // Add this import for PlatformException

class UpdateService {
  static StreamController<double>? _progressController;
  static Stream<double> get progressStream {
    _progressController ??= StreamController<double>.broadcast();
    return _progressController!.stream;
  }

  static void _resetProgress() {
    _progressController?.close();
    _progressController = StreamController<double>.broadcast();
  }

  static Future<bool> _requestStoragePermission() async {
    try {
      // Check if storage permission is already granted
      if (await Permission.storage.isGranted) {
        return true;
      }

      // Request storage permission
      final status = await Permission.storage.request();

      if (status.isGranted) {
        return true;
      }

      // For Android 11+ (API 30+), try manage external storage
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Permission request error: $e');
      return false;
    }
  }

  static Future<bool> _requestInstallPermission() async {
    try {
      if (await Permission.requestInstallPackages.isGranted) return true;
      final status = await Permission.requestInstallPackages.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Install permission error: $e');
      return false;
    }
  }

  static Future<String> _getDownloadDirectory() async {
    try {
      // Use external files directory which is accessible by FileProvider
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final downloadDir = Directory('${externalDir.path}/downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir.path;
      }

      // Fallback to temporary directory
      final tempDir = await getTemporaryDirectory();
      return tempDir.path;
    } catch (e) {
      // Final fallback
      return '/storage/emulated/0/Download';
    }
  }

  static Future<String> _downloadApk(String apkUrl) async {
    try {
      print('🔐 Checking storage permissions...');
      final hasStoragePermission = await _requestStoragePermission();
      if (!hasStoragePermission) {
        throw Exception('Storage permission is required to download updates');
      }
      print('✅ Storage permission granted');

      final directoryPath = await _getDownloadDirectory();
      print('📁 Download directory: $directoryPath');

      final filePath = '$directoryPath/update_${DateTime.now().millisecondsSinceEpoch}.apk';
      final file = File(filePath);

      // Create directory if it doesn't exist
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        print('📁 Creating directory: $directoryPath');
        await dir.create(recursive: true);
      }

      // Delete existing file if it exists
      if (await file.exists()) {
        print('🗑️ Deleting existing file');
        await file.delete();
      }

      print('🌐 Starting download request...');
      final dio = Dio();
      final response = await dio.download(
        apkUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _progressController?.add(progress);
            print('📊 Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      print('✅ Download HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Verify the file was actually written
        final downloadedFile = File(filePath);
        final exists = await downloadedFile.exists();
        final size = exists ? await downloadedFile.length() : 0;

        print('✅ Download verification - Exists: $exists, Size: $size bytes');

        if (exists && size > 0) {
          return filePath;
        } else {
          throw Exception('Downloaded file is empty or missing');
        }
      } else {
        throw Exception('Failed to download APK: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Download error: $e');
      if (e is DioException) {
        print('❌ Dio error: ${e.message}');
        print('❌ Dio response: ${e.response?.statusCode}');
        print('❌ Dio type: ${e.type}');
      }
      rethrow;
    }
  }

  static Future<void> downloadAndInstallUpdate(String apkUrl) async {
    _resetProgress();
    print('🚀 Starting downloadAndInstallUpdate process');

    try {
      print('⬇️ Starting download from: $apkUrl');

      final hasInstallPermission = await _requestInstallPermission();
      if (!hasInstallPermission) {
        throw Exception('Install permission is required to install updates');
      }
      print('✅ Install permission granted');

      // Download the APK to external storage (accessible by FileProvider)
      print('📥 Downloading APK...');
      final apkFilePath = await _downloadApk(apkUrl);
      print('✅ Download completed: $apkFilePath');

      // Verify file exists
      final apkFile = File(apkFilePath);
      final fileExists = await apkFile.exists();
      final fileSize = fileExists ? await apkFile.length() : 0;
      print('📁 File exists: $fileExists, Size: $fileSize bytes');

      if (!fileExists || fileSize == 0) {
        throw Exception('Downloaded APK file is missing or empty');
      }

      // Install the APK using flutter_app_installer
      print('🔧 Starting installation...');
      final FlutterAppInstaller flutterAppInstaller = FlutterAppInstaller();

      await flutterAppInstaller.installApk(
        filePath: apkFilePath,
        silently: false,
      );

      print('✅ Installation initiated successfully');

    } catch (e) {
      print('❌ Update failed: $e');
      print('❌ Error type: ${e.runtimeType}');

      // Handle PlatformException
      if (e is PlatformException) {
        print('❌ Platform error code: ${e.code}');
        print('❌ Platform error message: ${e.message}');
        print('❌ Platform error details: ${e.details}');
      }
      // Handle DioException
      else if (e is DioException) {
        print('❌ Dio error: ${e.message}');
        print('❌ Dio response: ${e.response?.statusCode}');
        print('❌ Dio type: ${e.type}');
      }

      _progressController?.addError(e);
      rethrow;
    }
  }

  static Future<Map<String, bool>> checkPermissions() async {
    final storagePermission = await _requestStoragePermission();
    final installPermission = await _requestInstallPermission();

    print('📋 Permission status - Storage: $storagePermission, Install: $installPermission');

    return {
      'storage': storagePermission,
      'install': installPermission,
    };
  }
}