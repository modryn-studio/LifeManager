import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/models.dart';

/// Pattern suggestion card
/// 
/// Displays a detected pattern with:
/// - Pattern title
/// - Suggested recurrence
/// - Confidence percentage
/// - Accept and dismiss buttons
/// 
/// Design:
/// - Warm, encouraging
/// - Clear call to action
/// - Non-pushy dismiss option
class PatternCard extends StatelessWidget {
  final TaskPattern pattern;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const PatternCard({
    super.key,
    required this.pattern,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.cardSpacing),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and confidence
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    pattern.patternTitle,
                    style: AppTheme.body(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gentleGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pattern.confidencePercentage,
                    style: AppTheme.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.softSage,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Suggested recurrence
            Row(
              children: [
                const Icon(
                  Icons.repeat,
                  size: 16,
                  color: AppTheme.warmGray,
                ),
                const SizedBox(width: 6),
                Text(
                  'Suggested: ${pattern.recurrenceDescription}',
                  style: AppTheme.body(
                    fontSize: 14,
                    color: AppTheme.warmGray,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                // Dismiss button (subtle)
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    'Not helpful',
                    style: AppTheme.body(
                      fontSize: 14,
                      color: AppTheme.warmGray,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Accept button (primary)
                ElevatedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create task'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
