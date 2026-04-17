import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? actionOnPressed;
  final String? actionLabel;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionOnPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (actionLabel != null && actionOnPressed != null)
            TextButton(
              onPressed: actionOnPressed,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
