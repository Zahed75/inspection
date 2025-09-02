// lib/features/survey/provider/survey_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/home.dart';
import '../../home/model/survey_list_model.dart';
import '../../home/provider/survey_api_provider.dart';
import '../../site/provider/selected_site_provider.dart';
import '../api/survey_api.dart';


final surveyListProvider = FutureProvider.autoDispose<SurveyListModel>((ref) async {
  final surveyApi = ref.read(surveyApiProvider);
  final selectedSite = ref.watch(selectedSiteProvider);

  return await surveyApi.getSurveysByUser(siteCode: selectedSite?.siteCode);
});