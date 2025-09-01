import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'update_checker.dart';
import '../../app/router/root_nav_key.dart'; // ✅ this file now exists

class AppLifecycleManager extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleManager> createState() =>
      _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends ConsumerState<AppLifecycleManager>
    with WidgetsBindingObserver {
  bool _checkedOnce = false;
  bool _dialogOpen = false;
  bool _forceRequired = false;
  bool _isChecking = false; // Add this

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCheckNow(force: true));
  }

  Future<void> _maybeCheckNow({bool force = false}) async {
    if (_isChecking || _dialogOpen) return;
    _isChecking = true;

    try {
      if (!_forceRequired && !force && _checkedOnce) return;
      _checkedOnce = true;

      final checker = ref.read(updateCheckerProvider);
      final result = await checker.checkForUpdates();
      if (result == null || result['isUpdateAvailable'] != true) return;

      final navCtx = rootNavigatorKey.currentContext;
      if (navCtx == null) return;

      final bool isMandatory = (result['force'] as bool?) ?? false;
      _forceRequired = isMandatory;
      _dialogOpen = true;

      try {
        if (isMandatory) {
          await checker.showForcedUpdateDialog(
            context: navCtx,
            apkUrl: result['apkUrl'],
            changelog: result['changelog'] ?? 'Bug fixes and improvements',
            versionName: result['versionName'] ?? '',
          );
        } else {
          await checker.showUpdateDialog(
            navCtx,
            isMandatory,
            result['apkUrl'],
            result['changelog'] ?? 'Bug fixes and improvements',
            result['versionName'] ?? '',
          );
        }
      } finally {
        _dialogOpen = false;
      }
    } finally {
      _isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
