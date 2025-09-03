// lib/features/site/site_location.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspection/features/site/provider/selected_site_provider.dart';
import 'package:inspection/features/site/provider/state_provider.dart';
import 'package:inspection/features/site/model/site_model.dart';
import 'package:inspection/app/router/routes.dart';

import '../../app/router/root_nav_key.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class SiteLocation extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  static const String selectedSiteKey = 'selected_site';
  static const String selectedSiteNameKey = 'selected_site_name';

  const SiteLocation({super.key, required this.isSelectionMode});

  static Future<void> saveSelectedSite(SelectedSite site) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedSiteKey, site.siteCode);
    await prefs.setString(selectedSiteNameKey, site.name);
  }

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
  ConsumerState<SiteLocation> createState() => _SiteLocationState();
}

class _SiteLocationState extends ConsumerState<SiteLocation> {
  final ScrollController _scrollController = ScrollController();
  List<Sites> _allSites = [];
  bool _isLoadingAll = true;

  @override
  void initState() {
    super.initState();
    _loadAllSites();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSites() async {
    try {
      setState(() { _isLoadingAll = true; });

      final siteApi = ref.read(siteApiProvider);
      final allSites = await siteApi.getAllSites();

      setState(() {
        _allSites = allSites;
        _isLoadingAll = false;
      });
    } catch (e) {
      setState(() { _isLoadingAll = false; });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sites: ${e.toString()}'),
          ));
          print('Error loading sites: $e');
    }
  }

  void _navigateToHome() {
    print('🚀 Navigating to home screen...');

    // Use a small delay to ensure state operations complete
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        // Use context.go for navigation
        context.go(Routes.home);
        print('✅ Navigation to home successful');
      } catch (e) {
        print('❌ Navigation failed: $e');

        // Fallback: Try using pushReplacement
        try {
          context.go(Routes.home);
          print('✅ Push replacement successful');
        } catch (e2) {
          print('❌ Push replacement also failed: $e2');

          // Last resort: Use root navigator
          try {
            final rootContext = rootNavigatorKey.currentContext;
            if (rootContext != null) {
              GoRouter.of(rootContext).go(Routes.home);
              print('✅ Root navigation successful');
            }
          } catch (e3) {
            print('❌ All navigation methods failed: $e3');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredSites = _allSites.where((site) {
      if (searchQuery.isEmpty) return true;
      final siteCode = site.siteCode?.toLowerCase() ?? '';
      final siteName = site.name?.toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      return siteCode.contains(query) || siteName.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Site'),
        centerTitle: true,
        actions: [
          if (widget.isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _navigateToHome,
            ),
        ],
      ),
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      body: _isLoadingAll
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search Bar
            TextField(
              onChanged: (query) => ref.read(searchQueryProvider.notifier).state = query,
              decoration: InputDecoration(
                hintText: 'Search by site code or name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isEmpty ? null : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Results count
            if (searchQuery.isNotEmpty) Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${filteredSites.length} sites found',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),

            if (filteredSites.isEmpty) Expanded(
              child: Center(
                child: Text(
                  searchQuery.isEmpty ? 'No sites available' : 'No results found for "$searchQuery"',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),

            // Site Grid
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                itemCount: filteredSites.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

                      print('✅ Site selected: ${selected.siteCode} - ${selected.name}');

                      // ✅ Persist to SharedPreferences
                      await SiteLocation.saveSelectedSite(selected);
                      print('✅ Site saved to SharedPreferences');

                      // ✅ Update global provider (triggers listeners)
                      ref.read(selectedSiteProvider.notifier).state = selected;
                      print('✅ Selected site provider updated');

                      // ✅ Navigate to home screen
                      if (widget.isSelectionMode) {
                        _navigateToHome();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
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
      ),
    );
  }
}