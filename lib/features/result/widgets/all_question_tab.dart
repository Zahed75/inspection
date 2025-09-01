// lib/features/result/widgets/all_questions_tab.dart
import 'package:flutter/material.dart';

class AllQuestionsTab extends StatefulWidget {
  const AllQuestionsTab({
    super.key,
    required this.categories,
    required this.qType,
    required this.qText,
    required this.qAnswer,
  });

  final List<Map<String, dynamic>> categories;
  final String Function(dynamic) qType;
  final String Function(dynamic) qText;
  final String Function(dynamic) qAnswer;

  @override
  State<AllQuestionsTab> createState() => _AllQuestionsTabState();
}

class _AllQuestionsTabState extends State<AllQuestionsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // flatten with category name
    final all = <Map<String, String>>[];
    for (final cat in widget.categories) {
      final name = (cat['name'] ?? '').toString();
      final List qs = (cat['questions'] as List?) ?? const [];
      for (final q in qs) {
        if (widget.qType(q) == 'remarks') continue;
        all.add({
          'category': name,
          'text': widget.qText(q),
          'answer': widget.qAnswer(q),
        });
      }
    }

    final filtered = _query.trim().isEmpty
        ? all
        : all.where((e) {
            final t = (e['text'] ?? '').toLowerCase();
            final a = (e['answer'] ?? '').toLowerCase();
            final q = _query.toLowerCase();
            return t.contains(q) || a.contains(q);
          }).toList();

    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search questions or answers...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      onPressed: () => setState(() => _query = ''),
                    ),
            ),
          ),
        ),

        // Results
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No questions found',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          item['text'] ?? '',
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // In your all_questions_tab.dart
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Answer: ${item['answer']?.toString() ?? ''}', // Ensure toString()
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: theme.colorScheme.primary.withOpacity(0.1),
                          ),
                          child: Text(
                            item['category'] ?? '',
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: filtered.length,
                ),
        ),
      ],
    );
  }
}
