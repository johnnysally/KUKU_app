import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AIResponseCard extends StatelessWidget {
  final String title;
  final String content;
  final Color? backgroundColor;
  final IconData? icon;

  const AIResponseCard({
    super.key,
    required this.title,
    required this.content,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Make the card expand to the parent's available width so it
    // appears edge-to-edge inside the screen padding used by pages.
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      color: backgroundColor ?? AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) Icon(icon, color: AppColors.primary),
                if (icon != null) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              content,
              style: const TextStyle(fontSize: 18, height: 1.7, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
