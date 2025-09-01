// lib/features/result/widgets/summary_tab.dart
import 'package:flutter/material.dart';
import 'dart:math';

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
    // Initialize all categories as expanded
    for (int i = 0; i < widget.categories.length; i++) {
      _expandedCategories[i] = true;
      _visibleQuestions[i] = _questionsPerLoad;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories List
          ..._buildCategoriesList(theme, textTheme),

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

  List<Widget> _buildCategoriesList(ThemeData theme, TextTheme textTheme) {
    return widget.categories.asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value;
      final name = (cat['name'] ?? '').toString();
      final score = (cat['score'] as num? ?? 0).toDouble();
      final total = (cat['total'] as num? ?? 0).toDouble();
      final List qs = (cat['questions'] as List?) ?? const [];
      final percent = total == 0 ? 0.0 : (score / total);
      final isExpanded = _expandedCategories[index] ?? false;
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
            // Category Header
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
                          backgroundColor: theme.colorScheme.surface
                              .withOpacity(0.3),
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

        return Container(
          color: qIndex.isEven
              ? theme.colorScheme.surface.withOpacity(0.1)
              : null,
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
                    Text(
                      text,
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // In your summary_tab.dart, ensure the answer display handles any type
                    Text(
                      widget.qAnswer(
                        q,
                      ), // This will call toString() on any type
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

      // Show More Button
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
