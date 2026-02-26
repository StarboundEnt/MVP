import 'package:flutter/material.dart';
import '../design_system/design_system.dart';

class ChoiceOption {
  final String label;
  final String value;
  
  const ChoiceOption({
    required this.label,
    required this.value,
  });
  
  // Performance optimization: Override equality for efficient comparisons
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChoiceOption &&
        other.label == label &&
        other.value == value;
  }

  @override
  int get hashCode => label.hashCode ^ value.hashCode;

  // Convert to HabitOption for new design system
  HabitOption toHabitOption() {
    return HabitOption(label: label, value: value);
  }
}

class HabitCard extends StatelessWidget {
  final String title;
  final String emoji;
  final List<ChoiceOption> options;
  final String? current;
  final ValueChanged<String?> onSelected;

  const HabitCard({
    Key? key,
    required this.title,
    required this.emoji,
    required this.options,
    this.current,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the new CosmicHabitCard with converted options
    return CosmicHabitCard(
      title: title,
      emoji: emoji,
      options: options.map((option) => option.toHabitOption()).toList(),
      currentValue: current,
      onSelectionChanged: onSelected,
    );
  }
}
