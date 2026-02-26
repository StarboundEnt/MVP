import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../colors.dart';
import '../typography.dart';

/// Consistent search bar shell used across Starbound screens.
class CosmicSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Widget? leading;
  final Widget? trailing;
  final Widget? trailingInline;
  final Widget? footer;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final int minLines;
  final int maxLines;
  final TextInputAction textInputAction;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool enabled;
  final String? semanticsLabel;
  final String? semanticsHint;
  final Color? accentColor;

  const CosmicSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.leading,
    this.trailing,
    this.trailingInline,
    this.footer,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.search,
    this.textStyle,
    this.hintStyle,
    this.enabled = true,
    this.semanticsLabel,
    this.semanticsHint,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseFill = StarboundColors.surface.withValues(
      alpha: enabled ? 0.85 : 0.5,
    );
    final Color accent = accentColor ?? StarboundColors.stellarAqua;

    final Widget searchField = Semantics(
      label: semanticsLabel,
      hint: semanticsHint,
      textField: true,
      enabled: enabled,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: baseFill,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: accent.withValues(alpha: 0.32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading ??
                Icon(
                  LucideIcons.search,
                  size: 20,
                  color: accent,
                ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                focusNode: focusNode,
                minLines: minLines,
                maxLines: maxLines,
                style: textStyle ??
                    StarboundTypography.bodyLarge.copyWith(
                      color: StarboundColors.textPrimary,
                      fontSize: 16,
                    ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: hintText,
                  hintStyle: hintStyle ??
                      StarboundTypography.body.copyWith(
                        color: StarboundColors.textSecondary
                            .withValues(alpha: 0.7),
                      ),
                  contentPadding: EdgeInsets.zero,
                ),
                textInputAction: textInputAction,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
            if (trailingInline != null) ...[
              trailingInline!,
              const SizedBox(width: 12),
            ],
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );

    if (footer == null) {
      return searchField;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchField,
        const SizedBox(height: 12),
        footer!,
      ],
    );
  }
}
