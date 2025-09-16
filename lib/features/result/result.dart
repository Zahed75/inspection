// // lib/features/result/result.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // ← for preview/share

import 'package:inspection/features/result/provider/responseId_provider.dart';
import 'package:inspection/features/result/widgets/result_header.dart';
import 'package:inspection/features/result/widgets/summary_tab.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../app/router/routes.dart';
import '../../navigation_menu.dart';
import '../../services/survey_storage_service.dart';
import '../site/provider/state_provider.dart';
import 'model/survey_result_model.dart';
import 'notifier/result_notifier.dart';

import 'package:inspection/features/site/model/site_model.dart';

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
    _loadSavedSurveyResult();
  }

  // Load the saved survey result when the screen is loaded
  Future<void> _loadSavedSurveyResult() async {
    try {
      final savedResult = await SurveyStorageService.getSurveyResult();
      print('Loaded saved result: $savedResult');

      if (savedResult != null && savedResult.responseId != null) {
        // Use the saved result if available and valid
        ref
            .read(resultNotifierProvider.notifier)
            .state = AsyncValue.data(
          savedResult,
        );
        // Also update the latest response ID
        ref
            .read(latestResponseIdProvider.notifier)
            .state =
        savedResult.responseId!;
      } else {
        // If no saved result, fetch it from the API using the provided responseId
        _fetchResult(ref);
      }
    } catch (e) {
      print('Error loading saved result: $e');
      // Fallback to API fetch
      _fetchResult(ref);
    }
  }

  Future<void> _fetchResult(WidgetRef ref) async {
    final notifier = ref.read(resultNotifierProvider.notifier);
    await notifier.fetchSurveyResult(widget.responseId);
    ref
        .read(latestResponseIdProvider.notifier)
        .state = widget.responseId;
  }

  Map<String, dynamic> _processSurveyData(SurveyResultModel result) {
    final questions = result.submittedQuestions ?? [];
    final nonRemarks = questions.where((q) => _qType(q) != 'remarks').toList();
    final remarks = questions.where((q) => _qType(q) == 'remarks').toList();

    final Map<String, Map<String, dynamic>> categoryMap = {};
    for (final q in nonRemarks) {
      final categoryName = _qCategory(q);
      final categoryKey = categoryName.isNotEmpty ? categoryName : 'General';
      categoryMap.putIfAbsent(
        categoryKey,
            () =>
        {
          'name': categoryKey,
          'score': 0.0,
          'total': 0.0,
          'questions': [],
        },
      );
      final category = categoryMap[categoryKey]!;
      category['score'] = (category['score'] as double) + _qObtainedMarks(q);
      category['total'] = (category['total'] as double) + _qMaxMarks(q);
      (category['questions'] as List).add(q);
    }

    final categories = categoryMap.values.toList();

    String feedback = 'No feedback submitted.';
    if (remarks.isNotEmpty && (_qAnswer(remarks.first)
        .toString()
        .isNotEmpty)) {
      feedback = _qAnswer(remarks.first);
    }

    final resolvedSiteCode = (result.outletCode
        ?.trim()
        .isNotEmpty == true)
        ? result.outletCode!.trim()
        : (result.siteCode
        ?.trim()
        .isNotEmpty == true
        ? result.siteCode!.trim()
        : 'N/A');
    print(result.outletCode);

    return {
      'overall': {
        'obtainedMarks': result.obtainedScore?.toDouble() ?? 0,
        'totalMarks': result.totalScore?.toDouble() ?? 0,
        'percentage': (result.percentage ?? 0.0),
      },
      'categories': categories,
      'siteCode': resolvedSiteCode,
      'siteName': Null,
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

  static String _qCategory(dynamic q) {
    try {
      if (q is SubmittedQuestions) {
        if (q.categoryName != null && q.categoryName!.trim().isNotEmpty) {
          return q.categoryName!.trim();
        }
      }
    } catch (_) {}
    if (q is Map) {
      final v = q['category_name'] ?? q['categoryName'] ?? q['category'];
      if (v != null && v
          .toString()
          .trim()
          .isNotEmpty) {
        return v.toString().trim();
      }
    }
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

  String _surveyTitleFrom(SurveyResultModel result) {
    try {
      final d = result as dynamic;
      final candidates = [
        d.surveyTitle,
        d.title,
        d.surveyName,
        (d.survey != null) ? d.survey.title : null,
      ];
      for (final c in candidates) {
        if (c is String && c
            .trim()
            .isNotEmpty) return c.trim();
      }
    } catch (_) {}
    return 'Survey';
  }

  Map<String, String> _remarksByCategory(List allQuestions) {
    final map = <String, String>{};
    for (final q in allQuestions) {
      if (_qType(q) == 'remarks') {
        final cat = _qCategory(q).isNotEmpty ? _qCategory(q) : 'General';
        final txt = _qAnswer(q).trim();
        if (txt.isNotEmpty) map[cat] = txt;
      }
    }
    return map;
  }


  // --------- PDF builder with fixed header + spanned remarks ----------

  Future<Uint8List> _buildPdfBytesWithFormat(
      SurveyResultModel result,
      PdfPageFormat pageFormat, {
        required String resolvedSiteName, // ✅ Changed parameter name to match what's being passed
      }) async {
    final data = _processSurveyData(result);
    final siteName = resolvedSiteName; // ✅ Use the parameter directly

    final allQs = (result.submittedQuestions ?? []).toList();
    final nonRemarks = allQs.where((q) => _qType(q) != 'remarks').toList();
    final remarksMap = _remarksByCategory(allQs);

    final Map<String, List> byCategory = {};
    for (final q in nonRemarks) {
      final categoryName = _qCategory(q);
      final categoryKey = categoryName.isNotEmpty ? categoryName : 'General';
      byCategory.putIfAbsent(categoryKey, () => []).add(q);
    }

    final siteCode = (data['siteCode'] ?? result.siteCode ?? 'N/A').toString();
    final timestamp = _safeParseDate(data['timestamp']);
    final dateStr = DateFormat('MMMM d, y - h:mm a').format(timestamp);

    final surveyTitle = (() {
      if ((result.surveyTitle ?? '').trim().isNotEmpty) {
        return result.surveyTitle!.trim();
      }
      final fromData = (data['siteName']?.toString().trim() ?? '');
      if (fromData.isNotEmpty) return fromData;
      return _surveyTitleFrom(result);
    })();

    final overall = (data['overall'] as Map?) ?? {};
    final rawObt = (overall['obtainedMarks'] as num?)?.toDouble() ?? 0.0;
    final rawTot = (overall['totalMarks'] as num?)?.toDouble() ?? 0.0;
    final obtained = rawObt <= rawTot ? rawObt : rawTot;
    final total = rawTot >= rawObt ? rawTot : rawObt;
    final percent = total == 0 ? 0.0 : (obtained / total * 100.0);

    final overallFeedback = data['feedback']?.toString() ?? 'No feedback submitted.';

    final submitterName = (result.submittedBy ?? '').toString().trim();
    final submitterPhone = (result.submittedUserPhone ?? '').toString().trim();
    final submitterLine = [
      if (submitterName.isNotEmpty) submitterName,
      if (submitterPhone.isNotEmpty) '($submitterPhone)',
    ].join(' ').trim();

    final pdf = pw.Document();

    pw.Widget _chip(String label) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: PdfColors.deepPurple100,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.deepPurple200, width: 0.5),
        ),
        child: pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.deepPurple800,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    pw.Widget _metricCard({
      required String title,
      required String value,
      PdfColor color = PdfColors.deepPurple,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Add this method to your _ResultScreenState class
    pw.Widget _buildCategoryBlock(String catName, List qs, String catRemark) {
      // Compute category score
      double catObt = 0, catMax = 0;
      for (final q in qs) {
        catObt += _qObtainedMarks(q);
        catMax += _qMaxMarks(q);
      }
      final catPercent = catMax == 0 ? 0.0 : (catObt / catMax * 100.0);

      // Left table: No/Category/Question/Answer/Marks (NO per-row remarks)
      final leftTable = pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(28), // No.
          1: const pw.FlexColumnWidth(2), // Category
          2: const pw.FlexColumnWidth(3), // Question
          3: const pw.FlexColumnWidth(2), // Answer
          4: const pw.FixedColumnWidth(60), // Marks
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _buildPdfCell('No.', bold: true),
              _buildPdfCell('Category', bold: true),
              _buildPdfCell('Question', bold: true),
              _buildPdfCell('Answer', bold: true),
              _buildPdfCell('Marks', bold: true, alignEnd: true),
            ],
          ),
          ...qs.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            final qText = _qText(q);
            final qAns = _qAnswer(q);
            final om = _qObtainedMarks(q);
            final mm = _qMaxMarks(q);
            return pw.TableRow(
              decoration: i.isEven
                  ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF9F9F9))
                  : null,
              children: [
                _buildPdfCell('${i + 1}'),
                _buildPdfCell(catName),
                _buildPdfCell(qText),
                _buildPdfCell(qAns),
                _buildPdfCell(
                  '${om.toStringAsFixed(0)}/${mm.toStringAsFixed(0)}',
                  alignEnd: true,
                ),
              ],
            );
          }),
        ],
      );

      // Right "spanned" remarks panel (equal height via flexible layout)
      final rightRemarks = pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Remarks',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              (catRemark.isNotEmpty) ? catRemark : '—',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
            ),
          ],
        ),
      );

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  catName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Text(
                  '${catPercent.toStringAsFixed(1)}% - ${catObt.round()}/${catMax.round()}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(flex: 7, child: leftTable),
              pw.SizedBox(width: 8),
              pw.Expanded(flex: 3, child: rightRemarks),
            ],
          ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        build: (_) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.deepPurple50,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.deepPurple100, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  surveyTitle,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepPurple800,
                  ),
                ),

                pw.SizedBox(height: 8),

                pw.Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip('Site- $siteCode'),
                    _chip('Site Name- $resolvedSiteName'), // ✅ Use the parameter
                    _chip(dateStr),
                    if (submitterLine.isNotEmpty)
                      _chip('Submitted- $submitterLine'),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _metricCard(
                        title: 'Score',
                        value: '${obtained.round()}/${total.round()}',
                        color: PdfColors.deepPurple700,
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: _metricCard(
                        title: 'Total Percentage',
                        value: '${percent.toStringAsFixed(1)}%',
                        color: PdfColors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 18),


          ...byCategory.entries.map((entry) {
            final catName = entry.key;
            final qs = entry.value;
            final catRemark = remarksMap[catName] ?? '';
            return pw.Column(
              children: [
                _buildCategoryBlock(catName, qs, catRemark),
                pw.SizedBox(height: 12),
              ],
            );
          }),

          if (overallFeedback.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                border: pw.Border.all(color: PdfColors.indigo100, width: 0.8),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Feedback & Remarks',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.indigo800,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    overallFeedback,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
          ],
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


  pw.Widget _buildPdfCell(String text, {
    bool bold = false,
    bool alignEnd = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: alignEnd ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
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
    final baseName = filename.toLowerCase().endsWith('.pdf')
        ? filename.substring(0, filename.length - 4)
        : filename;

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final saver = FileSaver.instance as dynamic;
        String? saved;
        try {
          saved =
          await saver.saveFile(
            name: baseName,
            bytes: bytes,
            ext: 'pdf',
            mimeType: MimeType.pdf,
          )
          as String?;
        } catch (_) {
          try {
            saved =
            await saver.saveFile(baseName, bytes, 'pdf', MimeType.pdf)
            as String?;
          } catch (_) {}
        }
        if (saved != null && saved.isNotEmpty) {
          if (Platform.isAndroid && saved.startsWith('content://')) {
            return 'Downloads/$filename';
          }
          return saved;
        }
      } catch (_) {}
    }

    if (Platform.isAndroid) {
      for (final p in [
        ph.Permission.manageExternalStorage,
        ph.Permission.storage,
      ]) {
        try {
          final status = await p.request();
          if (status.isGranted) {
            final downloads = Directory('/storage/emulated/0/Download');
            if (await downloads.exists()) {
              final file = File('${downloads.path}/$filename');
              await file.writeAsBytes(bytes, flush: true);
              return file.path;
            }
          }
        } catch (_) {}
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _downloadPdf(SurveyResultModel result) async {
    setState(() => _exporting = true);
    try {
      // ✅ Use the site name directly from the API response
      final String siteName = result.siteName ?? 'Unknown Site';

      final bytes = await _buildPdfBytesWithFormat(
        result,
        PdfPageFormat.a4,
        resolvedSiteName: siteName, // ✅ Use correct parameter name
      );

      final filename = 'survey_${result.responseId ?? DateTime.now().millisecondsSinceEpoch}.pdf';

      final path = await _savePdfToBestPlace(bytes, filename);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      await Printing.sharePdf(bytes: bytes, filename: filename);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to:\n$path'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultState = ref.watch(resultNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Center(child: Text('Survey Result')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final currentRoute = GoRouter
                .of(context)
                .location;
            if (currentRoute == '/home') {
              ref
                  .read(selectedIndexProvider.notifier)
                  .state = 0;
            } else {
              context.goNamed(Routes.home);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Download / Preview',
            onPressed: _exporting ? null : () {
              final current = ref.read(resultNotifierProvider);
              current.when(
                data: (res) {
                  // ✅ Just call _downloadPdf with the result - it will use the site_name from API
                  _downloadPdf(res);
                },
                loading: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please wait, loading result...')),
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
        loading: () =>
            Center(
              child: CircularProgressIndicator(
                  color: theme.colorScheme.primary),
            ),
        error: (error, stackTrace) =>
            Center(
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

          final rawObt =
              (processedData['overall']?['obtainedMarks'] as num?)
                  ?.toDouble() ??
                  0.0;
          final rawTot =
              (processedData['overall']?['totalMarks'] as num?)?.toDouble() ??
                  0.0;
          final obtainedForCalc = rawObt <= rawTot ? rawObt : rawTot;
          final totalForCalc = rawTot >= rawObt ? rawTot : rawObt;
          final percent = totalForCalc == 0
              ? 0.0
              : obtainedForCalc / totalForCalc;
          final resultPercentLabel = '${(percent * 100).toStringAsFixed(1)}%';

          final String siteCode = (processedData['siteCode'] ?? 'N/A')
              .toString();

          final sitesAsync = ref.watch(allSitesProvider);
          String? siteNameResolved;
          sitesAsync.maybeWhen(
            data: (List<Sites> sites) {
              siteNameResolved = sites
                  .firstWhere(
                    (s) =>
                (s.siteCode ?? '').toString().trim() == siteCode.trim(),
                orElse: () => Sites(),
              )
                  .name;
            },
            orElse: () {},
          );

          final String? siteName = siteNameResolved;

          final DateTime timestamp = _safeParseDate(processedData['timestamp']);
          final String feedback =
              processedData['feedback']?.toString() ?? 'No feedback submitted.';

          final List<Map<String, dynamic>> categories =
              (processedData['categories'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
                  [];

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) =>
            [
              SliverToBoxAdapter(
                child: ResultHeader(
                  siteCode: siteCode,
                  siteName: siteName,
                  // shows clean name in UI
                  timestamp: timestamp,
                  totalScore: obtainedForCalc.round(),
                  maxScore: totalForCalc.round(),
                  percent: percent,
                  percentLabel: resultPercentLabel,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  height: 12,
                ),
              ),
            ],
            body: Container(
              color: theme.cardColor,
              child: SummaryTab(
                isDark: isDark,
                categories: categories,
                feedback: feedback,
                qType: _qType,
                qText: _qText,
                qAnswer: _qAnswer,
                qObtainedMarks: _qObtainedMarks,
                qMaxMarks: _qMaxMarks,
              ),
            ),
          );
        },
      ),
    );
  }
}

