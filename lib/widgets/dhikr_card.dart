import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DhikrCard extends StatelessWidget {
  final String quote;
  final String? source;

  const DhikrCard({super.key, required this.quote, this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✦', style: TextStyle(color: AppColors.accent, fontSize: 18)),
          const SizedBox(height: 16),
          Text(quote, style: Theme.of(context).textTheme.displayLarge),
          if (source != null) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              source!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
