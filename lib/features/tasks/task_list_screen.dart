import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import 'widgets/task_card.dart';
import 'add_task_screen.dart';
import '../auth/login_screen.dart';
import '../patterns/pattern_suggestions_screen.dart';

/// Main task list screen
/// 
/// Shows all tasks for the couple with:
/// - Real-time sync between partners
/// - Sections: Overdue, Today, Upcoming, No due date
/// - Add task FAB
/// - Pattern suggestions badge
/// 
/// Design:
/// - Spacious, breathable layout
/// - Warm morning digest message at top
/// - Gentle animations throughout
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  Profile? _currentUser;
  Profile? _partner;
  String? _morningDigest;
  String? _pendingPartnerEmail;
  int _pendingPatternCount = 0;
  bool _isLoading = true;
  StreamSubscription<List<Task>>? _taskSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      // Load user data
      _currentUser = await AuthService.getCurrentProfile();
      _partner = await AuthService.getPartnerProfile();
      
      // Cache pending partner email if no partner
      if (_partner == null) {
        _pendingPartnerEmail = await CoupleService.getPendingPartnerEmail();
      }
      
      // Check for pending reminders and show notifications
      await AgentService.checkForPendingReminders();
      
      // Get morning digest
      _morningDigest = await AgentService.getLatestMorningDigest();
      
      // Get pending pattern count
      _pendingPatternCount = await PatternService.getPendingPatternCount();
      
      // Subscribe to real-time task updates
      _taskSubscription = TaskService.watchTasks().listen(
        (tasks) {
          if (mounted) {
            setState(() => _tasks = tasks);
          }
        },
        onError: (error) {
          debugPrint('Task stream error: $error');
          // Continue with existing tasks on error
        },
      );
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    _pendingPatternCount = await PatternService.getPendingPatternCount();
    _morningDigest = await AgentService.getLatestMorningDigest();
    
    // Acknowledge all reminders on refresh
    await AgentService.acknowledgeAllReminders();
    
    setState(() {});
  }

  void _navigateToAddTask() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
  }

  void _navigateToPatterns() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PatternSuggestionsScreen()),
    ).then((_) {
      // Refresh pattern count when returning
      PatternService.getPendingPatternCount().then((count) {
        if (mounted) {
          setState(() => _pendingPatternCount = count);
        }
      });
    });
  }

  void _navigateToAddPartner() async {
    final emailController = TextEditingController();
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Add Your Partner',
            style: AppTheme.handwritten(
              fontSize: 24,
              color: AppTheme.charcoal,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter your partner's email address. They'll be linked to your household when they sign up.",
                style: AppTheme.body(
                  fontSize: 14,
                  color: AppTheme.warmGray,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Partner Email',
                  errorText: errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.input,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                
                if (email.isEmpty) {
                  setState(() => errorMessage = 'Please enter an email');
                  return;
                }
                
                if (!CoupleService.isValidEmailFormat(email)) {
                  setState(() => errorMessage = 'Please enter a valid email');
                  return;
                }
                
                try {
                  await CoupleService.updatePendingPartnerEmail(email);
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  debugPrint('Error updating pending partner email: $e');
                  if (mounted) {
                    setState(() => errorMessage = e.toString().contains('duplicate')
                        ? 'This email is already linked'
                        : 'Failed to save email. Please try again.');
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // Refresh data to show the new pending partner email
      _initializeData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "We'll link you when ${emailController.text.trim()} joins",
            ),
            backgroundColor: AppTheme.gentleGreen,
          ),
        );
      }
    }
    
    emailController.dispose();
  }

  Future<void> _showPartnerInviteOptions() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Partner Invitation',
          style: AppTheme.handwritten(
            fontSize: 24,
            color: AppTheme.charcoal,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invitation sent to:',
              style: AppTheme.body(
                fontSize: 14,
                color: AppTheme.warmGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _pendingPartnerEmail ?? '',
              style: AppTheme.body(
                fontSize: 16,
                color: AppTheme.charcoal,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "They'll be automatically linked when they sign up with this email.",
              style: AppTheme.body(
                fontSize: 14,
                color: AppTheme.warmGray,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel Invitation'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('change'),
            child: const Text('Change Email'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (result == 'cancel') {
      await _handleCancelInvitation();
    } else if (result == 'change') {
      _navigateToAddPartner();
    }
  }

  Future<void> _handleCancelInvitation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Invitation?',
          style: AppTheme.handwritten(
            fontSize: 24,
            color: AppTheme.charcoal,
          ),
        ),
        content: Text(
          'This will remove the pending invitation. You can add a partner again later.',
          style: AppTheme.body(
            fontSize: 14,
            color: AppTheme.warmGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Invitation'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmPeach,
            ),
            child: const Text('Cancel Invitation'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CoupleService.cancelPendingPartnerInvitation();
        _initializeData(); // Refresh to update UI
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Partner invitation cancelled'),
              backgroundColor: AppTheme.gentleGreen,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error cancelling invitation: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel invitation. Please try again.'),
              backgroundColor: AppTheme.warmPeach,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSignOut() async {
    await AuthService.signOut();
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  List<Task> get _overdueTasks => 
      _tasks.where((t) => !t.isCompleted && t.isOverdue).toList();
  
  List<Task> get _todayTasks => 
      _tasks.where((t) => !t.isCompleted && t.isDueToday).toList();
  
  List<Task> get _upcomingTasks => 
      _tasks.where((t) => 
          !t.isCompleted && 
          !t.isOverdue && 
          !t.isDueToday && 
          t.dueDate != null
      ).toList();
  
  List<Task> get _noDueDateTasks => 
      _tasks.where((t) => !t.isCompleted && t.hasNoDueDate).toList();
  
  List<Task> get _completedTasks => 
      _tasks.where((t) => t.isCompleted).toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.softSage,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LifeManager',
          style: AppTheme.handwritten(
            fontSize: 28,
            color: AppTheme.charcoal,
          ),
        ),
        actions: [
          // Pattern suggestions badge
          if (_pendingPatternCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: _navigateToPatterns,
                  tooltip: 'Pattern suggestions',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.mutedCoral,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _pendingPatternCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          
          // Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'patterns',
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 20),
                    const SizedBox(width: 12),
                    const Text('Pattern suggestions'),
                    if (_pendingPatternCount > 0) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.mutedCoral,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _pendingPatternCount.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'patterns') {
                _navigateToPatterns();
              } else if (value == 'signout') {
                _handleSignOut();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.softSage,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Morning digest card
            if (_morningDigest != null) ...[
              _buildMorningDigestCard(),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
            
            // Partner status
            if (_partner == null && _currentUser != null) ...[
              _buildPartnerPendingCard(),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
            
            // Overdue section
            if (_overdueTasks.isNotEmpty) ...[
              _buildSectionHeader('Overdue', Icons.warning_amber_rounded, AppTheme.warmPeach),
              ..._overdueTasks.map((task) => TaskCard(
                task: task,
                currentUser: _currentUser,
                partner: _partner,
              )),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
            
            // Today section
            if (_todayTasks.isNotEmpty) ...[
              _buildSectionHeader('Today', Icons.today, AppTheme.softSage),
              ..._todayTasks.map((task) => TaskCard(
                task: task,
                currentUser: _currentUser,
                partner: _partner,
              )),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
            
            // Upcoming section
            if (_upcomingTasks.isNotEmpty) ...[
              _buildSectionHeader('Upcoming', Icons.event, AppTheme.charcoal),
              ..._upcomingTasks.map((task) => TaskCard(
                task: task,
                currentUser: _currentUser,
                partner: _partner,
              )),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
            
            // No due date section
            if (_noDueDateTasks.isNotEmpty) ...[
              _buildSectionHeader('When you get to it', Icons.hourglass_empty, AppTheme.warmGray),
              ..._noDueDateTasks.map((task) => TaskCard(
                task: task,
                currentUser: _currentUser,
                partner: _partner,
              )),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
            
            // Recently completed section (collapsed by default)
            if (_completedTasks.isNotEmpty) ...[
              _buildCompletedSection(),
            ],
            
            // Empty state
            if (_tasks.where((t) => !t.isCompleted).isEmpty)
              _buildEmptyState(),
            
            // Bottom padding for FAB
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMorningDigestCard() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.suggestionBackground,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppTheme.mutedCoral.withAlpha(77),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Morning ❤️',
                style: AppTheme.handwritten(
                  fontSize: 22,
                  color: AppTheme.mutedCoral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _morningDigest!,
            style: AppTheme.body(
              fontSize: 15,
              color: AppTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerPendingCard() {
    final bool hasPendingInvite = _pendingPartnerEmail != null;
    
    return InkWell(
      onTap: hasPendingInvite ? _showPartnerInviteOptions : _navigateToAddPartner,
      borderRadius: AppRadius.card,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: AppTheme.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.favorite_border,
              color: AppTheme.mutedCoral,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPendingInvite
                        ? 'Partner Invitation Sent'
                        : 'Add your partner to share tasks',
                    style: AppTheme.body(
                      fontSize: 14,
                      color: hasPendingInvite ? AppTheme.charcoal : AppTheme.warmGray,
                      fontWeight: hasPendingInvite ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (hasPendingInvite) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Waiting for $_pendingPartnerEmail to join",
                      style: AppTheme.body(
                        fontSize: 13,
                        color: AppTheme.warmGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              hasPendingInvite ? Icons.more_horiz : Icons.chevron_right,
              color: AppTheme.warmGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSection() {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Row(
          children: [
            const Icon(Icons.check_circle, size: 18, color: AppTheme.gentleGreen),
            const SizedBox(width: 8),
            Text(
              'Completed (${_completedTasks.length})',
              style: AppTheme.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.gentleGreen,
              ),
            ),
          ],
        ),
        children: _completedTasks.take(5).map((task) => TaskCard(
          task: task,
          currentUser: _currentUser,
          partner: _partner,
        )).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          const Text(
            '✨',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'All clear!',
            style: AppTheme.handwritten(
              fontSize: 28,
              color: AppTheme.softSage,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first task',
            style: AppTheme.body(
              fontSize: 16,
              color: AppTheme.warmGray,
            ),
          ),
        ],
      ),
    );
  }
}
