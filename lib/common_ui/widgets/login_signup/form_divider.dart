
import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/texts.dart';

class UFormDivider extends StatelessWidget {
  const UFormDivider({super.key, required this.dark, required String title});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            indent: 50,
            endIndent: 5,
            thickness: 0.5,
            color: dark ? UColors.darkGrey : UColors.grey,
          ),
        ),
        Text(
          UTexts.orSignInWith,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Expanded(
          child: Divider(
            indent: 5,
            endIndent: 60,
            color: dark ? UColors.darkGrey : UColors.grey,
          ),
        ),
      ],
    );
  }
}
