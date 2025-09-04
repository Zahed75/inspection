// // lib/features/result/result_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:inspection/features/result/provider/responseId_provider.dart';
// import 'package:inspection/features/result/widgets/all_question_tab.dart';
// import 'package:inspection/features/result/widgets/result_header.dart';
// import 'package:inspection/features/result/widgets/summary_tab.dart';
// import '../../app/router/routes.dart';
// import '../../navigation_menu.dart';
// import 'model/survey_result_model.dart';
// import 'notifier/result_notifier.dart';
//
// // Remove old providers and use the new notifier
// final resultNotifierProvider =
//     StateNotifierProvider<ResultNotifier, AsyncValue<SurveyResultModel>>((ref) {
//       return ResultNotifier(ref);
//     });
//
// class ResultScreen extends ConsumerStatefulWidget {
//   const ResultScreen({super.key, required this.responseId});
//
//   final int responseId;
//
//   @override
//   ConsumerState<ResultScreen> createState() => _ResultScreenState();
// }
//
// class _ResultScreenState extends ConsumerState<ResultScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _fetchResult(ref));
//   }
//
//   Future<void> _fetchResult(WidgetRef ref) async {
//     final notifier = ref.read(resultNotifierProvider.notifier);
//     await notifier.fetchSurveyResult(widget.responseId);
//     ref.read(latestResponseIdProvider.notifier).state = widget.responseId;
//   }
//
//   // Helper methods to process API data
//   Map<String, dynamic> _processSurveyData(SurveyResultModel result) {
//     // Group questions by category (you might need to adjust this based on your actual data structure)
//     final categories = <Map<String, dynamic>>[];
//
//     // For now, let's assume all questions are in one category
//     // You might need to modify this based on how your API returns categories
//     final questions = result.submittedQuestions ?? [];
//
//     final nonRemarksQuestions = questions
//         .where((q) => q.type != 'remarks')
//         .toList();
//     final remarks = questions.where((q) => q.type == 'remarks').toList();
//
//     categories.add({
//       'name': 'Survey Questions',
//       'obtainedMarks': result.obtainedScore?.toDouble() ?? 0,
//       'totalMarks': result.totalScore?.toDouble() ?? 0,
//       'questions': nonRemarksQuestions,
//     });
//
//     // Get feedback from remarks
//     String feedback = 'No feedback submitted.';
//     if (remarks.isNotEmpty && remarks.first.answer?.isNotEmpty == true) {
//       feedback = remarks.first.answer!;
//     }
//
//     return {
//       'overall': {
//         'obtainedMarks': result.obtainedScore?.toDouble() ?? 0,
//         'totalMarks': result.totalScore?.toDouble() ?? 0,
//         'percentage': result.percentage ?? 0.0,
//       },
//       'categories': categories,
//       'siteCode': result.siteCode ?? 'N/A',
//       'siteName': result.outletCode ?? 'Unknown Site',
//       'timestamp': result.submittedAt ?? DateTime.now().toIso8601String(),
//       'feedback': feedback,
//     };
//   }
//
//   // Helper methods for question processing
//   static String _qType(dynamic q) {
//     if (q is SubmittedQuestions) return q.type ?? '';
//     if (q is Map) return (q['type'] ?? '').toString();
//     return '';
//   }
//
//   static String _qText(dynamic q) {
//     if (q is SubmittedQuestions) return q.questionText ?? '';
//     if (q is Map) return (q['text'] ?? '').toString();
//     return '';
//   }
//
//   // In your result_screen.dart, update the _qAnswer helper method:
//   static String _qAnswer(dynamic q) {
//     if (q is SubmittedQuestions) return q.answer?.toString() ?? '';
//     if (q is Map) return (q['answer'] ?? '').toString();
//     return '';
//   }
//
//   // In your result_screen.dart, update the helper methods:
//   static double _qObtainedMarks(dynamic q) {
//     if (q is SubmittedQuestions) return q.obtainedMarks ?? 0;
//     if (q is Map) return (q['obtainedMarks'] as num?)?.toDouble() ?? 0;
//     return 0;
//   }
//
//   static double _qMaxMarks(dynamic q) {
//     if (q is SubmittedQuestions) return (q.maxMarks ?? 0).toDouble();
//     if (q is Map) return (q['maxMarks'] as num?)?.toDouble() ?? 0;
//     return 0;
//   }
//
//   static DateTime _safeParseDate(dynamic v) {
//     if (v is DateTime) return v;
//     if (v is String) {
//       try {
//         return DateTime.parse(v);
//       } catch (_) {}
//     }
//     return DateTime.now();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final resultState = ref.watch(resultNotifierProvider);
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//
//     return Scaffold(
//       backgroundColor:
//           theme.scaffoldBackgroundColor, // FIX: Changed from transparent
//       // In your ResultScreen's build method, update the AppBar
//       appBar: AppBar(
//         title: const Text('Survey Result'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             // Check if we're in the History tab of NavigationMenu
//             final currentRoute = GoRouter.of(context).location;
//
//             if (currentRoute == '/home') {
//               // If we're already in home (History tab), just switch to Home tab
//               ref.read(selectedIndexProvider.notifier).state = 0;
//             } else {
//               // If we're in standalone ResultScreen, navigate back to home
//               context.goNamed(Routes.home);
//             }
//           },
//         ),
//       ),
//       body: resultState.when(
//         loading: () => Center(
//           child: CircularProgressIndicator(color: theme.colorScheme.primary),
//         ),
//         error: (error, stackTrace) => Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 error.toString().contains('token') ||
//                         error.toString().contains('Authorization')
//                     ? 'Authentication failed. Please login again.'
//                     : 'Failed to load survey result: $error',
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 12),
//               FilledButton(
//                 onPressed: () => _fetchResult(ref),
//                 child: const Text('Retry'),
//               ),
//               if (error.toString().contains('token'))
//                 TextButton(
//                   onPressed: () {
//                     context.goNamed(Routes.signIn);
//                   },
//                   child: const Text('Go to Login'),
//                 ),
//             ],
//           ),
//         ),
//         data: (result) {
//           final processedData = _processSurveyData(result);
//
//           final totalScore =
//               (processedData['overall']?['obtainedMarks'] as num?)
//                   ?.toDouble() ??
//               0;
//           final maxScore =
//               (processedData['overall']?['totalMarks'] as num?)?.toDouble() ??
//               0;
//           final percent = maxScore == 0 ? 0.0 : totalScore / maxScore;
//           final resultPercentLabel = '${(percent * 100).toStringAsFixed(1)}%';
//
//           final String siteCode = (processedData['siteCode'] ?? 'N/A')
//               .toString();
//           final String? siteName = processedData['siteName']?.toString();
//           final DateTime timestamp = _safeParseDate(processedData['timestamp']);
//           final String feedback =
//               processedData['feedback']?.toString() ?? 'No feedback submitted.';
//
//           final List<Map<String, dynamic>> categories =
//               (processedData['categories'] as List?)
//                   ?.cast<Map<String, dynamic>>() ??
//               [];
//
//           return DefaultTabController(
//             length: 2,
//             child: Column(
//               children: [
//                 // Fixed Header
//                 ResultHeader(
//                   siteCode: siteCode,
//                   siteName: siteName,
//                   timestamp: timestamp,
//                   totalScore: totalScore.round(),
//                   maxScore: maxScore.round(),
//                   percent: percent,
//                   percentLabel: resultPercentLabel,
//                 ),
//
//                 // Fixed Tab Bar
//                 Container(
//                   decoration: BoxDecoration(
//                     color: theme.cardColor,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: TabBar(
//                     indicatorColor: theme.colorScheme.primary,
//                     labelColor: theme.colorScheme.primary,
//                     unselectedLabelColor: theme.colorScheme.onSurface
//                         .withOpacity(0.6),
//                     tabs: const [
//                       Tab(text: 'Summary'),
//                       Tab(text: 'All Questions'),
//                     ],
//                   ),
//                 ),
//
//                 // Scrollable Content
//                 Expanded(
//                   child: Container(
//                     color: theme.cardColor, // FIX: Changed from transparent
//                     child: TabBarView(
//                       children: [
//                         // SUMMARY TAB
//                         SummaryTab(
//                           isDark: isDark,
//                           categories: categories,
//                           feedback: feedback,
//                           qType: _qType,
//                           qText: _qText,
//                           qAnswer: _qAnswer,
//                           qObtainedMarks: _qObtainedMarks,
//                           qMaxMarks: _qMaxMarks,
//                         ),
//
//                         // ALL QUESTIONS TAB
//                         AllQuestionsTab(
//                           categories: categories,
//                           qType: _qType,
//                           qText: _qText,
//                           qAnswer: _qAnswer,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }




