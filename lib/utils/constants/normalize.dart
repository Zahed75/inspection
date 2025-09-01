// lib/utils/normalize.dart
/// Normalize any site code to what the backend expects:
/// - strip zero-width & BOM chars
/// - collapse non-breaking spaces
/// - trim
/// - UPPERCASE
String normalizeSiteCode(String input) {
  final cleaned = input
  // zero-width: 200B..200D, and BOM FEFF
      .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
  // non-breaking space -> normal space
      .replaceAll('\u00A0', ' ')
      .trim()
      .toUpperCase();
  return cleaned;
}
