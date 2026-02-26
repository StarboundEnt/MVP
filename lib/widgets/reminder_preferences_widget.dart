import 'dart:ui';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import '../services/journaling_reminder_service.dart' as reminders;
import '../design_system/colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Widget for managing journaling reminder preferences
typedef ReminderPreferences = reminders.ReminderPreferences;
typedef ReminderWindow = reminders.ReminderWindow;
typedef ReminderServiceTime = reminders.TimeOfDay;

class ReminderPreferencesWidget extends StatefulWidget {
  final ReminderPreferences initialPreferences;
  final Function(ReminderPreferences) onPreferencesChanged;

  const ReminderPreferencesWidget({
    super.key,
    required this.initialPreferences,
    required this.onPreferencesChanged,
  });

  @override
  State<ReminderPreferencesWidget> createState() => _ReminderPreferencesWidgetState();
}

class _ReminderPreferencesWidgetState extends State<ReminderPreferencesWidget> {
  late ReminderPreferences _preferences;
  final reminders.JournalingReminderService _reminderService =
      reminders.JournalingReminderService();

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences;
  }

  void _updatePreferences(ReminderPreferences newPreferences) {
    setState(() {
      _preferences = newPreferences;
    });
    widget.onPreferencesChanged(newPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StarboundColors.deepSpace.withValues(alpha: 0.1),
            StarboundColors.nebulaPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: StarboundColors.stellarYellow.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildMainToggle(),
                if (_preferences.isEnabled) ...[
                  const SizedBox(height: 20),
                  _buildReminderWindows(),
                  const SizedBox(height: 20),
                  _buildAdvancedOptions(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: StarboundColors.stellarYellow.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            LucideIcons.bell,
            color: StarboundColors.stellarYellow,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gentle Reminders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: StarboundColors.cosmicWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _reminderService.getEncouragementMessage(),
                style: TextStyle(
                  fontSize: 13,
                  color: StarboundColors.cosmicWhite.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StarboundColors.stellarYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StarboundColors.stellarYellow.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable gentle reminders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: StarboundColors.cosmicWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gentle reminders to track your health',
                  style: TextStyle(
                    fontSize: 14,
                    color: StarboundColors.cosmicWhite.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: _preferences.isEnabled,
            onChanged: (value) {
              _updatePreferences(_preferences.copyWith(isEnabled: value));
            },
            activeColor: StarboundColors.stellarYellow,
            inactiveThumbColor: StarboundColors.cosmicWhite.withValues(alpha: 0.7),
            inactiveTrackColor: StarboundColors.deepSpace.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderWindows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your reminder times',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: StarboundColors.cosmicWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select when you\'d like health check-in reminders',
          style: TextStyle(
            fontSize: 13,
            color: StarboundColors.cosmicWhite.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        ...ReminderWindow.values.map((window) => _buildReminderWindowOption(window)),
      ],
    );
  }

  Widget _buildReminderWindowOption(ReminderWindow window) {
    final isEnabled = _preferences.enabledWindows.contains(window);
    final customTime = _preferences.customTimes[window];
    final displayTime = customTime?.format12Hour() ?? window.defaultTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isEnabled 
          ? StarboundColors.stellarYellow.withValues(alpha: 0.1)
          : StarboundColors.deepSpace.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled 
            ? StarboundColors.stellarYellow.withValues(alpha: 0.3)
            : StarboundColors.cosmicWhite.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getWindowIcon(window),
                color: isEnabled ? StarboundColors.stellarYellow : StarboundColors.cosmicWhite.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      window.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isEnabled ? StarboundColors.cosmicWhite : StarboundColors.cosmicWhite.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      displayTime,
                      style: TextStyle(
                        fontSize: 13,
                        color: isEnabled ? StarboundColors.stellarYellow : StarboundColors.cosmicWhite.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isEnabled,
                onChanged: (value) {
                  final newWindows = Set<ReminderWindow>.from(_preferences.enabledWindows);
                  if (value == true) {
                    newWindows.add(window);
                  } else {
                    newWindows.remove(window);
                  }
                  _updatePreferences(_preferences.copyWith(enabledWindows: newWindows));
                },
                activeColor: StarboundColors.stellarYellow,
                checkColor: StarboundColors.deepSpace,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 8),
            _buildTimeCustomization(window),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeCustomization(ReminderWindow window) {
    final customTime = _preferences.customTimes[window];
    final currentTime = customTime ?? ReminderServiceTime(
      hour: window.defaultHour,
      minute: window.defaultMinute,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: StarboundColors.deepSpace.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Custom time:',
              style: TextStyle(
                fontSize: 13,
                color: StarboundColors.cosmicWhite.withValues(alpha: 0.8),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _selectTime(window, currentTime),
            style: TextButton.styleFrom(
              foregroundColor: StarboundColors.stellarYellow,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              currentTime.format12Hour(),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          if (customTime != null)
            IconButton(
              onPressed: () => _resetToDefault(window),
              icon: Icon(
                LucideIcons.rotateCcw,
                size: 14,
                color: StarboundColors.cosmicWhite.withValues(alpha: 0.6),
              ),
              tooltip: 'Reset to default',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: StarboundColors.cosmicWhite,
          ),
        ),
        const SizedBox(height: 10),
        _buildAdvancedOption(
          icon: LucideIcons.calendar,
          title: 'Skip weekends',
          subtitle: 'No reminders on Saturday and Sunday',
          value: _preferences.skipWeekendsEnabled,
          onChanged: (value) {
            _updatePreferences(_preferences.copyWith(skipWeekendsEnabled: value));
          },
        ),
        const SizedBox(height: 8),
        _buildAdvancedOption(
          icon: LucideIcons.clock,
          title: 'Only when inactive',
          subtitle: 'Only remind me after ${_preferences.inactivityDays} days without journaling',
          value: _preferences.onlyAfterInactivityEnabled,
          onChanged: (value) {
            _updatePreferences(_preferences.copyWith(onlyAfterInactivityEnabled: value));
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StarboundColors.deepSpace.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: StarboundColors.cosmicWhite.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: StarboundColors.stellarYellow.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: StarboundColors.cosmicWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: StarboundColors.cosmicWhite.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: StarboundColors.stellarYellow,
            inactiveThumbColor: StarboundColors.cosmicWhite.withValues(alpha: 0.7),
            inactiveTrackColor: StarboundColors.deepSpace.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  IconData _getWindowIcon(reminders.ReminderWindow window) {
    switch (window) {
      case reminders.ReminderWindow.morning:
        return LucideIcons.sunrise;
      case reminders.ReminderWindow.lunch:
        return LucideIcons.sun;
      case reminders.ReminderWindow.evening:
        return LucideIcons.sunset;
    }
  }

  Future<void> _selectTime(
    ReminderWindow window,
    ReminderServiceTime currentTime,
  ) async {
    final material.TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: material.TimeOfDay(hour: currentTime.hour, minute: currentTime.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: StarboundColors.stellarYellow,
              onSurface: StarboundColors.cosmicWhite,
              surface: StarboundColors.deepSpace,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newCustomTimes =
          Map<ReminderWindow, ReminderServiceTime>.from(_preferences.customTimes);
      newCustomTimes[window] =
          ReminderServiceTime(hour: picked.hour, minute: picked.minute);
      _updatePreferences(_preferences.copyWith(customTimes: newCustomTimes));
    }
  }

  void _resetToDefault(ReminderWindow window) {
    final newCustomTimes =
        Map<ReminderWindow, ReminderServiceTime>.from(_preferences.customTimes);
    newCustomTimes.remove(window);
    _updatePreferences(_preferences.copyWith(customTimes: newCustomTimes));
  }
}
