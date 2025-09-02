// // lib/features/site/provider/site_provider.dart
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../../../core/network/dio_provider.dart';
// import '../api/site_api.dart';
// import '../model/site_model.dart';
//
// final siteApiProvider = Provider<SiteApi>((ref) {
//   final dio = ref.watch(dioProvider);
//   return SiteApi(dio);
// });
//
// final sitesProvider = FutureProvider<SiteListModel>((ref) async {
//   final siteApi = ref.read(siteApiProvider);
//   return await siteApi.getSitesByUser();
// });




// lib/features/site/provider/site_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../api/site_api.dart';
import '../model/site_model.dart';

final siteApiProvider = Provider<SiteApi>((ref) {
  final dio = ref.watch(dioProvider);
  return SiteApi(dio);
});

// Provider for paginated sites (if you want to keep pagination)
final sitesProvider = FutureProvider<SiteListModel>((ref) async {
  final siteApi = ref.read(siteApiProvider);
  return await siteApi.getSitesByUser();
});

// New provider for ALL sites
final allSitesProvider = FutureProvider<List<Sites>>((ref) async {
  final siteApi = ref.read(siteApiProvider);
  return await siteApi.getAllSites();
});