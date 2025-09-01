import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Survey state provider
final surveyProvider = StateProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) {
  // Placeholder: Replace this with actual API data when available
  return [
    {
      'title': 'Survey 1',
      'questions': List.generate(10, (index) => 'Question ${index + 1}'),
    },
    {
      'title': 'Survey 2',
      'questions': List.generate(15, (index) => 'Question ${index + 1}'),
    },
  ];
});

class SurveyInfo extends ConsumerWidget {
  final String title;
  final int totalQuestions;
  final String estimatedTime;
  final VoidCallback onStart;

  const SurveyInfo({
    super.key,
    required this.title,
    required this.totalQuestions,
    required this.estimatedTime,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          /// 📄 Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.task_square, size: 28),
          ),

          const SizedBox(width: 12),

          /// 📋 Survey Title & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                /// Sub info
                Text(
                  '$totalQuestions Questions • $estimatedTime',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium!.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),

          /// ▶️ Start Button
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Start"),
          ),
        ],
      ),
    );
  }
}