// lib/features/result/result.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:inspection/features/result/provider/responseId_provider.dart';
import 'package:inspection/features/result/widgets/all_question_tab.dart';
import 'package:inspection/features/result/widgets/result_header.dart';
import 'package:inspection/features/result/widgets/summary_tab.dart';
import '../../app/router/routes.dart';
import '../../navigation_menu.dart';
import 'model/survey_result_model.dart';
import 'notifier/result_notifier.dart';

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
  bool _exporting = false;

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

  // ---------------- PDF helpers ----------------

  /// Build PDF honoring the page format
  Future<Uint8List> _buildPdfBytesWithFormat(
      SurveyResultModel result,
      PdfPageFormat pageFormat,
      ) async {
    final data = _processSurveyData(result);
    final siteCode = (data['siteCode'] ?? 'N/A').toString();
    final siteName = data['siteName']?.toString();
    final timestamp = _safeParseDate(data['timestamp']);

    final overall = (data['overall'] as Map?) ?? {};

    // --- Normalize obtained/total and compute percentage from scores ---
    final rawObt = (overall['obtainedMarks'] as num?)?.toDouble() ?? 0.0;
    final rawTot = (overall['totalMarks'] as num?)?.toDouble() ?? 0.0;

    // keep display order correct if server sends swapped values
    final obt = rawObt <= rawTot ? rawObt : rawTot;
    final tot = rawTot >= rawObt ? rawTot : rawObt;

    // Always compute % from scores so it matches screen
    final percent = tot == 0 ? 0.0 : (obt / tot * 100.0);
    // ------------------------------------------------------------------

    final feedback = data['feedback']?.toString() ?? 'No feedback submitted.';
    final categories =
        (data['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final pdf = pw.Document();
    final dateStr = DateFormat('MMMM d, y • h:mm a').format(timestamp);

    pw.Widget _cell(String text, {bool bold = false, bool alignEnd = false}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        alignment:
        alignEnd ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        build: (_) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SURVEY RESULT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    siteCode,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  if (siteName != null && siteName.isNotEmpty)
                    pw.Text(
                      siteName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 10,
                        height: 10,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey500,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        dateStr,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Score card
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Score',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${obt.round()}/${tot.round()}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    // Progress bar
                    pw.Stack(
                      children: [
                        pw.Container(
                          width: 120,
                          height: 8,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                        ),
                        pw.Container(
                          width: 120 * ((percent / 100.0).clamp(0.0, 1.0)),
                          height: 8,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.deepPurple,
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.deepPurple,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 18),
          pw.Divider(color: PdfColors.grey300),

          // Categories with Category + Remarks columns (kept)
          ...categories.expand((cat) {
            final name = (cat['name'] ?? '').toString();
            final List qs = (cat['questions'] as List?) ?? const [];
            double catObt = 0;
            double catMax = 0;
            for (final q in qs) {
              catObt += _qObtainedMarks(q);
              catMax += _qMaxMarks(q);
            }
            final catPercent = catMax == 0 ? 0.0 : (catObt / catMax);

            return [
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    name,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    '${(catPercent * 100).toStringAsFixed(0)}%  •  ${catObt.round()}/${catMax.round()}',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border:
                pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28), // No.
                  1: const pw.FlexColumnWidth(2), // Category
                  2: const pw.FlexColumnWidth(3), // Question
                  3: const pw.FlexColumnWidth(2), // Answer
                  4: const pw.FixedColumnWidth(60), // Marks
                  5: const pw.FlexColumnWidth(3), // Remarks
                },
                children: [
                  pw.TableRow(
                    decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('No.', bold: true),
                      _cell('Category', bold: true),
                      _cell('Question', bold: true),
                      _cell('Answer', bold: true),
                      _cell('Marks', bold: true, alignEnd: true),
                      _cell('Remarks', bold: true),
                    ],
                  ),
                  ...List.generate(qs.length, (i) {
                    final q = qs[i];
                    final qText = _qText(q);
                    final qAns = _qAnswer(q);
                    final om = _qObtainedMarks(q);
                    final mm = _qMaxMarks(q);

                    // Use the question's category_name/categoryName when available
                    final qCategory =
                    _qCategory(q).isNotEmpty ? _qCategory(q) : name;

                    return pw.TableRow(
                      decoration: i.isEven
                          ? const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF9F9F9),
                      )
                          : null,
                      children: [
                        _cell('${i + 1}'),
                        _cell(qCategory), // <-- Category column fixed here
                        _cell(qText),
                        _cell(qAns),
                        _cell(
                          '${om.toStringAsFixed(0)}/${mm.toStringAsFixed(0)}',
                          alignEnd: true,
                        ),
                        _cell(''), // Remarks column left empty as before
                      ],
                    );
                  }),
                  // Overall remarks row (kept)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFF3F4F6),
                    ),
                    children: [
                      _cell('-'),
                      _cell('Remarks', bold: true),
                      _cell('-'),
                      _cell('-'),
                      _cell('-', alignEnd: true),
                      _cell(feedback),
                    ],
                  ),
                ],
              ),
            ];
          }).toList(),

          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300),

          // Feedback section (kept)
          pw.Text(
            'Feedback & Remarks',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.deepPurple,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            feedback,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildMinimalPdfBytes({String? message}) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (_) =>
            pw.Center(child: pw.Text(message ?? 'PDF could not be generated.')),
      ),
    );
    return await doc.save();
  }

  Future<String> _savePdfToBestPlace(Uint8List bytes, String filename) async {
    if (Platform.isAndroid) {
      try {
        final downloads = Directory('/storage/emulated/0/Download');
        if (await downloads.exists()) {
          final file = File('${downloads.path}/$filename');
          await file.writeAsBytes(bytes);
          return file.path;
        }
      } catch (_) {}
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ---------------- /PDF helpers ----------------

  Future<void> _downloadPdf(SurveyResultModel result) async {
    setState(() => _exporting = true);
    try {
      final bytes = await _buildPdfBytesWithFormat(result, PdfPageFormat.a4);
      final filename =
          'survey_${result.responseId ?? DateTime.now().millisecondsSinceEpoch}.pdf';
      final path = await _savePdfToBestPlace(bytes, filename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to:\n$path'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save PDF: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ---------------- data processors ----------------

  Map<String, dynamic> _processSurveyData(SurveyResultModel result) {
    final categories = <Map<String, dynamic>>[];

    final questions = result.submittedQuestions ?? [];
    final nonRemarks = questions.where((q) => q.type != 'remarks').toList();
    final remarks = questions.where((q) => q.type == 'remarks').toList();

    categories.add({
      'name': 'Survey Questions',
      'obtainedMarks': result.obtainedScore?.toDouble() ?? 0,
      'totalMarks': result.totalScore?.toDouble() ?? 0,
      'questions': nonRemarks,
    });

    String feedback = 'No feedback submitted.';
    if (remarks.isNotEmpty &&
        (remarks.first.answer?.toString().isNotEmpty ?? false)) {
      feedback = remarks.first.answer.toString();
    }

    return {
      'overall': {
        'obtainedMarks': result.obtainedScore?.toDouble() ?? 0,
        'totalMarks': result.totalScore?.toDouble() ?? 0,
        // keep API percentage out of math; we compute from scores
        'percentage': (result.percentage ?? 0.0),
      },
      'categories': categories,
      'siteCode': result.siteCode ?? 'N/A',
      'siteName': result.outletCode ?? 'Unknown Site',
      'timestamp': result.submittedAt ?? DateTime.now().toIso8601String(),
      'feedback': feedback,
    };
  }

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

  static String _qAnswer(dynamic q) {
    if (q is SubmittedQuestions) return q.answer?.toString() ?? '';
    if (q is Map) return (q['answer'] ?? '').toString();
    return '';
  }

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

  /// Returns the question's category if present (supports both camelCase and snake_case),
  /// otherwise returns an empty string.
  static String _qCategory(dynamic q) {
    // If it's a model, try reading category fields (using dynamic to avoid hard dependency)
    try {
      if (q is SubmittedQuestions) {
        final String? c1 = (q as dynamic).categoryName as String?;
        final String? c2 = (q as dynamic).category as String?;
        if (c1 != null && c1.isNotEmpty) return c1;
        if (c2 != null && c2.isNotEmpty) return c2;
      }
    } catch (_) {
      // fall through to map handling
    }

    // If it's a map, try both styles
    if (q is Map) {
      final v = q['categoryName'] ?? q['category_name'] ?? q['category'];
      if (v != null) return v.toString();
    }

    // Fallback
    return '';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Survey Result'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final currentRoute = GoRouter.of(context).location;
            if (currentRoute == '/home') {
              ref.read(selectedIndexProvider.notifier).state = 0;
            } else {
              context.goNamed(Routes.home);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: _exporting
                ? null
                : () {
              final current = ref.read(resultNotifierProvider);
              current.when(
                data: (res) => _downloadPdf(res),
                loading: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please wait, loading result...'),
                  ),
                ),
                error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cannot export: $e')),
                ),
              );
            },
            icon: _exporting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.download_rounded),
          ),
        ],
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
                  onPressed: () => context.goNamed(Routes.signIn),
                  child: const Text('Go to Login'),
                ),
            ],
          ),
        ),
        data: (result) {
          final processedData = _processSurveyData(result);

          // Normalize here too so header ring & label are always right
          final rawObt =
              (processedData['overall']?['obtainedMarks'] as num?)
                  ?.toDouble() ??
                  0.0;
          final rawTot =
              (processedData['overall']?['totalMarks'] as num?)?.toDouble() ??
                  0.0;
          final obtainedForCalc = rawObt <= rawTot ? rawObt : rawTot;
          final totalForCalc = rawTot >= rawObt ? rawTot : rawObt;

          final percent =
          totalForCalc == 0 ? 0.0 : obtainedForCalc / totalForCalc;
          final resultPercentLabel = '${(percent * 100).toStringAsFixed(1)}%';

          final String siteCode =
          (processedData['siteCode'] ?? 'N/A').toString();
          final String? siteName = processedData['siteName']?.toString();
          final DateTime timestamp =
          _safeParseDate(processedData['timestamp']);
          final String feedback = processedData['feedback']?.toString() ??
              'No feedback submitted.';

          final List<Map<String, dynamic>> categories =
              (processedData['categories'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
                  [];

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                ResultHeader(
                  siteCode: siteCode,
                  siteName: siteName,
                  timestamp: timestamp,
                  // pass normalized order so header shows e.g. 30/50
                  totalScore: obtainedForCalc.round(),
                  maxScore: totalForCalc.round(),
                  percent: percent, // 0..1
                  percentLabel: resultPercentLabel,
                ),
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
                    unselectedLabelColor:
                    theme.colorScheme.onSurface.withOpacity(0.6),
                    tabs: const [
                      Tab(text: 'Summary'),
                      Tab(text: 'All Questions'),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: theme.cardColor,
                    child: TabBarView(
                      children: [
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
