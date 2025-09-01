// lib/features/site/provider/selected_site_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedSite {
  final String siteCode;
  final String name;
  const SelectedSite({required this.siteCode, required this.name});
}

final selectedSiteProvider = StateProvider<SelectedSite?>((ref) => null);
