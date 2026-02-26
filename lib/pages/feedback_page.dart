import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../design_system/design_system.dart';
import '../providers/app_state.dart';

class FeedbackPage extends StatefulWidget {
  final VoidCallback? onGoBack;

  const FeedbackPage({
    Key? key,
    this.onGoBack,
  }) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  late TextEditingController _feedbackController;
  late FocusNode _feedbackFocusNode;
  String _selectedCategory = 'General';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'General', 'icon': LucideIcons.messageSquare, 'color': StarboundColors.stellarAqua},
    {'name': 'Bug Report', 'icon': LucideIcons.bug, 'color': StarboundColors.error},
    {'name': 'Feature Request', 'icon': LucideIcons.lightbulb, 'color': StarboundColors.stellarYellow},
    {'name': 'Improvement', 'icon': LucideIcons.trendingUp, 'color': StarboundColors.nebulaPurple},
    {'name': 'Question', 'icon': LucideIcons.helpCircle, 'color': StarboundColors.starlightBlue},
  ];

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
    _feedbackFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _feedbackFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      _showMessage('Please enter your feedback before submitting.', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      HapticFeedback.mediumImpact();

      final appState = context.read<AppState>();
      final delivered = await appState.submitUserFeedback(
        category: _selectedCategory,
        message: text,
        metadata: {
          'text_length': text.length,
          'from_screen': 'feedback_page',
        },
      );

      if (mounted) {
        final successMessage = delivered
            ? 'Thank you for your feedback! We\'ll review it soon.'
            : 'Thanks! We\'ll send this through as soon as you\'re back online.';
        _showMessage(successMessage, isError: false);
        
        // Clear the form after successful submission
        _feedbackController.clear();
        setState(() {
          _selectedCategory = 'General';
        });
        _feedbackFocusNode.unfocus();
        
        // Go back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && widget.onGoBack != null) {
            widget.onGoBack!();
          }
        });
      }
      
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to submit feedback. Please try again.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? LucideIcons.alertCircle : LucideIcons.checkCircle,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? StarboundColors.error : StarboundColors.success,
        duration: Duration(seconds: isError ? 4 : 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StarboundColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          color: StarboundColors.textPrimary,
          onPressed: widget.onGoBack ?? () => Navigator.pop(context),
        ),
        title: Text(
          'Share Feedback',
          style: StarboundTypography.heading3.copyWith(
            color: StarboundColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_feedbackController.text.trim().isNotEmpty && !_isSubmitting)
            TextButton(
              onPressed: _submitFeedback,
              child: Text(
                'Send',
                style: StarboundTypography.button.copyWith(
                  color: StarboundColors.stellarAqua,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: StarboundColors.stellarAqua.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: StarboundColors.stellarAqua.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.heart,
                      size: 32,
                      color: StarboundColors.stellarAqua,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Voice Matters',
                      style: StarboundTypography.heading3.copyWith(
                        color: StarboundColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Help us make Starbound better by sharing your thoughts, ideas, or reporting any issues.',
                      style: StarboundTypography.bodyLarge.copyWith(
                        color: StarboundColors.textSecondary,
                        height: 1.5,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Category selection
              Text(
                'What type of feedback is this?',
                style: StarboundTypography.heading3.copyWith(
                  color: StarboundColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category['name'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _CategoryChip(
                          name: category['name'],
                          icon: category['icon'],
                          color: category['color'],
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedCategory = category['name'];
                            });
                            HapticFeedback.lightImpact();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Feedback text input
              Text(
                'Tell us more',
                style: StarboundTypography.heading3.copyWith(
                  color: StarboundColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 20),
              
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _feedbackFocusNode.hasFocus
                        ? StarboundColors.stellarAqua.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                    width: _feedbackFocusNode.hasFocus ? 1.5 : 1,
                  ),
                ),
                child: TextField(
                  controller: _feedbackController,
                  focusNode: _feedbackFocusNode,
                  maxLines: 6,
                  maxLength: 1000,
                  style: StarboundTypography.bodyLarge.copyWith(
                    color: StarboundColors.textPrimary,
                    height: 1.5,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: _getHintText(),
                    hintStyle: StarboundTypography.bodyLarge.copyWith(
                      color: StarboundColors.textTertiary,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(24),
                    counterStyle: StarboundTypography.caption.copyWith(
                      color: StarboundColors.textTertiary,
                    ),
                  ),
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => setState(() {}),
                  enabled: !_isSubmitting,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _feedbackController.text.trim().isNotEmpty && !_isSubmitting
                      ? _submitFeedback
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StarboundColors.stellarAqua,
                    foregroundColor: StarboundColors.background,
                    disabledBackgroundColor: StarboundColors.stellarAqua.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: StarboundColors.background,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sending...',
                              style: StarboundTypography.button.copyWith(
                                color: StarboundColors.background,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Send Feedback',
                          style: StarboundTypography.button.copyWith(
                            color: StarboundColors.background,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Privacy note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.shield,
                      size: 18,
                      color: StarboundColors.textTertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your feedback is anonymous and helps us improve the app experience.',
                        style: StarboundTypography.caption.copyWith(
                          color: StarboundColors.textTertiary,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHintText() {
    switch (_selectedCategory) {
      case 'Bug Report':
        return 'Describe the bug you encountered. What did you expect to happen? What actually happened? Include steps to reproduce if possible.';
      case 'Feature Request':
        return 'What new feature would you like to see? How would it help you? Be as specific as possible.';
      case 'Improvement':
        return 'What could work better in the app? How would you improve the current experience?';
      case 'Question':
        return 'What would you like to know? Ask us anything about the app or its features.';
      default:
        return 'Share your thoughts, ideas, or anything else you\'d like us to know. We read every message!';
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : StarboundColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: StarboundTypography.button.copyWith(
                  color: isSelected ? color : StarboundColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
