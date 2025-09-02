// lib/features/profile/profile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/app/router/routes.dart'; // Ensure Routes is imported
import 'package:iconsax/iconsax.dart';
import 'package:inspection/features/profile/provider/user_profile_provider.dart';

import '../../common_ui/widgets/alerts/u_alert.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/theme_notifier.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/token_storage.dart';
import '../../utils/helpers/update_checker.dart';
import '../signin/signin.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger profile fetch when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(userProfileNotifierProvider.notifier).fetchUserProfile();
      }
    });
  }

  Future<void> _checkForUpdates() async {
    final updateChecker = ref.read(updateCheckerProvider);
    final result = await updateChecker.checkForUpdates();

    if (result != null && result['isUpdateAvailable'] == true) {
      updateChecker.showUpdateDialog(
        context,
        result['isMandatory'],
        result['apkUrl'],
        result['changelog'],
        result['versionName'],
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['message'] ?? 'App is up to date'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _performLogout() async {
    print('=== STARTING LOGOUT PROCESS ===');

    try {
      // Step 1: Clear profile state
      ref.read(userProfileNotifierProvider.notifier).resetProfile();
      print('✅ Profile state cleared');

      // Step 2: Clear token using TokenStorage
      await TokenStorage.clearToken();
      print('✅ Token cleared');

      // Step 3: Clear remember me preference
      final storageService = ref.read(storageServiceProvider);
      await storageService.setRememberMe(false);
      print('✅ Remember me preference cleared');

      // Step 4: Verify token is cleared
      final isCleared = await TokenStorage.isTokenCleared();
      print('🔍 Token clearance verification: ${isCleared ? "SUCCESS" : "FAILED"}');

      // Step 5: Invalidate providers to ensure clean state
      ref.invalidate(userProfileNotifierProvider);
      print('✅ User profile provider invalidated');
    } catch (e) {
      print('❌ Error during logout: $e');
      rethrow; // Let the error propagate to _handleLogout
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logging out...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Perform logout operations
        await _performLogout();

        // Navigate to sign-in screen with replacement
        if (context.mounted) {
          // Clear the navigation stack and go to sign-in
          while (GoRouter.of(context).canPop()) {
            GoRouter.of(context).pop();
          }
          context.go(Routes.signIn);
          print('✅ Navigation to sign-in screen successful');
        } else {
          print('❌ Context not mounted for navigation');
        }
      } catch (e) {
        print('❌ Logout process failed: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final userProfileState = ref.watch(userProfileNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: userProfileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load profile',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    ref
                        .read(userProfileNotifierProvider.notifier)
                        .fetchUserProfile();
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (userProfile) {
          final user = userProfile.data?.user;

          return ListView(
            padding: const EdgeInsets.all(USizes.defaultSpace),
            children: [
              /// Profile Info
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                      backgroundImage: const AssetImage('assets/logo/appLogo.png'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? "No Name",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? "No Email",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.phoneNumber ?? "No Phone",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: USizes.spaceBtwSections),
              const Divider(),

              /// Update Name
              ListTile(
                leading: const Icon(Iconsax.edit),
                title: const Text('Update Name'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  final nameController = TextEditingController(text: user?.name ?? '');

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Update Name'),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final newName = nameController.text.trim();
                            if (newName.isEmpty) {
                              UAlert.show(
                                title: 'Error',
                                message: 'Name is required',
                                context: context,
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              /// Update Email
              ListTile(
                leading: const Icon(Iconsax.sms),
                title: const Text('Update Email'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  final emailController = TextEditingController(text: user?.email ?? '');

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Update Email'),
                      content: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final newEmail = emailController.text.trim();
                            if (newEmail.isEmpty) {
                              UAlert.show(
                                title: 'Error',
                                message: 'Email is required',
                                context: context,
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              /// Update Password
              ListTile(
                leading: const Icon(Iconsax.lock),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  final passwordController = TextEditingController();

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Update Password'),
                      content: TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(labelText: 'New Password'),
                        obscureText: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final newPass = passwordController.text.trim();
                            if (newPass.length < 6) {
                              UAlert.show(
                                title: 'Error',
                                message: 'Password must be at least 6 characters',
                                context: context,
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              /// Toggle Theme
              ListTile(
                leading: const Icon(Iconsax.moon),
                title: const Text('Toggle Theme'),
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).state =
                    value ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),

              /// Logout
              ListTile(
                leading: Icon(Iconsax.logout, color: Colors.grey.shade800),
                title: const Text('Logout'),
                onTap: _handleLogout,
              ),

              ListTile(
                leading: const Icon(Iconsax.refresh),
                title: const Text('Check for Updates'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _checkForUpdates,
              ),

              /// App Version
              const Divider(),
              ListTile(
                leading: const Icon(Iconsax.information),
                title: const Text('App Version'),
                trailing: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Iconsax.code),
                title: const Text('Build Number'),
                trailing: const Text('100'),
              ),
            ],
          );
        },
      ),
    );
  }
}