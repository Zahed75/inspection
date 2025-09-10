// lib/features/result/widgets/summary_tab.dart
import 'package:flutter/material.dart';
import 'dart:math';

import '../../question/model/survey_submit_model.dart';

class SummaryTab extends StatefulWidget {
  const SummaryTab({
    super.key,
    required this.isDark,
    required this.categories,
    required this.feedback,
    required this.qType,
    required this.qText,
    required this.qAnswer,
    required this.qObtainedMarks,
    required this.qMaxMarks,
  });

  final bool isDark;
  /// Incoming "categories" can be your old single-bucket like:
  /// [{'name':'Survey Questions','questions':[...]}]
  /// We will regroup those questions by category_name for display.
  final List<Map<String, dynamic>> categories;
  final String feedback;
  final String Function(dynamic) qType;
  final String Function(dynamic) qText;
  final String Function(dynamic) qAnswer;
  final double Function(dynamic) qObtainedMarks;
  final double Function(dynamic) qMaxMarks;

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  final Map<int, bool> _expandedCategories = {};
  final Map<int, int> _visibleQuestions = {};

  static const int _questionsPerLoad = 10;

  @override
  void initState() {
    super.initState();
    // We'll lazily initialize expansion per index after we compute groups in build.
  }

  /// --- Helpers to detect & read category name from a question ---
  /// --- Helpers to detect & read category name from a question ---
  String _categoryOf(dynamic q) {
    // 1) Try to extract from the question object directly
    try {
      if (q is Map<String, dynamic>) {
        // Handle Map objects (from JSON)
        final category = q['category_name'] ?? q['categoryName'] ?? q['category'];
        if (category != null && category.toString().trim().isNotEmpty) {
          return category.toString().trim();
        }
      } else if (q is SubmittedQuestions) {
        // Handle SubmittedQuestions model objects
        final d = q as dynamic;
        final c1 = d.categoryName;
        if (c1 is String && c1.trim().isNotEmpty) return c1.trim();
        final c2 = d.category;
        if (c2 is String && c2.trim().isNotEmpty) return c2.trim();
      }
    } catch (_) {
      // Fall through to other methods
    }

    // 2) If it's a Map with nested structure, try to extract
    if (q is Map) {
      final m = Map<String, dynamic>.from(q);

      // Try direct keys first
      final direct = m['category_name'] ?? m['categoryName'] ?? m['category'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }

      // Try nested in question object
      final question = m['question'];
      if (question is Map) {
        final nested = _categoryOf(Map<String, dynamic>.from(question));
        if (nested.isNotEmpty && nested != 'General') return nested;
      }
    }

    // 3) Fallback to text parsing (unchanged)
    final text = widget.qText(q);
    if (text.isNotEmpty) {
      final mBracket = RegExp(r'^\s*\[([^\]]+)\]\s*').firstMatch(text);
      if (mBracket != null) {
        final cat = mBracket.group(1)?.trim();
        if (cat != null && cat.isNotEmpty) return cat;
      }
      final mParen = RegExp(r'^\s*\(([^)]+)\)\s*').firstMatch(text);
      if (mParen != null) {
        final cat = mParen.group(1)?.trim();
        if (cat != null && cat.isNotEmpty) return cat;
      }
      final mDelim = RegExp(r'^\s*([^\-\:\•\|]{3,40}?)\s*[\:\-\•\|]\s+').firstMatch(text);
      if (mDelim != null) {
        final raw = (mDelim.group(1) ?? '').trim();
        final valid = raw.isNotEmpty &&
            raw.length <= 30 &&
            !raw.contains('?') &&
            RegExp(r'[A-Za-z]').hasMatch(raw);
        if (valid) return raw;
      }
    }

    // 4) Final fallback
    return 'General';
  }



  /// Take the incoming categories (which may be a single bucket)



  List<Map<String, dynamic>> _groupIntoCategories() {
    final looksGrouped = widget.categories.isNotEmpty &&
        widget.categories.every((c) => c.containsKey('questions'));

    if (looksGrouped) {
      final List<Map<String, dynamic>> out = [];
      for (final c in widget.categories) {
        final String name = (c['name'] ?? 'General').toString();
        final List qs = (c['questions'] as List?) ?? const [];
        double score = 0, total = 0;
        for (final q in qs) {
          score += widget.qObtainedMarks(q);
          total += widget.qMaxMarks(q);
        }
        out.add({
          'name': name,
          'score': score,
          'total': total,
          'questions': qs,
        });
      }
      return out;
    }

    // fallback regrouping (when API didn't send category blocks)
    final List allQs = [];
    for (final c in widget.categories) {
      final qs = (c['questions'] as List?) ?? const [];
      allQs.addAll(qs);
    }

    final Map<String, Map<String, dynamic>> grouped = {};
    for (final q in allQs) {
      final cat = _categoryOf(q);
      final obtained = widget.qObtainedMarks(q);
      final max = widget.qMaxMarks(q);

      final bucket = grouped.putIfAbsent(cat, () {
        return {
          'name': cat,
          'score': 0.0,
          'total': 0.0,
          'questions': <dynamic>[],
        };
      });

      bucket['questions'].add(q);
      bucket['score'] = (bucket['score'] as double) + obtained;
      bucket['total'] = (bucket['total'] as double) + max;
    }

    final list = grouped.values.toList();
    list.sort((a, b) => (a['name'] as String)
        .toLowerCase()
        .compareTo((b['name'] as String).toLowerCase()));
    return list;
  }



