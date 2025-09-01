import 'package:flutter/material.dart';

class UHelperFunctions {
  UHelperFunctions._();

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static String getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      // 5AM to 12PM
      return 'Good Morning';
    } else if (hour >= 12 && hour < 16) {
      // 12PM to 4PM
      return 'Good Afternoon';
    } else if (hour >= 16 && hour < 19) {
      // 5PM to 7PM
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }
}
