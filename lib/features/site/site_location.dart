// lib/features/site/site_location.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspection/features/site/provider/state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspection/features/site/provider/selected_site_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class SiteLocation extends ConsumerWidget {
  final bool isSelectionMode;
  static const String selectedSiteKey = 'selected_site';
  static const String selectedSiteNameKey = 'selected_site_name';

  const SiteLocation({super.key, required this.isSelectionMode});

  // ✅ Save selected site to SharedPreferences (typed)
  static Future<void> saveSelectedSite(SelectedSite site) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedSiteKey, site.siteCode);
    await prefs.setString(selectedSiteNameKey, site.name);
  }

  // ✅ Get selected site from SharedPreferences (typed)
  static Future<SelectedSite?> getSelectedSite() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(selectedSiteKey);
    final name = prefs.getString(selectedSiteNameKey);
    if (code != null && name != null) {
      return SelectedSite(siteCode: code, name: name);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Site'),
        centerTitle: true,
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      body: sitesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(sitesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (siteList) {
          final sites = siteList.sites ?? [];
          final filteredSites = sites.where((site) {
            final siteCode = site.siteCode?.toLowerCase() ?? '';
            final siteName = site.name?.toLowerCase() ?? '';
            final query = searchQuery.toLowerCase();
            return siteCode.contains(query) || siteName.contains(query);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (query) {
                    ref.read(searchQueryProvider.notifier).state = query;
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by site code or name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (filteredSites.isEmpty)
                  const Expanded(
                    child: Center(child: Text('No results found')),
                  ),

                // Site Grid
                Expanded(
                  child: GridView.builder(
                    itemCount: filteredSites.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.2,
                        ),
                    itemBuilder: (context, index) {
                      final site = filteredSites[index];
                      final siteCode = site.siteCode ?? 'N/A';
                      final siteName = site.name ?? 'Unknown Site';

                      return GestureDetector(
                        onTap: () async {
                          final selected = SelectedSite(
                            siteCode: siteCode,
                            name: siteName,
                          );

                          // ✅ Persist to SharedPreferences
                          await saveSelectedSite(selected);

                          // ✅ Update global provider (triggers listeners)
                          ref.read(selectedSiteProvider.notifier).state =
                              selected;

                          // If you have a survey provider that depends on selected site,
                          // uncomment to force refetch immediately:
                          // ref.invalidate(surveyListProvider);

                          // Return selection if this screen was opened modally
                          if (isSelectionMode) {
                            Navigator.of(context).pop(selected);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                siteCode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                siteName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
