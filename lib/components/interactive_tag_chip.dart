import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../design_system/design_system.dart';

class InteractiveTagChip extends StatefulWidget {
  final String tag;
  final String originalTag;
  final double confidence;
  final String? subdomain;
  final String? aiReasoning;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final Function(String)? onRename;
  final Function(String)? onRequestNudge;
  final bool isPinned;
  final bool isEditable;

  const InteractiveTagChip({
    Key? key,
    required this.tag,
    required this.originalTag,
    required this.confidence,
    this.subdomain,
    this.aiReasoning,
    this.onTap,
    this.onPin,
    this.onRename,
    this.onRequestNudge,
    this.isPinned = false,
    this.isEditable = true,
  }) : super(key: key);

  @override
  State<InteractiveTagChip> createState() => _InteractiveTagChipState();
}

class _InteractiveTagChipState extends State<InteractiveTagChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      _showTagExplanationModal();
    }
  }

  void _showTagExplanationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TagExplanationModal(
        tag: widget.tag,
        originalTag: widget.originalTag,
        confidence: widget.confidence,
        subdomain: widget.subdomain,
        aiReasoning: widget.aiReasoning,
        isPinned: widget.isPinned,
        onPin: widget.onPin,
        onRename: widget.onRename,
        onRequestNudge: widget.onRequestNudge,
        isEditable: widget.isEditable,
      ),
    );
  }

  Color _getTagColor() {
    final tagLower = widget.tag.toLowerCase();
    final subdomainLower = widget.subdomain?.toLowerCase() ?? '';
    
    // Anxiety and stress - red-orange
    if (tagLower.contains('anxiety') || 
        tagLower.contains('stress') || 
        tagLower.contains('panic') ||
        tagLower.contains('worried') ||
        tagLower.contains('overwhelmed')) {
      return const Color(0xFFFF6B47);
    }
    
    // Low energy and fatigue - grey-blue
    if (tagLower.contains('tired') || 
        tagLower.contains('energy') || 
        tagLower.contains('fatigue') ||
        tagLower.contains('exhausted') ||
        tagLower.contains('sleepy')) {
      return const Color(0xFF6B7B8C);
    }
    
    // Positive emotions - green
    if (tagLower.contains('happy') || 
        tagLower.contains('joy') || 
        tagLower.contains('grateful') ||
        tagLower.contains('excited') ||
        tagLower.contains('motivated')) {
      return StarboundColors.success;
    }
    
    // Sadness and depression - deep blue
    if (tagLower.contains('sad') || 
        tagLower.contains('depressed') || 
        tagLower.contains('down') ||
        tagLower.contains('lonely') ||
        tagLower.contains('hopeless')) {
      return const Color(0xFF4A5568);
    }
    
    // Physical health - teal
    if (subdomainLower.contains('physical') ||
        tagLower.contains('pain') ||
        tagLower.contains('sick') ||
        tagLower.contains('health')) {
      return StarboundColors.stellarAqua;
    }
    
    // Social/relationships - pink
    if (subdomainLower.contains('social') ||
        tagLower.contains('friend') ||
        tagLower.contains('family') ||
        tagLower.contains('relationship')) {
      return const Color(0xFFED64A6);
    }
    
    // Work/career - purple
    if (subdomainLower.contains('work') ||
        subdomainLower.contains('career') ||
        tagLower.contains('job') ||
        tagLower.contains('interview')) {
      return StarboundColors.nebulaPurple;
    }
    
    // Default - stellar yellow
    return StarboundColors.stellarYellow;
  }

  IconData _getTagIcon() {
    final tagLower = widget.tag.toLowerCase();
    
    if (tagLower.contains('anxiety') || tagLower.contains('stress')) {
      return LucideIcons.zap;
    }
    if (tagLower.contains('energy') || tagLower.contains('tired')) {
      return LucideIcons.battery;
    }
    if (tagLower.contains('happy') || tagLower.contains('joy')) {
      return LucideIcons.smile;
    }
    if (tagLower.contains('sad') || tagLower.contains('depressed')) {
      return LucideIcons.cloud;
    }
    if (tagLower.contains('pain') || tagLower.contains('health')) {
      return LucideIcons.heart;
    }
    if (tagLower.contains('work') || tagLower.contains('job')) {
      return LucideIcons.briefcase;
    }
    if (tagLower.contains('friend') || tagLower.contains('social')) {
      return LucideIcons.users;
    }
    
    return LucideIcons.tag;
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = _getTagColor();
    final confidence = widget.confidence;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.only(right: 8, bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15 + (_isHovered ? 0.05 : 0.0)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tagColor.withValues(alpha: 0.4 + (_isHovered ? 0.2 : 0.0)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (_isHovered || _isPressed) ...[
                            BoxShadow(
                              color: tagColor.withValues(alpha: 0.3 * _glowAnimation.value),
                              blurRadius: 12 * _glowAnimation.value,
                              spreadRadius: 2 * _glowAnimation.value,
                            ),
                            BoxShadow(
                              color: tagColor.withValues(alpha: 0.2 * _glowAnimation.value),
                              blurRadius: 20 * _glowAnimation.value,
                              spreadRadius: 4 * _glowAnimation.value,
                            ),
                          ],
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tag icon
                          Icon(
                            _getTagIcon(),
                            size: 14,
                            color: tagColor,
                          ),
                          const SizedBox(width: 6),
                          
                          // Tag text
                          Text(
                            widget.tag.replaceAll('_', ' '),
                            style: StarboundTypography.bodySmall.copyWith(
                              color: tagColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          
                          // Confidence indicator (subtle)
                          if (confidence < 0.7) ...[
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.helpCircle,
                              size: 10,
                              color: tagColor.withValues(alpha: 0.6),
                            ),
                          ],
                          
                          // Pin indicator
                          if (widget.isPinned) ...[
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.pin,
                              size: 10,
                              color: tagColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TagExplanationModal extends StatelessWidget {
  final String tag;
  final String originalTag;
  final double confidence;
  final String? subdomain;
  final String? aiReasoning;
  final bool isPinned;
  final VoidCallback? onPin;
  final Function(String)? onRename;
  final Function(String)? onRequestNudge;
  final bool isEditable;

  const TagExplanationModal({
    Key? key,
    required this.tag,
    required this.originalTag,
    required this.confidence,
    this.subdomain,
    this.aiReasoning,
    this.isPinned = false,
    this.onPin,
    this.onRename,
    this.onRequestNudge,
    this.isEditable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: StarboundColors.background.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: StarboundColors.stellarAqua.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  LucideIcons.brain,
                                  size: 20,
                                  color: StarboundColors.stellarAqua,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tag.replaceAll('_', ' '),
                                      style: StarboundTypography.heading2.copyWith(
                                        color: StarboundColors.textPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (subdomain != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        subdomain!,
                                        style: StarboundTypography.bodySmall.copyWith(
                                          color: StarboundColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  LucideIcons.x,
                                  color: StarboundColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // AI Transparency Section
                          _buildSection(
                            icon: LucideIcons.eye,
                            title: "How I identified this",
                            content: aiReasoning ?? 
                              "I noticed the word '${originalTag}' in your text and connected it to the ${tag.replaceAll('_', ' ')} pattern based on context clues and emotional language.",
                            color: StarboundColors.stellarAqua,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Confidence Section
                          _buildConfidenceSection(),
                          
                          const SizedBox(height: 20),
                          
                          // Actions Section
                          _buildActionsSection(context),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: StarboundTypography.heading3.copyWith(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: StarboundTypography.bodyLarge.copyWith(
              color: StarboundColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceSection() {
    final confidencePercentage = (confidence * 100).round();
    Color confidenceColor;
    String confidenceText;
    
    if (confidence >= 0.8) {
      confidenceColor = StarboundColors.success;
      confidenceText = "High confidence";
    } else if (confidence >= 0.6) {
      confidenceColor = StarboundColors.stellarYellow;
      confidenceText = "Medium confidence";
    } else {
      confidenceColor = StarboundColors.warning;
      confidenceText = "Low confidence - please verify";
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: confidenceColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: confidenceColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.target, size: 16, color: confidenceColor),
              const SizedBox(width: 8),
              Text(
                "AI Confidence: $confidencePercentage%",
                style: StarboundTypography.heading3.copyWith(
                  color: confidenceColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            confidenceText,
            style: StarboundTypography.bodyLarge.copyWith(
              color: StarboundColors.textPrimary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          // Confidence bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: confidence,
              child: Container(
                decoration: BoxDecoration(
                  color: confidenceColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Actions",
          style: StarboundTypography.heading3.copyWith(
            color: StarboundColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Request Nudge
        _buildActionButton(
          icon: LucideIcons.zap,
          title: "Get a suggestion",
          subtitle: "Want a ${tag.replaceAll('_', ' ').toLowerCase()} reset idea?",
          color: StarboundColors.stellarAqua,
          onTap: () {
            Navigator.of(context).pop();
            if (onRequestNudge != null) {
              onRequestNudge!(tag);
            }
          },
        ),
        
        const SizedBox(height: 12),
        
        // Pin/Unpin Pattern
        _buildActionButton(
          icon: isPinned ? LucideIcons.pinOff : LucideIcons.pin,
          title: isPinned ? "Unpin pattern" : "Pin this pattern",
          subtitle: isPinned 
            ? "Remove from your tracked patterns"
            : "Track this for future awareness",
          color: StarboundColors.stellarYellow,
          onTap: () {
            Navigator.of(context).pop();
            if (onPin != null) {
              onPin!();
            }
          },
        ),
        
        if (isEditable) ...[
          const SizedBox(height: 12),
          
          // Edit Tag Name
          _buildActionButton(
            icon: LucideIcons.edit,
            title: "Rename tag",
            subtitle: "Use your own words (e.g. 'Overwhelmed' instead of 'Anxiety')",
            color: StarboundColors.nebulaPurple,
            onTap: () {
              Navigator.of(context).pop();
              _showRenameDialog(context);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: StarboundTypography.bodyLarge.copyWith(
                        color: StarboundColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: StarboundTypography.bodySmall.copyWith(
                        color: StarboundColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: StarboundColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: tag);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: StarboundColors.background,
        title: Text(
          'Rename Tag',
          style: StarboundTypography.heading2.copyWith(
            color: StarboundColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use words that feel right for your experience:',
              style: StarboundTypography.bodyLarge.copyWith(
                color: StarboundColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: StarboundColors.textPrimary),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: StarboundColors.stellarAqua),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: StarboundColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onRename != null && controller.text.trim().isNotEmpty) {
                onRename!(controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: StarboundColors.stellarAqua,
              foregroundColor: StarboundColors.background,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
