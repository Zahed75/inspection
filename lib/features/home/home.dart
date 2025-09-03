// lib/features/home/home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:inspection/features/home/provider/survey_api_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/router/routes.dart';
import '../../common_ui/widgets/alerts/u_alert.dart';
import '../../features/site/provider/selected_site_provider.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/texts.dart';
import '../site/site_location.dart';
import '../survey/survey_info.dart';
import 'model/survey_list_model.dart';

// Define Riverpod providers for state management
final isLoadingProvider = StateProvider<bool>((ref) => true);
final surveysProvider = StateProvider<List<SurveyData>>((ref) => []);
final siteCodeProvider = StateProvider<String>((ref) => 'Loading...');
final siteNameProvider = StateProvider<String>((ref) => '');
final errorMessageProvider = StateProvider<String?>((ref) => null);

// HomeScreen UI
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSelectedSite();
      _fetchSurveys();

      // Listen for site selection changes
      ref.listen(selectedSiteProvider, (previous, next) {
        if (next != null && next != previous) {
          print('📍 Site changed to: ${next.siteCode}');
          _fetchSurveys(); // Refresh surveys when site changes
        }
      });
    });
  }

  // Load selected site from storage
  Future<void> _loadSelectedSite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final siteCode = prefs.getString(SiteLocation.selectedSiteKey);
      final siteName = prefs.getString(SiteLocation.selectedSiteNameKey);

      if (siteCode != null && siteName != null) {
        ref.read(siteCodeProvider.notifier).state = siteCode;
        ref.read(siteNameProvider.notifier).state = siteName;
        ref.read(selectedSiteProvider.notifier).state = SelectedSite(
          siteCode: siteCode,
          name: siteName,
        );
      } else {
        ref.read(siteCodeProvider.notifier).state = 'Select Site';
        ref.read(siteNameProvider.notifier).state = '';
      }
    } catch (e) {
      ref.read(siteCodeProvider.notifier).state = 'Select Site';
    }
  }

  // Fetch surveys from API
  Future<void> _fetchSurveys() async {
    final surveyApi = ref.read(surveyApiProvider);
    final selectedSite = ref.read(selectedSiteProvider);

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    try {
      final surveyList = await surveyApi.getSurveysByUser(
        siteCode: selectedSite?.siteCode,
      );

      if (surveyList.data != null && surveyList.data!.isNotEmpty) {
        ref.read(surveysProvider.notifier).state = surveyList.data!;
      } else {
        ref.read(surveysProvider.notifier).state = [];
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = e.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UAlert.show(
          title: 'Error',
          message: 'Failed to load surveys: ${e.toString().replaceAll('Exception: ', '')}',
          context: context,
        );
      });
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  // Open site location screen
  Future<void> _openSiteLocation() async {
    print('📱 Opening site location screen...');
    context.push(Routes.siteLocation, extra: {'isSelectionMode': true});
  }

  void _onStartSurvey(SurveyData survey) {
    final selectedSite = ref.read(selectedSiteProvider);
    final siteCode = selectedSite?.siteCode ?? '';

    context.go(
      Routes.question,
      extra: {'survey_data': survey.toJson(), 'site_code': siteCode},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final siteCode = ref.watch(siteCodeProvider);
    final siteName = ref.watch(siteNameProvider);
    final surveys = ref.watch(surveysProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final textColor = isDark ? UColors.white : UColors.dark;

    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UAlert.show(title: 'Error', message: errorMessage, context: context);
        ref.read(errorMessageProvider.notifier).state = null;
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/icons/circleIcon.png', width: 24, height: 24),
                  Text('Home', style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w900, color: UColors.darkerGrey,
                  )),
                  GestureDetector(
                    onTap: _openSiteLocation,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: Text(siteCode, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: UColors.primary, fontWeight: FontWeight.w600,
                              )),
                            ),
                            if (siteName.isNotEmpty) ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: Text(siteName, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: UColors.darkGrey)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Icon(Iconsax.location, size: 18, color: UColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
                  onRefresh: _fetchSurveys,
                  child: surveys.isEmpty ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Column(
                          children: [
                            Text('No surveys available', style: TextStyle(color: subtitleColor)),
                            if (siteCode != 'Select Site') Text('for site: $siteCode', style: TextStyle(color: subtitleColor, fontSize: 12)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _openSiteLocation, child: const Text('Change Site')),
                          ],
                        ),
                      ),
                    ],
                  ) : ListView.builder(
                    itemCount: surveys.length,
                    itemBuilder: (context, index) {
                      final survey = surveys[index];
                      final questionCount = survey.questions?.length ?? 0;
                      final estimatedTime = questionCount * 1;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0) Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 8),
                            child: Text(UTexts.availabileSurvey, style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: textColor, fontWeight: FontWeight.bold,
                            )),
                          ),
                          SurveyInfo(
                            title: survey.title ?? 'Untitled Survey',
                            totalQuestions: questionCount,
                            estimatedTime: '$estimatedTime min',
                            onStart: () => _onStartSurvey(survey),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}