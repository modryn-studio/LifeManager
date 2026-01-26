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
      
      // Check for pending reminders and show notifications
      await AgentService.checkForPendingReminders();
      
      // Get morning digest
      _morningDigest = await AgentService.getLatestMorningDigest();
      
      // Get pending pattern count
      _pendingPatternCount = await PatternService.getPendingPatternCount();
      
      // Subscribe to real-time task updates
      _taskSubscription = TaskService.watchTasks().listen((tasks) {
        if (mounted) {
          setState(() => _tasks = tasks);
        }
      });
      
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
          color: AppTheme.mutedCoral.withOpacity(0.3),
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
    return FutureBuilder<String?>(
      future: CoupleService.getPendingPartnerEmail(),
      builder: (context, snapshot) {
        final pendingEmail = snapshot.data;
        
        return Container(
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
                child: Text(
                  pendingEmail != null
                      ? "We'll link you when $pendingEmail joins"
                      : 'Add your partner to share tasks',
                  style: AppTheme.body(
                    fontSize: 14,
                    color: AppTheme.warmGray,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          Text(
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
