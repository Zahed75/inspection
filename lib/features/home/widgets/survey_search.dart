import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';

class SurveySearch extends StatefulWidget {
  const SurveySearch({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.hintText = 'Search survey...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String hintText;

  @override
  State<SurveySearch> createState() => _SurveySearchState();
}

class _SurveySearchState extends State<SurveySearch> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _hasFocus = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // White/gray with primary accent
    final background = isDark ? Colors.black.withOpacity(.06) : Colors.white;
    final borderColor = _hasFocus
        ? theme.colorScheme.primary.withOpacity(.55)
        : Colors.grey.shade300;
    final boxShadow = _hasFocus
        ? [
      BoxShadow(
        color: theme.colorScheme.primary.withOpacity(.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ]
        : [
      BoxShadow(
        color: Colors.black.withOpacity(.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (_, __, ___) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: boxShadow,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: theme.colorScheme.primary,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor.withOpacity(.9),
                ),
                prefixIcon: const Icon(Icons.search, color: UColors.primary),
                prefixIconConstraints:
                const BoxConstraints(minWidth: 40, minHeight: 40),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? Tooltip(
                  message: 'Clear',
                  child: IconButton(
                    icon:
                    const Icon(Icons.close, color: Colors.black54),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onClear?.call();
                      _focusNode.requestFocus();
                    },
                  ),
                )
                    : null,

                // 🔒 Kill the inner TextField outline completely
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                filled: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
