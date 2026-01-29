import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../services/services.dart';

/// Task detail screen
/// 
/// Shows full task details with options to:
/// - Edit task fields
/// - Mark as complete/incomplete
/// - Delete task
/// 
/// Design:
/// - Clean, focused layout
/// - Easy editing
/// - Destructive actions require confirmation
class TaskDetailScreen extends StatefulWidget {
  final Task task;
  
  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _refreshTask() async {
    final updated = await TaskService.getTaskById(_task.id);
    if (updated != null && mounted) {
      setState(() => _task = updated);
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoading = true);
    
    try {
      if (_task.isCompleted) {
        final updated = await TaskService.uncompleteTask(_task.id);
        setState(() => _task = updated);
      } else {
        final updated = await TaskService.completeTask(_task.id);
        setState(() => _task = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong'),
            backgroundColor: AppTheme.warmPeach,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete task?',
          style: AppTheme.handwritten(fontSize: 24),
        ),
        content: Text(
          'This cannot be undone.',
          style: AppTheme.body(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmPeach,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() => _isDeleting = true);
      
      try {
        await TaskService.deleteTask(_task.id);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete task'),
              backgroundColor: AppTheme.warmPeach,
            ),
          );
        }
      }
    }
  }

  void _navigateToEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EditTaskScreen(task: _task),
      ),
    ).then((_) => _refreshTask());
  }

  @override
  Widget build(BuildContext context) {
    final categoryLabel = CategoryConfig.getLabel(_task.category);
    final categoryEmoji = CategoryConfig.getEmoji(_task.category);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task',
          style: AppTheme.handwritten(fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            onPressed: _isDeleting ? null : _handleDelete,
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: _isLoading ? null : _handleComplete,
                child: AnimatedContainer(
                  duration: AppDurations.tapFeedback,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _task.isCompleted
                        ? AppTheme.gentleGreen
                        : Colors.transparent,
                    border: Border.all(
                      color: _task.isCompleted
                          ? AppTheme.gentleGreen
                          : AppTheme.warmGray,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _task.isCompleted
                      ? const Icon(Icons.check, size: 22, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _task.title,
                  style: AppTheme.handwritten(
                    fontSize: 28,
                    color: _task.isCompleted ? AppTheme.warmGray : AppTheme.charcoal,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Description
          if (_task.description != null && _task.description!.isNotEmpty) ...[
            Text(
              _task.description!,
              style: AppTheme.body(
                fontSize: 16,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          
          const Divider(),
          
          // Details
          _buildDetailRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: '$categoryEmoji $categoryLabel',
          ),
          
          _buildDetailRow(
            icon: Icons.event_outlined,
            label: 'Due date',
            value: _task.dueDate != null
                ? DateFormat('EEEE, MMMM d, y').format(_task.dueDate!)
                : 'When you get to it',
            valueColor: _task.isOverdue ? AppTheme.warmPeach : null,
          ),
          
          if (_task.isRecurring)
            _buildDetailRow(
              icon: Icons.repeat,
              label: 'Repeats',
              value: _task.recurrenceDescription,
            ),
          
          if (_task.completedAt != null)
            _buildDetailRow(
              icon: Icons.check_circle_outline,
              label: 'Completed',
              value: DateFormat('MMM d, y h:mm a').format(_task.completedAt!),
              valueColor: AppTheme.gentleGreen,
            ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Complete/Uncomplete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleComplete,
              icon: Icon(
                _task.isCompleted
                    ? Icons.replay
                    : Icons.check,
              ),
              label: Text(
                _task.isCompleted ? 'Mark as incomplete' : 'Mark as complete',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _task.isCompleted
                    ? AppTheme.warmGray
                    : AppTheme.gentleGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.warmGray),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTheme.body(
              fontSize: 14,
              color: AppTheme.warmGray,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTheme.body(
              fontSize: 14,
              color: valueColor ?? AppTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Edit task screen (internal)
class _EditTaskScreen extends StatefulWidget {
  final Task task;
  
  const _EditTaskScreen({required this.task});

  @override
  State<_EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<_EditTaskScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  late String? _category;
  late DateTime? _dueDate;
  late String? _recurrencePattern;
  late int? _recurrenceIntervalDays;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _category = widget.task.category;
    _dueDate = widget.task.dueDate;
    _recurrencePattern = widget.task.recurrencePattern;
    _recurrenceIntervalDays = widget.task.recurrenceIntervalDays;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final updated = widget.task.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        category: _category,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null && widget.task.dueDate != null,
        recurrencePattern: _recurrencePattern,
        clearRecurrencePattern: _recurrencePattern == null && widget.task.recurrencePattern != null,
        recurrenceIntervalDays: _recurrenceIntervalDays,
        clearRecurrenceIntervalDays: _recurrenceIntervalDays == null && widget.task.recurrenceIntervalDays != null,
      );
      
      await TaskService.updateTask(updated);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save changes'),
            backgroundColor: AppTheme.warmPeach,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    
    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit task',
          style: AppTheme.handwritten(fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: AppTheme.body(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.softSage,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Title
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Task',
            ),
          ),
          
          const SizedBox(height: AppSpacing.fieldSpacing),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
            ),
          ),
          
          const SizedBox(height: AppSpacing.sectionSpacing),
          
          // Category
          Text(
            'Category',
            style: AppTheme.body(fontSize: 14, color: AppTheme.warmGray),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['household', 'pet', 'health', 'personal', 'sentimental']
                .map((cat) => _buildCategoryChip(cat))
                .toList(),
          ),
          
          const SizedBox(height: AppSpacing.sectionSpacing),
          
          // Due date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event, color: AppTheme.softSage),
            title: Text(
              _dueDate != null
                  ? DateFormat('EEEE, MMMM d').format(_dueDate!)
                  : 'Due date',
              style: AppTheme.body(
                fontSize: 16,
                color: _dueDate != null ? AppTheme.charcoal : AppTheme.warmGray,
              ),
            ),
            trailing: _dueDate != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _dueDate = null),
                  )
                : null,
            onTap: _selectDueDate,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _category == category;
    final emoji = CategoryConfig.getEmoji(category);
    final label = CategoryConfig.getLabel(category);
    
    return FilterChip(
      label: Text('$emoji $label'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _category = selected ? category : null);
      },
      selectedColor: AppTheme.softSage.withAlpha(51),
      checkmarkColor: AppTheme.softSage,
      side: BorderSide(
        color: isSelected ? AppTheme.softSage : AppTheme.cardBorder,
      ),
    );
  }
}
