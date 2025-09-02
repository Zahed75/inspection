// lib/navigation_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'features/dashboard/dashboard.dart';
import 'features/home/home.dart';
import 'features/profile/profile.dart';
import 'features/result/provider/responseId_provider.dart';
import 'features/result/result.dart';
import 'features/site/provider/selected_site_provider.dart';


final selectedIndexProvider = StateProvider<int>((ref) => 0);

class NavigationMenu extends ConsumerWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final index = ref.watch(selectedIndexProvider);
    final latestResponseId = ref.watch(latestResponseIdProvider);
    final selectedSite = ref.watch(selectedSiteProvider);

    // Refresh surveys when home tab is selected and site is available
    if (index == 0 && selectedSite != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Invalidate any survey-related providers to force refresh
        ref.invalidate(surveysProvider);
      });
    }

    Widget body;
    switch (index) {
      case 0:
        body = const HomeScreen();
        break;
      case 1:
      // Show ResultScreen if we have a latest response ID, otherwise show placeholder
        body = latestResponseId != null && latestResponseId > 0
            ? ResultScreen(responseId: latestResponseId)
            : const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Survey History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Complete surveys to see your history here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
        break;
      case 2:
        body = const DashboardScreen();
        break;
      case 3:
        body = const ProfileScreen();
        break;
      default:
        body = const HomeScreen();
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: body,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: dark ? Colors.black12 : Colors.grey[100],
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: NavigationBar(
                height: 64,
                elevation: 0,
                backgroundColor: dark ? Colors.black12 : Colors.grey[100],
                indicatorColor: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: index,
                onDestinationSelected: (i) {
                  ref.read(selectedIndexProvider.notifier).state = i;
                  // Don't clear the latest response ID when switching tabs
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Iconsax.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Iconsax.shop),
                    label: 'History',
                  ),
                  NavigationDestination(
                    icon: Icon(Iconsax.menu_board),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Iconsax.user),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}