  /// Ensure per-category expansion/pagination maps have defaults
  void _ensureStateForLength(int len) {
    for (int i = 0; i < len; i++) {
      _expandedCategories.putIfAbsent(i, () => true); // expanded by default
      _visibleQuestions.putIfAbsent(i, () => _questionsPerLoad);
    }
    // Clean up any extra keys if categories shrank
    _expandedCategories.removeWhere((k, v) => k >= len);
    _visibleQuestions.removeWhere((k, v) => k >= len);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // New: regroup questions by category_name for display
    final groupedCategories = _groupIntoCategories();
    _ensureStateForLength(groupedCategories.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories List
          ..._buildCategoriesList(theme, textTheme, groupedCategories),

          // Feedback Section
          _buildFeedbackSection(theme, textTheme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScoreMetric(
      String label,
      String value,
      Color color,
      ThemeData theme,
      ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategoriesList(
      ThemeData theme,
      TextTheme textTheme,
      List<Map<String, dynamic>> groupedCategories,
      ) {
    return groupedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value;
      final name = (cat['name'] ?? '').toString();
      final score = (cat['score'] as num? ?? 0).toDouble();
      final total = (cat['total'] as num? ?? 0).toDouble();
      final List qs = (cat['questions'] as List?) ?? const [];
      final percent = total == 0 ? 0.0 : (score / total);
      final isExpanded = _expandedCategories[index] ?? true;
      final visibleCount = _visibleQuestions[index] ?? _questionsPerLoad;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Category Header (unchanged UI)
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              title: Text(
                name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percent.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor:
                          theme.colorScheme.surface.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getScoreColor(percent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getScoreColor(percent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              onTap: () => setState(() {
                _expandedCategories[index] = !isExpanded;
              }),
            ),

            // Questions List (if expanded)
            if (isExpanded) ...[
              const Divider(height: 1),
              ..._buildQuestionsList(qs, visibleCount, index, theme, textTheme),
            ],
          ],
        ),
      );
    }).toList();
  }

  // GET CATEGORY NAME
  String _getCategoryName(dynamic q) {
    // 1) Try to get categoryName directly from SubmittedQuestions model
    try {
      if (q is SubmittedQuestions) {
        if (q.categoryName != null && q.categoryName!.trim().isNotEmpty) {
          return q.categoryName!.trim();
        }
      }
    } catch (_) {
      // Fall through to other methods
    }

    // 2) Try to get from Map if it's not a SubmittedQuestions object
    if (q is Map) {
      final category = q['category_name'] ?? q['categoryName'];
      if (category != null && category.toString().trim().isNotEmpty) {
        return category.toString().trim();
      }
    }

    // 3) Fallback to empty string (no category will be displayed)
    return '';
  }

  List<Widget> _buildQuestionsList(
      List<dynamic> questions,
      int visibleCount,
      int categoryIndex,
      ThemeData theme,
      TextTheme textTheme,
      ) {
    final displayedQuestions = questions.take(visibleCount).toList();
    final canShowMore = visibleCount < questions.length;

    return [
      ...displayedQuestions.asMap().entries.map((qEntry) {
        final qIndex = qEntry.key;
        final q = qEntry.value;
        final text = widget.qText(q);
        final answer = widget.qAnswer(q);
        final obtainedMarks = widget.qObtainedMarks(q);
        final maxMarks = widget.qMaxMarks(q);
        final questionPercent = maxMarks > 0 ? obtainedMarks / maxMarks : 0.0;

        // NEW: Extract category name from the question
        final categoryName = _getCategoryName(q);

        return Container(
          color: qIndex.isEven ? theme.colorScheme.surface.withOpacity(0.1) : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question Number
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: _getQuestionColor(questionPercent.toDouble()),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${qIndex + 1}',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Question Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NEW: Display category name above question
                    if (categoryName.isNotEmpty && categoryName != 'General')
                      Text(
                        categoryName,
                        style: textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (categoryName.isNotEmpty && categoryName != 'General')
                      const SizedBox(height: 4),

                    Text(
                      text,
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      answer,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Score Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getQuestionColor(
                              questionPercent.toDouble(),
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$obtainedMarks/$maxMarks',
                            style: textTheme.labelSmall?.copyWith(
                              color: _getQuestionColor(
                                questionPercent.toDouble(),
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Percentage
                        Text(
                          '${(questionPercent * 100).toStringAsFixed(0)}%',
                          style: textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),

      // Show More Button (unchanged)
      if (canShowMore)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ElevatedButton(
              onPressed: () => setState(() {
                _visibleQuestions[categoryIndex] =
                    visibleCount + _questionsPerLoad;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Show ${min(_questionsPerLoad, questions.length - visibleCount)} More Questions',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildFeedbackSection(ThemeData theme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.feedback, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'FEEDBACK & REMARKS',
                style: textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.feedback,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percent) {
    if (percent >= 0.8) return Colors.deepPurple;
    if (percent >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getQuestionColor(double percent) {
    if (percent >= 1.0) return Colors.deepPurpleAccent;
    if (percent >= 0.5) return Colors.orange;
    if (percent > 0) return Colors.blue;
    return Colors.grey;
  }
}
