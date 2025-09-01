
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../navigation_menu.dart';
import '../../common_ui/widgets/appBar/appbar.dart';
import '../../utils/constants/sizes.dart';

// Dummy static data provider (not used dynamically, just for Riverpod setup)
final dummyDataProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'outlet': 'Outlet 1', 'score': 80, 'timestamp': DateTime.now()},
    {
      'outlet': 'Outlet 2',
      'score': 90,
      'timestamp': DateTime.now().subtract(Duration(days: 1)),
    },
  ];
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Static data from Riverpod provider
    final reports = ref.watch(dummyDataProvider);

    bool isMyOutletSelected = true;
    DateTimeRange? selectedRange;

    void openDatePicker() async {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime(2026),
        initialDateRange:
            selectedRange ??
            DateTimeRange(
              start: DateTime(DateTime.now().year, DateTime.now().month, 1),
              end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
            ),
      );
      if (picked != null) {
        selectedRange = picked;
      }
    }

    return Scaffold(
      appBar: UAppBar(
        showBackArrow: true,
        onBackPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NavigationMenu()),
          );
        },
        title: const Center(child: Text("Dashboard")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(USizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Row
            Row(
              children: [
                IconButton(
                  onPressed: openDatePicker,
                  icon: const Icon(Iconsax.filter),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      isMyOutletSelected = true;
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMyOutletSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      foregroundColor: isMyOutletSelected
                          ? Colors.white
                          : Colors.purple,
                    ),
                    child: const Text("My Outlets"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      isMyOutletSelected = false;
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isMyOutletSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      foregroundColor: !isMyOutletSelected
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text("Nationals"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: USizes.spaceBtwSections),
            const Divider(),
            const SizedBox(height: USizes.spaceBtwSections),

            Text(
              isMyOutletSelected ? "My Outlet Scores" : "National Scores",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: USizes.spaceBtwItems),

            if (reports.isEmpty)
              const Text("No data available for the selected date range."),
            if (reports.isNotEmpty)
              ...reports.map((item) {
                return _buildScoreCard(
                  context,
                  index: reports.indexOf(item) + 1,
                  outlet: item['outlet']!,
                  score: item['score']!,
                  total: 100,
                  showPosition: isMyOutletSelected,
                  timestamp: item['timestamp']!,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(
    BuildContext context, {
    required int index,
    required String outlet,
    required int score,
    required int total,
    required bool showPosition,
    required DateTime timestamp,
  }) {
    final localTime = timestamp.toLocal();
    final formattedTime = DateFormat('hh:mm a, dd MMM yyyy').format(localTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showPosition ? "$index. $outlet" : outlet,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  "Time: $formattedTime",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            "$score / $total",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
