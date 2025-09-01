// lib/features/result/result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/features/result/provider/responseId_provider.dart';
import 'package:inspection/features/result/widgets/all_question_tab.dart';
import 'package:inspection/features/result/widgets/result_header.dart';
import 'package:inspection/features/result/widgets/summary_tab.dart';

import '../../app/router/routes.dart';
import '../../navigation_menu.dart';
import 'model/survey_result_model.dart';
import 'notifier/result_notifier.dart';

// Remove old providers and use the new notifier
final resultNotifierProvider =
    StateNotifierProvider<ResultNotifier, AsyncValue<SurveyResultModel>>((ref) {
      return ResultNotifier(ref);
    });

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.responseId});
  final int responseId;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchResult(ref));
  }

  Future<void> _fetchResult(WidgetRef ref) async {
    final notifier = ref.read(resultNotifierProvider.notifier);
    await notifier.fetchSurveyResult(widget.responseId);
    ref.read(latestResponseIdProvider.notifier).state = widget.responseId;
  }

  // Helper methods to process API data
  Map<String, dynamic> _processSurveyData(SurveyResultModel result) {
    // Group questions by category (you might need to adjust this based on your actual data structure)
    final categories = <Map<String, dynamic>>[];

    // For now, let's assume all questions are in one category
    // You might need to modify this based on how your API returns categories
    final questions = result.submittedQuestions ?? [];

    final nonRemarksQuestions = questions
        .where((q) => q.type != 'remarks')
        .toList();
    final remarks = questions.where((q) => q.type == 'remarks').toList();

    categories.add({
      'name': 'Survey Questions',
      'obtainedMarks': result.obtainedScore?.toDouble() ?? 0,
      'totalMarks': result.totalScore?.toDouble() ?? 0,
      'questions': nonRemarksQuestions,
    });

    // Get feedback from remarks
    String feedback = 'No feedback submitted.';
    if (remarks.isNotEmpty && remarks.first.answer?.isNotEmpty == true) {
      feedback = remarks.first.answer!;
    }

    return {
      'overall': {
        'obtainedMarks': result.obtainedScore?.toDouble() ?? 0,
        'totalMarks': result.totalScore?.toDouble() ?? 0,
        'percentage': result.percentage ?? 0.0,
      },
      'categories': categories,
      'siteCode': result.siteCode ?? 'N/A',
      'siteName': result.outletCode ?? 'Unknown Site',
      'timestamp': result.submittedAt ?? DateTime.now().toIso8601String(),
      'feedback': feedback,
    };
  }

  // Helper methods for question processing
  static String _qType(dynamic q) {
    if (q is SubmittedQuestions) return q.type ?? '';
    if (q is Map) return (q['type'] ?? '').toString();
    return '';
  }

  static String _qText(dynamic q) {
    if (q is SubmittedQuestions) return q.questionText ?? '';
    if (q is Map) return (q['text'] ?? '').toString();
    return '';
  }

  // In your result_screen.dart, update the _qAnswer helper method:
  static String _qAnswer(dynamic q) {
    if (q is SubmittedQuestions) return q.answer?.toString() ?? '';
    if (q is Map) return (q['answer'] ?? '').toString();
    return '';
  }

  // In your result_screen.dart, update the helper methods:
  static double _qObtainedMarks(dynamic q) {
    if (q is SubmittedQuestions) return q.obtainedMarks ?? 0;
    if (q is Map) return (q['obtainedMarks'] as num?)?.toDouble() ?? 0;
    return 0;
  }

  static double _qMaxMarks(dynamic q) {
    if (q is SubmittedQuestions) return (q.maxMarks ?? 0).toDouble();
    if (q is Map) return (q['maxMarks'] as num?)?.toDouble() ?? 0;
    return 0;
  }

  static DateTime _safeParseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final resultState = ref.watch(resultNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor, // FIX: Changed from transparent
      // In your ResultScreen's build method, update the AppBar
      appBar: AppBar(
        title: const Text('Survey Result'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we're in the History tab of NavigationMenu
            final currentRoute = GoRouter.of(context).location;

            if (currentRoute == '/home') {
              // If we're already in home (History tab), just switch to Home tab
              ref.read(selectedIndexProvider.notifier).state = 0;
            } else {
              // If we're in standalone ResultScreen, navigate back to home
              context.goNamed(Routes.home);
            }
          },
        ),
      ),
      body: resultState.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error.toString().contains('token') ||
                        error.toString().contains('Authorization')
                    ? 'Authentication failed. Please login again.'
                    : 'Failed to load survey result: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _fetchResult(ref),
                child: const Text('Retry'),
              ),
              if (error.toString().contains('token'))
                TextButton(
                  onPressed: () {
                    context.goNamed(Routes.signIn);
                  },
                  child: const Text('Go to Login'),
                ),
            ],
          ),
        ),
        data: (result) {
          final processedData = _processSurveyData(result);

          final totalScore =
              (processedData['overall']?['obtainedMarks'] as num?)
                  ?.toDouble() ??
              0;
          final maxScore =
              (processedData['overall']?['totalMarks'] as num?)?.toDouble() ??
              0;
          final percent = maxScore == 0 ? 0.0 : totalScore / maxScore;
          final resultPercentLabel = '${(percent * 100).toStringAsFixed(1)}%';

          final String siteCode = (processedData['siteCode'] ?? 'N/A')
              .toString();
          final String? siteName = processedData['siteName']?.toString();
          final DateTime timestamp = _safeParseDate(processedData['timestamp']);
          final String feedback =
              processedData['feedback']?.toString() ?? 'No feedback submitted.';

          final List<Map<String, dynamic>> categories =
              (processedData['categories'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Fixed Header
                ResultHeader(
                  siteCode: siteCode,
                  siteName: siteName,
                  timestamp: timestamp,
                  totalScore: totalScore.round(),
                  maxScore: maxScore.round(),
                  percent: percent,
                  percentLabel: resultPercentLabel,
                ),

                // Fixed Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: TabBar(
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface
                        .withOpacity(0.6),
                    tabs: const [
                      Tab(text: 'Summary'),
                      Tab(text: 'All Questions'),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: Container(
                    color: theme.cardColor, // FIX: Changed from transparent
                    child: TabBarView(
                      children: [
                        // SUMMARY TAB
                        SummaryTab(
                          isDark: isDark,
                          categories: categories,
                          feedback: feedback,
                          qType: _qType,
                          qText: _qText,
                          qAnswer: _qAnswer,
                          qObtainedMarks: _qObtainedMarks,
                          qMaxMarks: _qMaxMarks,
                        ),

                        // ALL QUESTIONS TAB
                        AllQuestionsTab(
                          categories: categories,
                          qType: _qType,
                          qText: _qText,
                          qAnswer: _qAnswer,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
