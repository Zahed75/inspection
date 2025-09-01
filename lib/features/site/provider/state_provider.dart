// lib/features/site/provider/site_provider.dart


import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../api/site_api.dart';
import '../model/site_model.dart';

final siteApiProvider = Provider<SiteApi>((ref) {
  final dio = ref.watch(dioProvider);
  return SiteApi(dio);
});

final sitesProvider = FutureProvider<SiteListModel>((ref) async {
  final siteApi = ref.read(siteApiProvider);
  return await siteApi.getSitesByUser();
});
