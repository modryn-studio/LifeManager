import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/services.dart';
import '../tasks/task_list_screen.dart';

/// Couple setup screen
/// 
/// Shown after signup to:
/// 1. Try joining an existing couple (via email lookup)
/// 2. Create a new couple with optional partner email
/// 
/// Design:
/// - Warm, encouraging
/// - Clear explanation of what happens next
class CoupleSetupScreen extends StatefulWidget {
  final String displayName;
  
  const CoupleSetupScreen({
    super.key,
    required this.displayName,
  });

  @override
  State<CoupleSetupScreen> createState() => _CoupleSetupScreenState();
}

class _CoupleSetupScreenState extends State<CoupleSetupScreen> {
  final _partnerEmailController = TextEditingController();
  
  bool _isLoading = false;
  bool _checkingExistingCouple = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkForExistingCouple();
  }

  @override
  void dispose() {
    _partnerEmailController.dispose();
    super.dispose();
  }

  /// Check if someone invited this user to their couple
  Future<void> _checkForExistingCouple() async {
    try {
      final profile = await CoupleService.tryJoinExistingCouple(
        displayName: widget.displayName,
      );
      
      if (!mounted) return;
      
      if (profile != null) {
        // Successfully joined an existing couple!
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TaskListScreen()),
        );
        return;
      }
    } catch (e) {
      // Continue to manual setup
    } finally {
      if (mounted) {
        setState(() => _checkingExistingCouple = false);
      }
    }
  }

  Future<void> _handleCreateCouple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final partnerEmail = _partnerEmailController.text.trim();
      
      // Validate email format if provided
      if (partnerEmail.isNotEmpty && !CoupleService.isValidEmailFormat(partnerEmail)) {
        setState(() {
          _errorMessage = 'Please enter a valid email address';
          _isLoading = false;
        });
        return;
      }
      
      await CoupleService.createCoupleAndProfile(
        displayName: widget.displayName,
        partnerEmail: partnerEmail.isNotEmpty ? partnerEmail : null,
      );
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TaskListScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingExistingCouple) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppTheme.softSage,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Setting things up...',
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              
              // Welcome message
              Text(
                'Hi, ${widget.displayName}! 👋',
                style: AppTheme.handwritten(
                  fontSize: 36,
                  color: AppTheme.softSage,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'LifeManager works best when you\'re connected with your partner. '
                'Enter their email below and we\'ll link your accounts when they join.',
                style: AppTheme.body(
                  fontSize: 16,
                  color: AppTheme.charcoal,
                  fontWeight: FontWeight.normal,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Partner email field
              TextFormField(
                controller: _partnerEmailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: "Partner's email (optional)",
                  hintText: 'partner@example.com',
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Explanation text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.suggestionBackground,
                  borderRadius: AppRadius.card,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.warmGray,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "We'll link you when they join. You can skip this and add them later.",
                        style: AppTheme.body(
                          fontSize: 13,
                          color: AppTheme.warmGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.warmPeach.withOpacity(0.2),
                    borderRadius: AppRadius.toast,
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTheme.body(
                      fontSize: 14,
                      color: AppTheme.charcoal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateCouple,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _partnerEmailController.text.trim().isEmpty
                              ? "Continue Solo for Now"
                              : "Continue",
                        ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Skip option (subtle)
              if (_partnerEmailController.text.trim().isNotEmpty)
                Center(
                  child: TextButton(
                    onPressed: () {
                      _partnerEmailController.clear();
                      setState(() {});
                    },
                    child: Text(
                      "Skip partner invitation",
                      style: AppTheme.body(
                        fontSize: 14,
                        color: AppTheme.warmGray,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
