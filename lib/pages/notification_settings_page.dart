import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../services/error_service.dart';
import '../services/journaling_reminder_service.dart' as reminders;
import '../widgets/reminder_preferences_widget.dart';
import '../models/complexity_profile.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late bool _notificationsEnabled;
  late String _preferredTime;
  late List<int> _selectedDays;
  
  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final reminders.JournalingReminderService _reminderService = reminders.JournalingReminderService();
  ReminderPreferences _reminderPreferences = const ReminderPreferences();
  
  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _notificationsEnabled = appState.notificationsEnabled;
    _preferredTime = appState.notificationTime;
    _selectedDays = List.from(appState.notificationDays);
    _loadReminderPreferences();
  }
  
  Future<void> _loadReminderPreferences() async {
    try {
      final preferences = await _reminderService.getReminderPreferences();
      setState(() {
        _reminderPreferences = preferences;
      });
    } catch (e) {
      // Handle error silently for now
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notification Settings',
          style: AppConstants.heading2,
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppConstants.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationToggle(),
            const SizedBox(height: AppConstants.spacingXL),
            
            if (_notificationsEnabled) ...[
              _buildTimeSelector(),
              const SizedBox(height: AppConstants.spacingXL),
              
              _buildDaySelector(),
              const SizedBox(height: AppConstants.spacingXL),
              
              _buildNotificationTypes(),
              const SizedBox(height: AppConstants.spacingXL),
              
              _buildAdaptiveFeatures(),
              const SizedBox(height: AppConstants.spacingXL),
            ],
            
            // Add journaling reminders section
            _buildJournalingReminders(),
            const SizedBox(height: AppConstants.spacingXL),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationToggle() {
    return Container(
      padding: AppConstants.paddingL,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppConstants.spacingM),
              const Expanded(
                child: Text(
                  'Smart Notifications',
                  style: AppConstants.heading2,
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                activeColor: AppConstants.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            _notificationsEnabled 
                ? 'Receive personalized reminders and encouragement based on your habits and progress.'
                : 'Enable notifications to get gentle reminders and celebrate your progress.',
            style: AppConstants.bodyTextSecondary,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeSelector() {
    return Container(
      padding: AppConstants.paddingL,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              const Text(
                'Preferred Time',
                style: AppConstants.bodyText,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          InkWell(
            onTap: _selectTime,
            borderRadius: AppConstants.borderRadiusM,
            child: Container(
              padding: AppConstants.paddingM,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: AppConstants.borderRadiusM,
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Text(
                    _formatTime(_preferredTime),
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.edit,
                    color: AppConstants.primaryColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Starbound will adapt this time based on your complexity profile for optimal engagement.',
            style: AppConstants.caption,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDaySelector() {
    return Container(
      padding: AppConstants.paddingL,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              const Text(
                'Active Days',
                style: AppConstants.bodyText,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Wrap(
            spacing: AppConstants.spacingS,
            children: List.generate(7, (index) {
              final dayIndex = index + 1; // 1-7 for Mon-Sun
              final isSelected = _selectedDays.contains(dayIndex);
              
              return FilterChip(
                label: Text(_dayNames[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(dayIndex);
                    } else {
                      _selectedDays.remove(dayIndex);
                    }
                    _selectedDays.sort();
                  });
                },
                selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: AppConstants.primaryColor,
                side: BorderSide(
                  color: isSelected 
                      ? AppConstants.primaryColor 
                      : Colors.white.withValues(alpha: 0.3),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? AppConstants.primaryColor : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationTypes() {
    return Container(
      padding: AppConstants.paddingL,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              const Text(
                'Notification Types',
                style: AppConstants.bodyText,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          _buildNotificationTypeItem(
            icon: Icons.lightbulb_outline,
            title: 'Contextual Nudges',
            description: 'Smart suggestions based on your current habits and patterns',
            enabled: true,
          ),
          
          const SizedBox(height: AppConstants.spacingM),
          
          _buildNotificationTypeItem(
            icon: Icons.local_fire_department,
            title: 'Streak Protection',
            description: 'Gentle reminders to maintain your habit streaks',
            enabled: true,
          ),
          
          const SizedBox(height: AppConstants.spacingM),
          
          _buildNotificationTypeItem(
            icon: Icons.check_circle_outline,
            title: 'Daily Check-ins',
            description: 'Adaptive check-ins based on your complexity profile',
            enabled: true,
          ),
          
          const SizedBox(height: AppConstants.spacingM),
          
          _buildNotificationTypeItem(
            icon: Icons.celebration,
            title: 'Achievements',
            description: 'Celebrate milestones and progress',
            enabled: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationTypeItem({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
  }) {
    return Container(
      padding: AppConstants.paddingM,
      decoration: BoxDecoration(
        color: enabled 
            ? AppConstants.primaryColor.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: AppConstants.borderRadiusS,
        border: Border.all(
          color: enabled 
              ? AppConstants.primaryColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? AppConstants.primaryColor : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: enabled ? Colors.white70 : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (enabled)
            Icon(
              Icons.check_circle,
              color: AppConstants.primaryColor,
              size: 16,
            ),
        ],
      ),
    );
  }
  
  Widget _buildAdaptiveFeatures() {
    return Container(
      padding: AppConstants.paddingL,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: AppConstants.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              const Text(
                'Adaptive Intelligence',
                style: AppConstants.bodyText,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          Consumer<AppState>(
            builder: (context, appState, child) {
              final profile = appState.complexityProfile;
              return Container(
                padding: AppConstants.paddingM,
                decoration: BoxDecoration(
                  color: AppConstants.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: AppConstants.borderRadiusS,
                  border: Border.all(
                    color: AppConstants.secondaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.secondaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile.name.toUpperCase(),
                            style: TextStyle(
                              color: AppConstants.secondaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.auto_awesome,
                          color: AppConstants.secondaryColor,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      _getAdaptiveDescription(profile),
                      style: TextStyle(
                        color: AppConstants.secondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  String _getAdaptiveDescription(ComplexityLevel profile) {
    switch (profile) {
      case ComplexityLevel.stable:
        return 'Notifications are optimized for consistency and routine building. You\'ll receive regular, encouraging reminders.';
      case ComplexityLevel.trying:
        return 'Notifications adapt to help you find what works. Timing varies slightly to discover your optimal engagement patterns.';
      case ComplexityLevel.overloaded:
        return 'Notifications are gentler and less frequent to avoid overwhelming you. Focus is on support rather than pressure.';
      case ComplexityLevel.survival:
        return 'Notifications are minimal and extremely gentle. Only the most supportive and caring messages are sent.';
    }
  }
  
  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '$displayHour:$displayMinute $period';
  }
  
  Future<void> _selectTime() async {
    final parts = _preferredTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.surfaceColor,
              surface: AppConstants.surfaceColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedTime != null) {
      setState(() {
        _preferredTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      });
    }
  }
  
  Widget _buildJournalingReminders() {
    return ReminderPreferencesWidget(
      initialPreferences: _reminderPreferences,
      onPreferencesChanged: (newPreferences) async {
        try {
          await _reminderService.saveReminderPreferences(newPreferences);
          setState(() {
            _reminderPreferences = newPreferences;
          });
        } catch (e) {
          if (mounted) {
            ErrorService.showUserFeedback(
              context,
              'Failed to save reminder preferences. Please try again.',
              type: ErrorType.unknown,
            );
          }
        }
      },
    );
  }

  Future<void> _saveSettings() async {
    try {
      final appState = context.read<AppState>();
      
      await appState.updateNotificationPreferences(
        enabled: _notificationsEnabled,
        preferredTime: _preferredTime,
        enabledDays: _selectedDays,
      );
      
      // Also save reminder preferences
      await _reminderService.saveReminderPreferences(_reminderPreferences);
      
      if (mounted) {
        ErrorService.showSuccessFeedback(
          context,
          'Notification preferences saved successfully!',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showUserFeedback(
          context,
          'Failed to save preferences. Please try again.',
          type: ErrorType.unknown,
        );
      }
    }
  }
}
