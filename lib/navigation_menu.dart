// lib/navigation_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:inspection/services/survey_storage_service.dart';

import 'features/dashboard/dashboard.dart';
import 'features/home/home.dart';
import 'features/profile/profile.dart';
import 'features/result/model/survey_result_model.dart';
import 'features/result/provider/responseId_provider.dart';
import 'features/result/result.dart';
import 'features/site/provider/selected_site_provider.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

// Add this provider to watch for saved survey results
final savedSurveyResultProvider = FutureProvider<SurveyResultModel?>((ref) async {

  return await SurveyStorageService.getSurveyResult();
});

class NavigationMenu extends ConsumerWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final index = ref.watch(selectedIndexProvider);
    final latestResponseId = ref.watch(latestResponseIdProvider);
    final selectedSite = ref.watch(selectedSiteProvider);

    // Load saved survey result from storage
    final savedResultFuture = ref.watch(savedSurveyResultProvider);
    SurveyResultModel? savedResult;

    savedResultFuture.when(
      data: (result) => savedResult = result,
      loading: () => savedResult = null,
      error: (_, __) => savedResult = null,
    );

    Widget body;
    switch (index) {
      case 0:
        body = const HomeScreen();
        break;
      case 1:
      // Show ResultScreen if we have a saved result or the latest response ID
        final effectiveResponseId = savedResult?.responseId ?? latestResponseId;

        body = (effectiveResponseId != null && effectiveResponseId > 0)
            ? ResultScreen(responseId: effectiveResponseId)
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
                color: Colors.grey[100],
                border: Border.all(
                  color: Colors.black.withOpacity(0.05),
                ),
              ),
              child: NavigationBar(
                height: 64,
                elevation: 0,
                backgroundColor: Colors.grey[100],
                indicatorColor: Colors.black.withOpacity(0.08),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: index,
                onDestinationSelected: (i) {
                  ref.read(selectedIndexProvider.notifier).state = i;
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history),
                    label: 'History',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_circle),
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