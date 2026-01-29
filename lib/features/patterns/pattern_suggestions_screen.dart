import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import 'widgets/pattern_card.dart';

/// Pattern suggestions screen
/// 
/// Shows AI-detected patterns with options to:
/// - Accept (create recurring task)
/// - Dismiss (hide suggestion)
/// 
/// Design:
/// - Warm, encouraging tone
/// - Clear explanation of each suggestion
/// - Non-pushy - just helpful insights
class PatternSuggestionsScreen extends StatefulWidget {
  const PatternSuggestionsScreen({super.key});

  @override
  State<PatternSuggestionsScreen> createState() => _PatternSuggestionsScreenState();
}

class _PatternSuggestionsScreenState extends State<PatternSuggestionsScreen> {
  List<TaskPattern> _patterns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatterns();
  }

  Future<void> _loadPatterns() async {
    setState(() => _isLoading = true);
    
    try {
      final patterns = await PatternService.getPendingPatterns();
      setState(() {
        _patterns = patterns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAccept(TaskPattern pattern) async {
    try {
      await PatternService.acceptPattern(pattern);
      
      // Remove from list
      setState(() {
        _patterns.removeWhere((p) => p.id == pattern.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created recurring task: ${pattern.patternTitle}'),
            backgroundColor: AppTheme.gentleGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create task'),
            backgroundColor: AppTheme.warmPeach,
          ),
        );
      }
    }
  }

  Future<void> _handleDismiss(TaskPattern pattern) async {
    try {
      await PatternService.dismissPattern(pattern.id);
      
      // Remove from list
      setState(() {
        _patterns.removeWhere((p) => p.id == pattern.id);
      });
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patterns',
          style: AppTheme.handwritten(fontSize: 24),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.softSage),
            )
          : _patterns.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPatterns,
                  color: AppTheme.softSage,
                  child: ListView(
                    padding: AppSpacing.screenPadding,
                    children: [
                      // Explanation header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.suggestionBackground,
                          borderRadius: AppRadius.card,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: AppTheme.mutedCoral,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'We noticed some patterns in your tasks. Want to make them recurring?',
                                style: AppTheme.body(
                                  fontSize: 14,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Pattern cards
                      ..._patterns.map((pattern) => PatternCard(
                        pattern: pattern,
                        onAccept: () => _handleAccept(pattern),
                        onDismiss: () => _handleDismiss(pattern),
                      )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 64,
              color: AppTheme.softSage,
            ),
            const SizedBox(height: 16),
            Text(
              'No patterns yet',
              style: AppTheme.handwritten(
                fontSize: 28,
                color: AppTheme.softSage,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "As you complete tasks, we'll notice patterns and suggest making them recurring.",
              textAlign: TextAlign.center,
              style: AppTheme.body(
                fontSize: 16,
                color: AppTheme.warmGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
