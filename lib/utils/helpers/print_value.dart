import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';

void printValue(dynamic value, {String tag = " "}) {
  try {
    var decodeJSON = json.decode(value.toString()) as Map<String, dynamic>;
    log(
      "JSON OUTPUT: $tag ${const JsonEncoder.withIndent('').convert(decodeJSON)}\n",
    );
  } catch (_) {
    if (value is Map) {
      log(
        "JSON OUTPUT: $tag ${const JsonEncoder.withIndent('').convert(value)}\n",
      );
    } else {
      if (kDebugMode) {
        print("PRINT OUTPUT: $tag $value\n\n");
      }
    }
  }
}
