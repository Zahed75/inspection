
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_ui/custom_shapes/circular_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/device_helpers.dart';

/// StateProvider for dynamic height
final headerHeightProvider = StateProvider.autoDispose<double>((ref) {
  // Using DeviceHelper to get screen height correctly with context
  final screenHeight = UDeviceHelper.getScreenHeight(ref as BuildContext);
  return screenHeight * 0.3; // Default 30% of screen height
});

class UPrimaryHeaderContainer extends ConsumerWidget {
  final Widget child;

  const UPrimaryHeaderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerHeight = ref.watch(
      headerHeightProvider,
    ); // Correctly watch the height

    return Container(
      height: containerHeight,
      color: UColors.primary,
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -160,
            child: UCircularContainer(
              height: containerHeight * 1.3,
              width: containerHeight * 1.3,
              backgroundColor: UColors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            top: 50,
            right: -250,
            child: UCircularContainer(
              height: containerHeight * 1.3,
              width: containerHeight * 1.3,
              backgroundColor: UColors.white.withValues(alpha: 0.1),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
