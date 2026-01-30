import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/services.dart';

/// Add task screen
/// 
/// Simple form for creating a new task with:
/// - Title (required)
/// - Description (optional)
/// - Category (optional)
/// - Due date (optional - defaults to null)
/// - Recurrence (optional)
/// 
/// Design:
/// - Quick and easy
/// - Sensible defaults
/// - Optional fields clearly indicated
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _category;
  DateTime? _dueDate;
  String? _recurrencePattern;
  int? _recurrenceIntervalDays;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await TaskService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        category: _category,
        dueDate: _dueDate,
        recurrencePattern: _recurrencePattern,
        recurrenceIntervalDays: _recurrenceIntervalDays,
      );
      
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create task. Please try again.',
            style: AppTheme.body(color: AppTheme.charcoal),
          ),
          backgroundColor: AppTheme.warmPeach,
        ),
      );
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
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.softSage,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  void _clearDueDate() {
    setState(() => _dueDate = null);
  }

  void _showRecurrenceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Repeat',
          style: AppTheme.handwritten(fontSize: 24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRecurrenceOption('daily', 'Daily'),
            _buildRecurrenceOption('weekly', 'Weekly'),
            _buildRecurrenceOption('monthly', 'Monthly'),
            const Divider(),
            ListTile(
              title: const Text('Custom interval'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showCustomIntervalDialog();
              },
            ),
            if (_recurrencePattern != null)
              ListTile(
                title: const Text('No repeat'),
                leading: const Icon(Icons.close, color: AppTheme.warmGray),
                onTap: () {
                  setState(() {
                    _recurrencePattern = null;
                    _recurrenceIntervalDays = null;
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceOption(String pattern, String label) {
    final isSelected = _recurrencePattern == pattern;
    
    return ListTile(
      title: Text(label),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppTheme.softSage : AppTheme.warmGray,
      ),
      onTap: () {
        setState(() {
          _recurrencePattern = pattern;
          _recurrenceIntervalDays = null;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showCustomIntervalDialog() {
    final controller = TextEditingController(
      text: _recurrenceIntervalDays?.toString() ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Custom interval',
          style: AppTheme.handwritten(fontSize: 24),
        ),
        content: Row(
          children: [
            const Text('Every '),
            SizedBox(
              width: 60,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
            const Text(' days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0) {
                setState(() {
                  _recurrencePattern = 'custom';
                  _recurrenceIntervalDays = days;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New task',
          style: AppTheme.handwritten(fontSize: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
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
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What needs to be done?',
                hintText: 'e.g., Clean the cat box',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppSpacing.fieldSpacing),
            
            // Description field
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any details to remember...',
                alignLabelWithHint: true,
              ),
            ),
            
            const SizedBox(height: AppSpacing.sectionSpacing),
            
            // Category picker
            Text(
              'Category (optional)',
              style: AppTheme.body(
                fontSize: 14,
                color: AppTheme.warmGray,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['household', 'pet', 'health', 'personal', 'sentimental']
                  .map((cat) => _buildCategoryChip(cat))
                  .toList(),
            ),
            
            const SizedBox(height: AppSpacing.sectionSpacing),
            
            // Due date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event, color: AppTheme.softSage),
              title: Text(
                _dueDate != null
                    ? DateFormat('EEEE, MMMM d').format(_dueDate!)
                    : 'Due date (optional)',
                style: AppTheme.body(
                  fontSize: 16,
                  color: _dueDate != null ? AppTheme.charcoal : AppTheme.warmGray,
                ),
              ),
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _clearDueDate,
                    )
                  : null,
              onTap: _selectDueDate,
            ),
            
            // Recurrence picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat, color: AppTheme.softSage),
              title: Text(
                _recurrencePattern != null
                    ? RecurrenceConfig.getLabel(_recurrencePattern) +
                        (_recurrenceIntervalDays != null
                            ? ' ($_recurrenceIntervalDays days)'
                            : '')
                    : 'Repeat (optional)',
                style: AppTheme.body(
                  fontSize: 16,
                  color: _recurrencePattern != null
                      ? AppTheme.charcoal
                      : AppTheme.warmGray,
                ),
              ),
              trailing: _recurrencePattern != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _recurrencePattern = null;
                          _recurrenceIntervalDays = null;
                        });
                      },
                    )
                  : null,
              onTap: _showRecurrenceDialog,
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Tip about due dates
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.suggestionBackground,
                borderRadius: AppRadius.card,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: AppTheme.warmGray,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No due date? That's okay! Some tasks are just \"when you get to it.\"",
                      style: AppTheme.body(
                        fontSize: 13,
                        color: AppTheme.warmGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        setState(() {
          _category = selected ? category : null;
        });
      },
      selectedColor: AppTheme.softSage.withAlpha(51),
      checkmarkColor: AppTheme.softSage,
      side: BorderSide(
        color: isSelected ? AppTheme.softSage : AppTheme.cardBorder,
      ),
      labelStyle: AppTheme.body(
        fontSize: 14,
        color: isSelected ? AppTheme.softSage : AppTheme.charcoal,
      ),
    );
  }
}
