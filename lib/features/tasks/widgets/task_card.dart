import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/models.dart';
import '../../../services/services.dart';
import '../task_detail_screen.dart';

/// Task card widget
/// 
/// Displays a single task with:
/// - Checkbox for completion
/// - Title (with completion strikethrough animation)
/// - Category emoji
/// - Due date or recurrence info
/// - Partner indicator if assigned
/// 
/// Design:
/// - Generous tap target
/// - Gentle completion animation
/// - Category indicated by subtle emoji
class TaskCard extends StatefulWidget {
  final Task task;
  final Profile? currentUser;
  final Profile? partner;
  final VoidCallback? onCompleted;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.currentUser,
    this.partner,
    this.onCompleted,
    this.onTap,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _strikethroughAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDurations.cardTransition,
      vsync: this,
    );
    
    _strikethroughAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 1, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (widget.task.isCompleted) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (_isCompleting) return;
    
    setState(() => _isCompleting = true);
    
    try {
      if (widget.task.isCompleted) {
        // Uncomplete
        await TaskService.uncompleteTask(widget.task.id);
        if (mounted) _animationController.reverse();
      } else {
        // Complete with animation
        _animationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        await TaskService.completeTask(widget.task.id);
      }
      
      if (mounted) widget.onCompleted?.call();
    } catch (e) {
      if (mounted && !widget.task.isCompleted) {
        _animationController.reverse();
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(date.year, date.month, date.day);
    
    if (dueDay == today) {
      return 'Today';
    } else if (dueDay == tomorrow) {
      return 'Tomorrow';
    } else if (dueDay.isBefore(today)) {
      final daysAgo = today.difference(dueDay).inDays;
      return '$daysAgo ${daysAgo == 1 ? 'day' : 'days'} overdue';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryEmoji = CategoryConfig.getEmoji(widget.task.category);
    final isOverdue = widget.task.isOverdue;
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: child,
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.cardSpacing),
        child: InkWell(
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(task: widget.task),
                ),
              );
            }
          },
          borderRadius: AppRadius.card,
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: _handleComplete,
                  child: AnimatedContainer(
                    duration: AppDurations.tapFeedback,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.task.isCompleted || _isCompleting
                          ? AppTheme.gentleGreen
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.task.isCompleted || _isCompleting
                            ? AppTheme.gentleGreen
                            : AppTheme.warmGray,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: widget.task.isCompleted || _isCompleting
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with category emoji
                      Row(
                        children: [
                          if (widget.task.category != null) ...[
                            Text(
                              categoryEmoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _strikethroughAnimation,
                              builder: (context, child) {
                                return Stack(
                                  children: [
                                    Text(
                                      widget.task.title,
                                      style: AppTheme.body(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: widget.task.isCompleted
                                            ? AppTheme.warmGray
                                            : AppTheme.charcoal,
                                      ),
                                    ),
                                    if (_strikethroughAnimation.value > 0)
                                      Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: _strikethroughAnimation.value,
                                            child: Container(
                                              height: 1.5,
                                              color: AppTheme.warmGray,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Subtitle row
                      Row(
                        children: [
                          // Due date or recurrence
                          if (widget.task.dueDate != null) ...[
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: isOverdue ? AppTheme.warmPeach : AppTheme.warmGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDueDate(widget.task.dueDate),
                              style: AppTheme.body(
                                fontSize: 13,
                                color: isOverdue ? AppTheme.warmPeach : AppTheme.warmGray,
                              ),
                            ),
                          ] else if (widget.task.isRecurring) ...[
                            const Icon(
                              Icons.repeat,
                              size: 14,
                              color: AppTheme.warmGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.task.recurrenceDescription,
                              style: AppTheme.body(
                                fontSize: 13,
                                color: AppTheme.warmGray,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'When you get to it',
                              style: AppTheme.body(
                                fontSize: 13,
                                color: AppTheme.warmGray,
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                          
                          const Spacer(),
                          
                          // Assigned to indicator
                          if (widget.task.assignedTo != null &&
                              widget.partner != null &&
                              widget.task.assignedTo == widget.partner!.id)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.mutedCoral.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.partner!.nameOrFallback,
                                style: AppTheme.body(
                                  fontSize: 11,
                                  color: AppTheme.mutedCoral,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
