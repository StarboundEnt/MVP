import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/design_system.dart';
import '../services/smart_input_service.dart';

/// Smart input widget that intelligently routes user input
class SmartInputWidget extends StatefulWidget {
  final Function(SmartInputResult result) onInputProcessed;
  final ValueChanged<String?>? onGuidedJournalRequested;
  final String? placeholder;
  final bool showIntentIndicator;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const SmartInputWidget({
    Key? key,
    required this.onInputProcessed,
    this.onGuidedJournalRequested,
    this.placeholder,
    this.showIntentIndicator = true,
    this.controller,
    this.focusNode,
  }) : super(key: key);

  @override
  State<SmartInputWidget> createState() => _SmartInputWidgetState();
}

class _SmartInputWidgetState extends State<SmartInputWidget> 
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _ownsController;
  late bool _ownsFocusNode;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  
  bool _isProcessing = false;
  SmartRouteIntent _detectedIntent = SmartRouteIntent.clarify;
  double _confidence = 0.0;
  Timer? _debounceTimer;
  SmartInputResult? _lastResult;
  String _lastProcessedText = '';
  
  final SmartInputService _smartInputService = SmartInputService();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocusNode = widget.focusNode == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    
    // Only rebuild if mounted to avoid unnecessary rebuilds
    if (mounted) {
      setState(() {});
    }
  }

  void _onTextChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    final currentText = _controller.text.trim();
    
    // Reduced debounce timing for better responsiveness
    if (currentText.length > 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && currentText != _lastProcessedText) {
          _detectIntent();
        }
      });
    } else {
      setState(() {
        _detectedIntent = SmartRouteIntent.clarify;
        _confidence = 0.0;
        _lastResult = null;
      });
    }
  }

  Future<void> _detectIntent() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Avoid processing the same text twice
    if (text == _lastProcessedText) return;
    
    try {
      final result = await _smartInputService.processInput(text);
      if (mounted) {
        setState(() {
          _detectedIntent = result.intent;
          _confidence = result.confidence;
          _lastResult = result;
          _lastProcessedText = text;
        });
        
        // Debug logging
        debugPrint('🔍 Smart Input Classification:');
        debugPrint('   Text: "$text"');
        debugPrint('   Intent: ${result.intent}');
        debugPrint('   Confidence: ${result.confidence.toStringAsFixed(2)}');
        debugPrint('   Reasoning: ${result.reasoning}');
      }
    } catch (e) {
      debugPrint('Intent detection error: $e');
    }
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      HapticFeedback.mediumImpact();
      
      // Use cached result if available and text hasn't changed
      final result = (_lastResult != null && text == _lastProcessedText) 
          ? _lastResult! 
          : await _smartInputService.processInput(text);
      
      debugPrint('💫 SMART INPUT WIDGET: Processing result: ${result.intent}');
      debugPrint('💫 SMART INPUT WIDGET: Text: "${result.processedText}"'); 
      debugPrint('💫 SMART INPUT WIDGET: Confidence: ${result.confidence}');
      debugPrint('💫 SMART INPUT WIDGET: About to call onInputProcessed...');
      
      if (mounted) {
        if (result.intent == SmartRouteIntent.guidedJournal &&
            widget.onGuidedJournalRequested != null) {
          widget.onGuidedJournalRequested!(
              result.processedText.trim().isEmpty ? null : result.processedText);
        } else {
          widget.onInputProcessed(result);
        }

        _controller.clear();
        _focusNode.unfocus();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Failed to process input. Please try again.'),
              ],
            ),
            backgroundColor: StarboundColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleGuidedJournalTap() {
    if (widget.onGuidedJournalRequested == null || _isProcessing) return;
    HapticFeedback.lightImpact();
    final draft = _controller.text.trim();
    widget.onGuidedJournalRequested!(draft.isEmpty ? null : draft);
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = StarboundColors.stellarAqua;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? highlightColor.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.2),
                    width: _focusNode.hasFocus ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                    if (_focusNode.hasFocus)
                      ...StarboundColors.cosmicGlow(
                        highlightColor.withValues(alpha: 0.25),
                        intensity: 0.1 * _glowAnimation.value,
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 2,
                      maxLength: 500,
                      style: StarboundTypography.bodyLarge.copyWith(
                        color: StarboundColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.placeholder ?? 'Ask about symptoms, health concerns, or finding care...',
                        hintStyle: StarboundTypography.bodyLarge.copyWith(
                          color: StarboundColors.textTertiary,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                        counterText: "",
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSubmit(),
                      onChanged: (_) {
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      enabled: !_isProcessing,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (widget.onGuidedJournalRequested != null)
                          CosmicChip.action(
                            label: 'Health check-in (30-90s)',
                            icon: LucideIcons.bookOpen,
                            color: StarboundColors.stellarAqua,
                            enabled: !_isProcessing,
                            onTap: _handleGuidedJournalTap,
                          ),
                        const Spacer(),
                        _buildSubmitButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    final hasText = _controller.text.trim().isNotEmpty;
    
    return RepaintBoundary(
      child: AnimatedOpacity(
        opacity: hasText ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: hasText && !_isProcessing ? _handleSubmit : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: StarboundColors.stellarAqua.withValues(alpha: hasText ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: StarboundColors.stellarAqua.withValues(alpha: hasText ? 0.4 : 0.2),
                      width: 1,
                    ),
                    boxShadow: hasText && !_isProcessing
                        ? StarboundColors.cosmicGlow(
                            StarboundColors.stellarAqua,
                            intensity: 0.1,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProcessing)
                        CosmicLoading.small(
                          style: CosmicLoadingStyle.pulse,
                          primaryColor: StarboundColors.stellarAqua,
                        )
                      else
                        const Icon(
                          LucideIcons.arrowUpRight,
                          size: 14,
                          color: StarboundColors.stellarAqua,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isProcessing ? "Processing..." : "Send",
                        style: StarboundTypography.button.copyWith(
                          color: StarboundColors.stellarAqua,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ),
    );
  }

}
