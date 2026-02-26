/// Starbound Design System
/// 
/// A clean, retro-futuristic design system for the Starbound health companion app.
/// Features cosmic minimalism with space-themed elements and your brand colors.
/// 
/// Usage:
/// ```dart
/// import 'package:starbound/design_system/design_system.dart';
/// 
/// // Use colors
/// Container(color: StarboundColors.stellarAqua)
/// 
/// // Use typography
/// Text('Hello', style: StarboundTypography.heading1)
/// 
/// // Use spacing
/// Padding(padding: StarboundSpacing.paddingMD)
/// 
/// // Use animations
/// AnimationController controller = StarboundAnimations.createCosmicController(vsync: this);
/// 
/// // Use components
/// CosmicButton.primary(child: Text('Click me'), onPressed: () {})
/// CosmicInput(hintText: 'Enter text...')
/// CosmicChip.choice(label: 'Option', isSelected: true)
/// ```

library design_system;

// Export all design system foundations
export 'colors.dart';
export 'typography.dart';
export 'spacing.dart';
export 'animations.dart';
export 'breakpoints.dart';

// Export all design system components
export 'components/cosmic_button.dart';
export 'components/cosmic_input.dart';
export 'components/cosmic_chip.dart';
export 'components/cosmic_habit_card.dart';
export 'components/cosmic_celebration.dart';
export 'components/cosmic_loading.dart';
export 'components/gravitational_fab.dart';
export 'components/cosmic_glass_panel.dart';
export 'components/cosmic_page_scaffold.dart';
export 'components/cosmic_icon_badge.dart';
export 'components/cosmic_parallax_field.dart';
export 'components/cosmic_capsule_header.dart';
export 'components/cosmic_search_bar.dart';
