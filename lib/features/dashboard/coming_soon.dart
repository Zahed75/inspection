import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ComingSoon extends ConsumerWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Center(child: Text("Coming Soon!")),
    );
  }
}
