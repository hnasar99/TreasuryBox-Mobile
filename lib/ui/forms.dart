import 'package:flutter/material.dart';

import 'theme.dart';

/// Keeps forms scrollable on phones and readable on wide windows.
class TreasuryFormBody extends StatelessWidget {
  const TreasuryFormBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        // The fields have at most 680 logical pixels, plus page margins.
        constraints: const BoxConstraints(maxWidth: 680 + FxSpace.l * 2),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            FxSpace.l,
            FxSpace.l,
            FxSpace.l,
            FxSpace.xxl,
          ),
          children: children,
        ),
      ),
    );
  }
}

/// A persistent label owns its space above the field, away from any border.
class TreasuryTextField extends StatelessWidget {
  const TreasuryTextField({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: FxSpace.s),
        // Keep the name on the editable node without announcing it twice.
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            minLines: minLines,
            maxLines: maxLines,
            decoration: const InputDecoration(),
          ),
        ),
      ],
    );
  }
}
