// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:go_router/go_router.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:inspection/features/question/provider/survey_submit_provider.dart';
//
// import '../../app/router/routes.dart';
// import '../../common_ui/widgets/alerts/u_alert.dart';
// import '../result/provider/responseId_provider.dart';
// import 'model/survey_submit_model.dart';
//
// // Providers for Riverpod
// final locationProvider = StateProvider<Position?>((ref) => null);
// final imageProvider = StateProvider<Map<int, String?>>((ref) => {});
// final detectedLocationProvider = StateProvider<Map<int, Map<String, double>?>>(
//   (ref) => {},
// );
// final answersProvider = StateProvider<Map<int, dynamic>>((ref) => {});
// final currentCategoryProvider = StateProvider<String>((ref) => 'All');
// final expandedCategoriesProvider = StateProvider<Set<String>>((ref) => {});
//
// class QuestionScreen extends ConsumerStatefulWidget {
//   final Map<String, dynamic> surveyData;
//   final String siteCode;
//
//   const QuestionScreen({
//     super.key,
//     required this.surveyData,
//     required this.siteCode,
//   });
//
//   @override
//   ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
// }
//
// class _QuestionScreenState extends ConsumerState<QuestionScreen> {
//   bool isSubmitting = false;
//   final ScrollController _scrollController = ScrollController();
//
//   // Map questionId -> serial number (1-based) for validation messages
//   late final Map<int, int> _serialById;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Build the serial map once from incoming questions order
//     final List questions = (widget.surveyData['questions'] as List?) ?? [];
//     _serialById = {
//       for (var i = 0; i < questions.length; i++)
//         (questions[i]['id'] as int): i + 1,
//     };
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(answersProvider.notifier).state = {};
//       ref.read(locationProvider.notifier).state = null;
//       _getLocation();
//     });
//   }
//
//   int _serialOf(int qid) => _serialById[qid] ?? qid;
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _getLocation() async {
//     final permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       UAlert.show(
//         title: "Permission Denied",
//         message: "Location permission is required.",
//         icon: Icons.error_outline,
//         iconColor: Colors.redAccent,
//         context: context,
//       );
//       return;
//     }
//     final position = await Geolocator.getCurrentPosition();
//     ref.read(locationProvider.notifier).state = position;
//   }
//
//   Future<void> pickImage(int questionId) async {
//     final image = await ImagePicker().pickImage(source: ImageSource.camera);
//     if (image != null) {
//       ref.read(imageProvider.notifier).update((state) {
//         return {...state, questionId: image.path};
//       });
//     }
//   }
//
//   Future<void> uploadFile(int questionId) async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
//     if (result != null && result.files.single.path != null) {
//       ref.read(imageProvider.notifier).update((state) {
//         return {...state, questionId: result.files.single.path};
//       });
//     }
//   }
//
//   Future<void> detectLocation(int questionId) async {
//     final permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       UAlert.show(
//         title: "Permission Denied",
//         message: "Location permission is required.",
//         icon: Icons.error_outline,
//         iconColor: Colors.redAccent,
//         context: context,
//       );
//       return;
//     }
//     final position = await Geolocator.getCurrentPosition();
//     ref.read(detectedLocationProvider.notifier).update((state) {
//       return {
//         ...state,
//         questionId: {
//           "latitude": position.latitude,
//           "longitude": position.longitude,
//         },
//       };
//     });
//   }
//
//   void _toggleCategory(String category) {
//     ref.read(expandedCategoriesProvider.notifier).update((state) {
//       final newState = Set<String>.from(state);
//       if (newState.contains(category)) {
//         newState.remove(category);
//       } else {
//         newState.add(category);
//       }
//       return newState;
//     });
//   }
//
//   Future<void> _submitSurvey() async {
//     if (isSubmitting) return;
//
//     setState(() => isSubmitting = true);
//
//     try {
//       final surveySubmitApi = ref.read(surveySubmitApiProvider);
//       final answers = ref.read(answersProvider);
//       final currentLocation = ref.read(locationProvider);
//       final images = ref.read(imageProvider);
//       final detectedLocations = ref.read(detectedLocationProvider);
//
//       // Prepare question responses with validation
//       final List<Map<String, dynamic>> questionResponses = [];
//       final Map<int, String> imageFiles = {};
//       final List<String> validationErrors = [];
//
//       // Process regular questions (text, choice, linear, remarks, yesno, multiple_scoring)
//       for (var question in widget.surveyData['questions'] as List) {
//         final questionId = question['id'] as int;
//         final questionType = question['type'] as String;
//         final isRequired = (question['is_required'] ?? false) as bool;
//         final answer = answers[questionId];
//
//         // Skip image and location questions for now (handled separately)
//         if (questionType == 'image' || questionType == 'location') {
//           continue;
//         }
//
//         // Validate required questions
//         if (isRequired && answer == null) {
//           validationErrors.add(
//             'Question #${_serialOf(questionId)} is required',
//           );
//           continue;
//         }
//
//         // Validate linear range
//         if (questionType == 'linear' && answer != null) {
//           final minValue = (question['min_value'] ?? 0) as int;
//           final maxValue = (question['max_value'] ?? 100) as int;
//           if (answer < minValue || answer > maxValue) {
//             validationErrors.add(
//               'Question #${_serialOf(questionId)}: Value must be between $minValue and $maxValue',
//             );
//             continue;
//           }
//         }
//
//         // REMOVE min 10 char validation for text/remarks (per instruction)
//
//         if (answer != null) {
//           Map<String, dynamic> response = {'question': questionId};
//
//           switch (questionType) {
//             case 'yesno':
//             case 'choice':
//             case 'multiple_scoring':
//               response['selected_choice'] = {'id': answer};
//               break;
//
//             case 'linear':
//               response['linear_value'] = answer;
//               break;
//
//             case 'text':
//             case 'remarks':
//               response['answer_text'] = answer;
//               break;
//           }
//
//           questionResponses.add(response);
//         }
//       }
//
//       // Process image questions
//       for (var question in widget.surveyData['questions'] as List) {
//         final questionId = question['id'] as int;
//         final questionType = question['type'] as String;
//         final isRequired = (question['is_required'] ?? false) as bool;
//
//         if (questionType == 'image') {
//           final imagePath = images[questionId];
//
//           // Validate required image
//           if (isRequired && imagePath == null) {
//             validationErrors.add(
//               'Question #${_serialOf(questionId)} is required',
//             );
//             continue;
//           }
//
//           if (imagePath != null) {
//             imageFiles[questionId] = imagePath;
//             // Add response entry for image question
//             questionResponses.add({'question': questionId});
//           }
//         }
//       }
//
//       // Process location questions
//       for (var question in widget.surveyData['questions'] as List) {
//         final questionId = question['id'] as int;
//         final questionType = question['type'] as String;
//         final isRequired = (question['is_required'] ?? false) as bool;
//
//         if (questionType == 'location') {
//           final location = detectedLocations[questionId];
//
//           // Validate required location
//           if (isRequired && location == null) {
//             validationErrors.add(
//               'Question #${_serialOf(questionId)} is required',
//             );
//             continue;
//           }
//
//           if (location != null) {
//             questionResponses.add({
//               'question': questionId,
//               'location_lat': location['latitude'],
//               'location_lon': location['longitude'],
//             });
//           }
//         }
//       }
//
//       // Check for validation errors
//       if (validationErrors.isNotEmpty) {
//         throw Exception(
//           'Please complete all required fields:\n${validationErrors.join('\n')}',
//         );
//         // (kept alert UX the same)
//       }
//
//       // Ensure outlet_code is not empty
//       final effectiveOutletCode = widget.siteCode.isNotEmpty
//           ? widget.siteCode
//           : 'CH02';
//
//       // Submit the survey
//       final response = await surveySubmitApi.submitSurveyResponse(
//         surveyId: widget.surveyData['id'],
//         outletCode: effectiveOutletCode,
//         locationLat: currentLocation?.latitude,
//         locationLon: currentLocation?.longitude,
//         questionResponses: questionResponses,
//         imagePaths: imageFiles,
//       );
//
//       _navigateToResultScreen(response);
//     } catch (e) {
//       // Handle error with user-friendly message
//       final errorMessage = e.toString().replaceAll('Exception: ', '');
//
//       UAlert.show(
//         title: "Submission Failed",
//         message: errorMessage,
//         icon: Icons.error_outline,
//         iconColor: Colors.redAccent,
//         context: context,
//       );
//     } finally {
//       setState(() => isSubmitting = false);
//     }
//   }
//
//   void _navigateToResultScreen(SurveySubmitResponseModel response) {
//     if (response.responseId == null || response.responseId == 0) {
//       UAlert.show(
//         title: "Submission Error",
//         message: "Failed to get valid response ID from server",
//         icon: Icons.error_outline,
//         iconColor: Colors.redAccent,
//         context: context,
//       );
//       return;
//     }
//
//     // Store the latest response ID
//     ref.read(latestResponseIdProvider.notifier).state = response.responseId;
//
//     // Navigate to ResultScreen
//     context.pushNamed(
//       Routes.result,
//       queryParams: {'responseId': response.responseId.toString()},
//     );
//   }
//
//   Widget _buildCategoryHeader(
//     String category,
//     int questionCount,
//     bool isExpanded,
//   ) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ListTile(
//         leading: Container(
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             color: theme.colorScheme.primary.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             Icons.category,
//             color: theme.colorScheme.primary,
//             size: 20,
//           ),
//         ),
//         title: Text(
//           category,
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 16,
//             color: theme.textTheme.bodyMedium?.color,
//           ),
//         ),
//         subtitle: Text(
//           "$questionCount questions",
//           style: TextStyle(color: theme.textTheme.bodySmall?.color),
//         ),
//         trailing: Icon(
//           isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
//           size: 20,
//           color: theme.textTheme.bodySmall?.color,
//         ),
//         onTap: () => _toggleCategory(category),
//       ),
//     );
//   }
//
//   Widget _buildQuestionCard(
//     Map<String, dynamic> question,
//     int serialNumber,
//     String category,
//   ) {
//     final theme = Theme.of(context);
//     final id = question['id'];
//     final type = question['type'];
//     final text = question['text'];
//     final marks = question['marks'];
//     final isRequired = question['is_required'] ?? false;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Question header with serial number
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 30,
//                   height: 30,
//                   decoration: BoxDecoration(
//                     color: theme.colorScheme.primary.withValues(alpha: 0.2),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Center(
//                     child: Text(
//                       '$serialNumber',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                         color: theme.colorScheme.primary,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         text,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                           color: theme.textTheme.bodyMedium?.color,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           if (isRequired)
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.red.withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: const Text(
//                                 "Required",
//                                 style: TextStyle(
//                                   color: Colors.red,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           if (marks != null) ...[
//                             const SizedBox(width: 8),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.green.withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 "$marks marks",
//                                 style: const TextStyle(
//                                   color: Colors.green,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//
//             // Question input based on type
//             _buildQuestionInput(question, id, type),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuestionInput(
//     Map<String, dynamic> question,
//     int id,
//     String type,
//   ) {
//     switch (type) {
//       case 'yesno':
//         return _buildYesNoInput(question, id);
//       case 'choice':
//         return _buildChoiceInput(question, id);
//       case 'multiple_scoring':
//         return _buildMultipleScoringInput(question, id);
//       case 'image':
//         return _buildImageInput(id);
//       case 'location':
//         return _buildLocationInput(id);
//       case 'text':
//       case 'remarks':
//         return _buildTextInput(id);
//       case 'linear':
//         return _buildLinearInput(question, id);
//       default:
//         return const Text('Unknown question type');
//     }
//   }
//
//   Widget _buildYesNoInput(Map<String, dynamic> question, int id) {
//     final theme = Theme.of(context);
//     final choices = question['choices'] as List;
//     final currentAnswer = ref.watch(answersProvider)[id];
//
//     return Row(
//       children: [
//         // Yes Button - 50% width
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: FilledButton.tonal(
//               onPressed: () => ref
//                   .read(answersProvider.notifier)
//                   .update((state) => {...state, id: choices[0]['id']}),
//               style: FilledButton.styleFrom(
//                 backgroundColor: currentAnswer == choices[0]['id']
//                     ? Colors.green
//                     : theme.colorScheme.surface,
//                 foregroundColor: currentAnswer == choices[0]['id']
//                     ? Colors.white
//                     : theme.textTheme.bodyMedium?.color,
//               ),
//               child: Text(choices[0]['text']),
//             ),
//           ),
//         ),
//
//         // No Button - 50% width
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: FilledButton.tonal(
//               onPressed: () => ref
//                   .read(answersProvider.notifier)
//                   .update((state) => {...state, id: choices[1]['id']}),
//               style: FilledButton.styleFrom(
//                 backgroundColor: currentAnswer == choices[1]['id']
//                     ? Colors.red
//                     : theme.colorScheme.surface,
//                 foregroundColor: currentAnswer == choices[1]['id']
//                     ? Colors.white
//                     : theme.textTheme.bodyMedium?.color,
//               ),
//               child: Text(choices[1]['text']),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildChoiceInput(Map<String, dynamic> question, int id) {
//     final theme = Theme.of(context);
//     return Column(
//       children: (question['choices'] as List).map<Widget>((choice) {
//         return RadioListTile(
//           title: Text(
//             choice['text'],
//             style: TextStyle(color: theme.textTheme.bodyMedium?.color),
//           ),
//           value: choice['id'],
//           groupValue: ref.watch(answersProvider)[id],
//           onChanged: (val) {
//             ref.read(answersProvider.notifier).update((state) {
//               return {...state, id: val};
//             });
//           },
//         );
//       }).toList(),
//     );
//   }
//
//   Widget _buildMultipleScoringInput(Map<String, dynamic> question, int id) {
//     final theme = Theme.of(context);
//     return Column(
//       children: (question['choices'] as List).map<Widget>((choice) {
//         return RadioListTile(
//           title: Text(
//             '${choice['text']} (${choice['marks']} marks)',
//             style: TextStyle(color: theme.textTheme.bodyMedium?.color),
//           ),
//           value: choice['id'],
//           groupValue: ref.watch(answersProvider)[id],
//           onChanged: (val) {
//             ref.read(answersProvider.notifier).update((state) {
//               return {...state, id: val};
//             });
//           },
//         );
//       }).toList(),
//     );
//   }
//
//   Widget _buildImageInput(int id) {
//     final theme = Theme.of(context);
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: () => pickImage(id),
//                 icon: const Icon(Iconsax.camera, size: 18),
//                 label: const Text('Take Photo'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
//                   foregroundColor: theme.colorScheme.primary,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: () => uploadFile(id),
//                 icon: const Icon(Iconsax.gallery, size: 18),
//                 label: const Text('Upload'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green.withOpacity(0.1),
//                   foregroundColor: Colors.green,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         if (ref.watch(imageProvider)[id] != null)
//           Container(
//             margin: const EdgeInsets.only(top: 8),
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.green.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Iconsax.gallery_tick, size: 16, color: Colors.green),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Selected: ${ref.watch(imageProvider)[id]!.split("/").last}',
//                     style: const TextStyle(color: Colors.green),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildLocationInput(int id) {
//     final theme = Theme.of(context);
//     final detectedLocation = ref.watch(detectedLocationProvider)[id];
//     final isLocationDetected = detectedLocation != null;
//
//     return Column(
//       children: [
//         ElevatedButton.icon(
//           onPressed: () => detectLocation(id),
//           icon: const Icon(Iconsax.location, size: 18),
//           label: const Text('Detect Current Location'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: theme.colorScheme.surface,
//             foregroundColor: theme.textTheme.bodyMedium?.color,
//           ),
//         ),
//         const SizedBox(height: 12),
//         if (isLocationDetected)
//           Container(
//             margin: const EdgeInsets.only(top: 8),
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Iconsax.location_tick,
//                   size: 16,
//                   color: theme.colorScheme.primary,
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     "Lat: ${detectedLocation["latitude"]!.toStringAsFixed(6)}, "
//                     "Lng: ${detectedLocation["longitude"]!.toStringAsFixed(6)}",
//                     style: TextStyle(color: theme.colorScheme.primary),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildTextInput(int id) {
//     final theme = Theme.of(context);
//     return TextField(
//       maxLines: 3,
//       onChanged: (val) {
//         ref.read(answersProvider.notifier).update((state) {
//           return {...state, id: val};
//         });
//       },
//       style: TextStyle(color: theme.textTheme.bodyMedium?.color),
//       decoration: InputDecoration(
//         hintText: "Type your response here...",
//         hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         filled: true,
//         fillColor: theme.colorScheme.surface,
//       ),
//     );
//   }
//
//   Widget _buildLinearInput(Map<String, dynamic> question, int id) {
//     final theme = Theme.of(context);
//     final minValue = (question['min_value'] ?? 0) as int;
//     final maxValue = (question['max_value'] ?? 10) as int;
//     final currentValue = ref.watch(answersProvider)[id] ?? minValue;
//
//     return Column(
//       children: [
//         Slider(
//           min: minValue.toDouble(),
//           max: maxValue.toDouble(),
//           value: (currentValue as num).toDouble(),
//           divisions: maxValue - minValue,
//           onChanged: (val) {
//             ref.read(answersProvider.notifier).update((state) {
//               return {...state, id: val.round()};
//             });
//           },
//         ),
//         Text(
//           "Selected: $currentValue",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: theme.textTheme.bodyMedium?.color,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildInfoChip(IconData icon, String text) {
//     final theme = Theme.of(context);
//     return Chip(
//       avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
//       label: Text(
//         text,
//         style: TextStyle(
//           fontSize: 12,
//           color: theme.textTheme.bodyMedium?.color,
//         ),
//       ),
//       backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
//       labelPadding: const EdgeInsets.symmetric(horizontal: 4),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final questions = widget.surveyData['questions'] as List;
//     final expandedCategories = ref.watch(expandedCategoriesProvider);
//     final theme = Theme.of(context);
//
//     // Group questions by category_name (fallback to category, then 'General')
//     final Map<String, List<Map<String, dynamic>>> categorizedQuestions = {};
//     for (var question in questions) {
//       final category =
//           (question['category_name'] ?? question['category'] ?? 'General')
//               as String;
//       categorizedQuestions.putIfAbsent(category, () => []);
//       categorizedQuestions[category]!.add(question);
//     }
//
//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: Icon(Iconsax.arrow_left_2, color: theme.iconTheme.color),
//           onPressed: () => {
//             if (GoRouter.of(context).canPop())
//               {GoRouter.of(context).pop()}
//             else
//               {GoRouter.of(context).go(Routes.home)},
//           },
//         ),
//         // AppBar: show Survey Title + Site Code (no other changes)
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               widget.surveyData['title'] ?? 'Survey',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: theme.textTheme.bodyMedium?.color,
//               ),
//             ),
//             Text(
//               'Site: ${widget.siteCode}',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: theme.textTheme.bodySmall?.color,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Iconsax.info_circle, color: theme.iconTheme.color),
//             onPressed: () {
//               UAlert.show(
//                 title: "Survey Info",
//                 message:
//                     widget.surveyData['description'] ??
//                     'No description available',
//                 context: context,
//               );
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // REMOVED the top survey info card as requested
//             // (no total questions / time / title card above categories)
//
//             // Questions list
//             Expanded(
//               child: ListView(
//                 controller: _scrollController,
//                 children: [
//                   ...categorizedQuestions.entries.map((entry) {
//                     final category = entry.key;
//                     final categoryQuestions = entry.value;
//                     final isExpanded = expandedCategories.contains(category);
//
//                     return Column(
//                       children: [
//                         _buildCategoryHeader(
//                           category,
//                           categoryQuestions.length,
//                           isExpanded,
//                         ),
//                         if (isExpanded)
//                           ...categoryQuestions.asMap().entries.map((
//                             questionEntry,
//                           ) {
//                             final index = questionEntry.key;
//                             final question = questionEntry.value;
//                             return _buildQuestionCard(
//                               question,
//                               index + 1,
//                               category,
//                             );
//                           }),
//                       ],
//                     );
//                   }),
//                   const SizedBox(height: 80),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: Container(
//         margin: const EdgeInsets.only(bottom: 1),
//         child: FloatingActionButton.extended(
//           onPressed: isSubmitting ? null : _submitSurvey,
//           backgroundColor: theme.colorScheme.primary,
//           foregroundColor: theme.colorScheme.onPrimary,
//           icon: isSubmitting
//               ? CircularProgressIndicator(
//                   color: theme.colorScheme.onPrimary,
//                   strokeWidth: 2,
//                 )
//               : const Icon(Iconsax.send_2),
//           label: Text(isSubmitting ? 'Submitting...' : 'Submit Survey'),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }
// }
































// New Question Screen!
// lib/features/question/question.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:inspection/features/question/provider/survey_submit_provider.dart';

import '../../app/router/routes.dart';
import '../../common_ui/widgets/alerts/u_alert.dart';
import '../result/provider/responseId_provider.dart';
import 'model/survey_submit_model.dart';

// ⬇️ import your search widget (adjust path if different)
import '../home/widgets/survey_search.dart';

// Providers for Riverpod
final locationProvider = StateProvider<Position?>((ref) => null);
final imageProvider = StateProvider<Map<int, String?>>((ref) => {});
final detectedLocationProvider = StateProvider<Map<int, Map<String, double>?>>(
      (ref) => {},
);
final answersProvider = StateProvider<Map<int, dynamic>>((ref) => {});
final currentCategoryProvider = StateProvider<String>((ref) => 'All');
final expandedCategoriesProvider = StateProvider<Set<String>>((ref) => {});

// ⬇️ search provider for THIS screen (questions)
final questionSearchQueryProvider = StateProvider<String>((ref) => '');

class QuestionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> surveyData;
  final String siteCode;

  const QuestionScreen({
    super.key,
    required this.surveyData,
    required this.siteCode,
  });

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  bool isSubmitting = false;
  final ScrollController _scrollController = ScrollController();

  // Map questionId -> serial number (1-based) for validation messages
  late final Map<int, int> _serialById;

  // ⬇️ controller for the search bar
  late final TextEditingController _questionSearchController;

  @override
  void initState() {
    super.initState();

    _questionSearchController = TextEditingController();

    // Build the serial map once from incoming questions order
    final List questions = (widget.surveyData['questions'] as List?) ?? [];
    _serialById = {
      for (var i = 0; i < questions.length; i++)
        (questions[i]['id'] as int): i + 1,
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(answersProvider.notifier).state = {};
      ref.read(locationProvider.notifier).state = null;
      _getLocation();
    });
  }

  int _serialOf(int qid) => _serialById[qid] ?? qid;

  @override
  void dispose() {
    _scrollController.dispose();
    _questionSearchController.dispose();
    super.dispose();
  }

  // ⬇️ apply question search (updates provider)
  void _applyQuestionSearch(String raw) {
    ref.read(questionSearchQueryProvider.notifier).state = raw;
  }

  Future<void> _getLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      UAlert.show(
        title: "Permission Denied",
        message: "Location permission is required.",
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        context: context,
      );
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    ref.read(locationProvider.notifier).state = position;
  }

  Future<void> pickImage(int questionId) async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      ref.read(imageProvider.notifier).update((state) {
        return {...state, questionId: image.path};
      });
    }
  }

  Future<void> uploadFile(int questionId) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      ref.read(imageProvider.notifier).update((state) {
        return {...state, questionId: result.files.single.path};
      });
    }
  }

  Future<void> detectLocation(int questionId) async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      UAlert.show(
        title: "Permission Denied",
        message: "Location permission is required.",
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        context: context,
      );
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    ref.read(detectedLocationProvider.notifier).update((state) {
      return {
        ...state,
        questionId: {
          "latitude": position.latitude,
          "longitude": position.longitude,
        },
      };
    });
  }

  void _toggleCategory(String category) {
    ref.read(expandedCategoriesProvider.notifier).update((state) {
      final newState = Set<String>.from(state);
      if (newState.contains(category)) {
        newState.remove(category);
      } else {
        newState.add(category);
      }
      return newState;
    });
  }

  Future<void> _submitSurvey() async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      final surveySubmitApi = ref.read(surveySubmitApiProvider);
      final answers = ref.read(answersProvider);
      final currentLocation = ref.read(locationProvider);
      final images = ref.read(imageProvider);
      final detectedLocations = ref.read(detectedLocationProvider);

      // Prepare question responses with validation
      final List<Map<String, dynamic>> questionResponses = [];
      final Map<int, String> imageFiles = {};
      final List<String> validationErrors = [];

      // Process regular questions (text, choice, linear, remarks, yesno, multiple_scoring)
      for (var question in widget.surveyData['questions'] as List) {
        final questionId = question['id'] as int;
        final questionType = question['type'] as String;
        final isRequired = (question['is_required'] ?? false) as bool;
        final answer = answers[questionId];

        if (questionType == 'image' || questionType == 'location') {
          continue;
        }

        if (isRequired && answer == null) {
          validationErrors.add(
            'Question #${_serialOf(questionId)} is required',
          );
          continue;
        }

        if (questionType == 'linear' && answer != null) {
          final minValue = (question['min_value'] ?? 0) as int;
          final maxValue = (question['max_value'] ?? 100) as int;
          if (answer < minValue || answer > maxValue) {
            validationErrors.add(
              'Question #${_serialOf(questionId)}: Value must be between $minValue and $maxValue',
            );
            continue;
          }
        }

        if (answer != null) {
          Map<String, dynamic> response = {'question': questionId};

          switch (questionType) {
            case 'yesno':
            case 'choice':
            case 'multiple_scoring':
              response['selected_choice'] = {'id': answer};
              break;

            case 'linear':
              response['linear_value'] = answer;
              break;

            case 'text':
            case 'remarks':
              response['answer_text'] = answer;
              break;
          }

          questionResponses.add(response);
        }
      }

      // Process image questions
      for (var question in widget.surveyData['questions'] as List) {
        final questionId = question['id'] as int;
        final questionType = question['type'] as String;
        final isRequired = (question['is_required'] ?? false) as bool;

        if (questionType == 'image') {
          final imagePath = images[questionId];

          if (isRequired && imagePath == null) {
            validationErrors.add(
              'Question #${_serialOf(questionId)} is required',
            );
            continue;
          }

          if (imagePath != null) {
            imageFiles[questionId] = imagePath;
            questionResponses.add({'question': questionId});
          }
        }
      }

      // Process location questions
      for (var question in widget.surveyData['questions'] as List) {
        final questionId = question['id'] as int;
        final questionType = question['type'] as String;
        final isRequired = (question['is_required'] ?? false) as bool;

        if (questionType == 'location') {
          final location = detectedLocations[questionId];

          if (isRequired && location == null) {
            validationErrors.add(
              'Question #${_serialOf(questionId)} is required',
            );
            continue;
          }

          if (location != null) {
            questionResponses.add({
              'question': questionId,
              'location_lat': location['latitude'],
              'location_lon': location['longitude'],
            });
          }
        }
      }

      if (validationErrors.isNotEmpty) {
        throw Exception(
          'Please complete all required fields:\n${validationErrors.join('\n')}',
        );
      }

      final effectiveOutletCode = widget.siteCode.isNotEmpty
          ? widget.siteCode
          : 'CH02';

      final response = await surveySubmitApi.submitSurveyResponse(
        surveyId: widget.surveyData['id'],
        outletCode: effectiveOutletCode,
        locationLat: currentLocation?.latitude,
        locationLon: currentLocation?.longitude,
        questionResponses: questionResponses,
        imagePaths: imageFiles,
      );

      _navigateToResultScreen(response);
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');

      UAlert.show(
        title: "Submission Failed",
        message: errorMessage,
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        context: context,
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _navigateToResultScreen(SurveySubmitResponseModel response) {
    if (response.responseId == null || response.responseId == 0) {
      UAlert.show(
        title: "Submission Error",
        message: "Failed to get valid response ID from server",
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        context: context,
      );
      return;
    }

    ref.read(latestResponseIdProvider.notifier).state = response.responseId;

    context.pushNamed(
      Routes.result,
      queryParams: {'responseId': response.responseId.toString()},
    );
  }

  Widget _buildCategoryHeader(
      String category,
      int questionCount,
      bool isExpanded,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.category,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          category,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        subtitle: Text(
          "$questionCount questions",
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),
        trailing: Icon(
          isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
          size: 20,
          color: theme.textTheme.bodySmall?.color,
        ),
        onTap: () => _toggleCategory(category),
      ),
    );
  }

  Widget _buildQuestionCard(
      Map<String, dynamic> question,
      int serialNumber,
      String category,
      ) {
    final theme = Theme.of(context);
    final id = question['id'];
    final type = question['type'];
    final text = question['text'];
    final marks = question['marks'];
    final isRequired = question['is_required'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header with serial number
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$serialNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),


                      Row(
                        children: [
                          // Left: Required chip (if any)
                          if (isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "Required",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          // Push the next widget to the far right
                          const Spacer(),

                          // Right: Marks chip (if any)
                          if (marks != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$marks marks",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      )

                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question input based on type
            _buildQuestionInput(question, id, type),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(
      Map<String, dynamic> question,
      int id,
      String type,
      ) {
    switch (type) {
      case 'yesno':
        return _buildYesNoInput(question, id);
      case 'choice':
        return _buildChoiceInput(question, id);
      case 'multiple_scoring':
        return _buildMultipleScoringInput(question, id);
      case 'image':
        return _buildImageInput(id);
      case 'location':
        return _buildLocationInput(id);
      case 'text':
      case 'remarks':
        return _buildTextInput(id);
      case 'linear':
        return _buildLinearInput(question, id);
      default:
        return const Text('Unknown question type');
    }
  }

  Widget _buildYesNoInput(Map<String, dynamic> question, int id) {
    final theme = Theme.of(context);
    final choices = question['choices'] as List;
    final currentAnswer = ref.watch(answersProvider)[id];

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton.tonal(
              onPressed: () => ref
                  .read(answersProvider.notifier)
                  .update((state) => {...state, id: choices[0]['id']}),
              style: FilledButton.styleFrom(
                backgroundColor: currentAnswer == choices[0]['id']
                    ? Colors.green
                    : theme.colorScheme.surface,
                foregroundColor: currentAnswer == choices[0]['id']
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color,
              ),
              child: Text(choices[0]['text']),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton.tonal(
              onPressed: () => ref
                  .read(answersProvider.notifier)
                  .update((state) => {...state, id: choices[1]['id']}),
              style: FilledButton.styleFrom(
                backgroundColor: currentAnswer == choices[1]['id']
                    ? Colors.red
                    : theme.colorScheme.surface,
                foregroundColor: currentAnswer == choices[1]['id']
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color,
              ),
              child: Text(choices[1]['text']),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceInput(Map<String, dynamic> question, int id) {
    final theme = Theme.of(context);
    return Column(
      children: (question['choices'] as List).map<Widget>((choice) {
        return RadioListTile(
          title: Text(
            choice['text'],
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
          value: choice['id'],
          groupValue: ref.watch(answersProvider)[id],
          onChanged: (val) {
            ref.read(answersProvider.notifier).update((state) {
              return {...state, id: val};
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildMultipleScoringInput(Map<String, dynamic> question, int id) {
    final theme = Theme.of(context);
    return Column(
      children: (question['choices'] as List).map<Widget>((choice) {
        return RadioListTile(
          title: Text(
            '${choice['text']} (${choice['marks']} marks)',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
          value: choice['id'],
          groupValue: ref.watch(answersProvider)[id],
          onChanged: (val) {
            ref.read(answersProvider.notifier).update((state) {
              return {...state, id: val};
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildImageInput(int id) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => pickImage(id),
                icon: const Icon(Iconsax.camera, size: 18),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => uploadFile(id),
                icon: const Icon(Iconsax.gallery, size: 18),
                label: const Text('Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  foregroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
        if (ref.watch(imageProvider)[id] != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.gallery_tick, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${ref.watch(imageProvider)[id]!.split("/").last}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationInput(int id) {
    final theme = Theme.of(context);
    final detectedLocation = ref.watch(detectedLocationProvider)[id];
    final isLocationDetected = detectedLocation != null;

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => detectLocation(id),
          icon: const Icon(Iconsax.location, size: 18),
          label: const Text('Detect Current Location'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 12),
        if (isLocationDetected)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.location_tick,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Lat: ${detectedLocation["latitude"]!.toStringAsFixed(6)}, "
                        "Lng: ${detectedLocation["longitude"]!.toStringAsFixed(6)}",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextInput(int id) {
    final theme = Theme.of(context);
    return TextField(
      maxLines: 3,
      onChanged: (val) {
        ref.read(answersProvider.notifier).update((state) {
          return {...state, id: val};
        });
      },
      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
      decoration: InputDecoration(
        hintText: "Type your response here...",
        hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildLinearInput(Map<String, dynamic> question, int id) {
    final theme = Theme.of(context);
    final minValue = (question['min_value'] ?? 0) as int;
    final maxValue = (question['max_value'] ?? 10) as int;
    final currentValue = ref.watch(answersProvider)[id] ?? minValue;

    return Column(
      children: [
        Slider(
          min: minValue.toDouble(),
          max: maxValue.toDouble(),
          value: (currentValue as num).toDouble(),
          divisions: maxValue - minValue,
          onChanged: (val) {
            ref.read(answersProvider.notifier).update((state) {
              return {...state, id: val.round()};
            });
          },
        ),
        Text(
          "Selected: $currentValue",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Full list from survey payload
    final List questions = (widget.surveyData['questions'] as List?) ?? [];

    // ⬇️ get current search string
    final search = ref.watch(questionSearchQueryProvider).trim().toLowerCase();

    // ⬇️ apply filtering by question text or category (no UI/UX changes)
    final List<Map<String, dynamic>> visibleQuestions = search.isEmpty
        ? questions.cast<Map<String, dynamic>>()
        : questions.where((q) {
      final text = (q['text'] ?? '').toString().toLowerCase();
      final cat =
      (q['category_name'] ?? q['category'] ?? 'General')
          .toString()
          .toLowerCase();
      return text.contains(search) || cat.contains(search);
    }).cast<Map<String, dynamic>>().toList();

    final expandedCategories = ref.watch(expandedCategoriesProvider);

    // Group visible questions by category_name (fallback to category, then 'General')
    final Map<String, List<Map<String, dynamic>>> categorizedQuestions = {};
    for (var question in visibleQuestions) {
      final category =
      (question['category_name'] ?? question['category'] ?? 'General')
      as String;
      categorizedQuestions.putIfAbsent(category, () => []);
      categorizedQuestions[category]!.add(question);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2, color: theme.iconTheme.color),
          onPressed: () => {
            if (GoRouter.of(context).canPop())
              {GoRouter.of(context).pop()}
            else
              {GoRouter.of(context).go(Routes.home)},
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.surveyData['title'] ?? 'Survey',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            Text(
              'Site: ${widget.siteCode}',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.info_circle, color: theme.iconTheme.color),
            onPressed: () {
              UAlert.show(
                title: "Survey Info",
                message:
                widget.surveyData['description'] ??
                    'No description available',
                context: context,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ⬇️ NEW: question search (reuses your SurveySearch widget)
            SurveySearch(
              controller: _questionSearchController,
              hintText: 'Search questions or category...',
              onChanged: _applyQuestionSearch,
              onClear: () => _applyQuestionSearch(''),
            ),

            // Questions list (unchanged UX)
            Expanded(
              child: ListView(
                controller: _scrollController,
                children: [
                  ...categorizedQuestions.entries.map((entry) {
                    final category = entry.key;
                    final categoryQuestions = entry.value;
                    final isExpanded = expandedCategories.contains(category);

                    return Column(
                      children: [
                        _buildCategoryHeader(
                          category,
                          categoryQuestions.length,
                          isExpanded,
                        ),
                        if (isExpanded)
                          ...categoryQuestions.asMap().entries.map((
                              questionEntry,
                              ) {
                            final index = questionEntry.key;
                            final question = questionEntry.value;
                            return _buildQuestionCard(
                              question,
                              index + 1,
                              category,
                            );
                          }),
                      ],
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 1),
        child: FloatingActionButton.extended(
          onPressed: isSubmitting ? null : _submitSurvey,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          icon: isSubmitting
              ? CircularProgressIndicator(
            color: theme.colorScheme.onPrimary,
            strokeWidth: 2,
          )
              : const Icon(Iconsax.send_2),
          label: Text(isSubmitting ? 'Submitting...' : 'Submit Survey'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
