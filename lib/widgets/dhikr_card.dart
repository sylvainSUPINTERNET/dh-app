import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DhikrCard extends StatelessWidget {
  final String quote;
  final String? source;

  const DhikrCard({super.key, required this.quote, this.source});

  static final _arabicTextPattern = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  bool get _isArabicQuote => _arabicTextPattern.hasMatch(quote);

  @override
  Widget build(BuildContext context) {
    final quoteTextDirection =
        _isArabicQuote ? TextDirection.rtl : TextDirection.ltr;
    final quoteTextAlign = _isArabicQuote ? TextAlign.right : TextAlign.left;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✦',
            style: TextStyle(color: AppColors.accent, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Directionality(
            textDirection: quoteTextDirection,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                quote,
                textAlign: quoteTextAlign,
                textDirection: quoteTextDirection,
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
          ),
          if (source != null) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
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
