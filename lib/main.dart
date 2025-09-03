// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspection/utils/constants/token_storage.dart';
import 'package:inspection/utils/helpers/app_lifecycle_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/router/app_router.dart';
import 'app/router/root_nav_key.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_notifier.dart';
import 'package:flutter/widgets.dart';
import 'features/profile/provider/user_profile_provider.dart';
import 'utils/helpers/update_checker.dart';

// In main.dart, modify the main function
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  final sharedPrefs = await SharedPreferences.getInstance();

  // Check initial auth state
  final token = await TokenStorage.getToken();
  final initialAuthState = token != null && token.isNotEmpty;

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sharedPrefs),
        // Initialize auth state
        isAuthenticatedProvider.overrideWith((ref) => initialAuthState),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(
      const Duration(seconds: 2),
    ); // Wait for app to initialize

    final updateChecker = ref.read(updateCheckerProvider);
    final updateInfo = await updateChecker.checkForUpdates();

    if (updateInfo != null && updateInfo['isUpdateAvailable'] == true) {
      if (updateInfo['force'] == true) {
        // Forced update
        updateChecker.showForcedUpdateDialog(
          context: rootNavigatorKey.currentContext!,
          apkUrl: updateInfo['apkUrl'],
          changelog: updateInfo['changelog'],
          versionName: updateInfo['versionName'],
        );
      } else {
        // Optional update
        updateChecker.showUpdateDialog(
          rootNavigatorKey.currentContext!,
          updateInfo['isMandatory'],
          updateInfo['apkUrl'],
          updateInfo['changelog'],
          updateInfo['versionName'],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return AppLifecycleManager(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: UAppTheme.lightTheme,
        darkTheme: UAppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
