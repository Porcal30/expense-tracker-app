import 'package:flutter/material.dart';

class ReportSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? backgroundColor;
  final Color? textColor;

  const ReportSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final fg = textColor ?? Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [bg.withValues(alpha: 0.95), bg.withValues(alpha: 0.76)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: fg.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: fg.withValues(alpha: 0.16),
            blurRadius: 16,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: fg.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: fg,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
