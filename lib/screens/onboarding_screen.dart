import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_preferences.dart';
import '../services/app_preferences_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  UserRole _role = UserRole.laity;
  NotificationFrequency _frequency = NotificationFrequency.twiceDaily;
  NotificationSource _source = NotificationSource.both;
  TimeOfDay _morningTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 19, minute: 0);

  Future<void> _finish() async {
    await AppPreferencesService.instance.completeOnboarding(
      userRole: _role,
      notificationFrequency: _frequency,
      notificationSource: _source,
      morningHour: _morningTime.hour,
      morningMinute: _morningTime.minute,
      eveningHour: _eveningTime.hour,
      eveningMinute: _eveningTime.minute,
    );
    await NotificationService.instance.refreshScheduledReminders();
  }

  void _next() {
    if (_page >= 2) {
      unawaited(_finish());
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _page = index),
                children: [
                  _WelcomeStep(),
                  _RoleStep(
                    selected: _role,
                    onChanged: (role) => setState(() => _role = role),
                  ),
                  _NotificationStep(
                    frequency: _frequency,
                    source: _source,
                    morningTime: _morningTime,
                    eveningTime: _eveningTime,
                    onFrequencyChanged: (value) =>
                        setState(() => _frequency = value),
                    onSourceChanged: (value) => setState(() => _source = value),
                    onMorningChanged: (value) =>
                        setState(() => _morningTime = value),
                    onEveningChanged: (value) =>
                        setState(() => _eveningTime = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dustyBlue,
                    foregroundColor: AppColors.text,
                  ),
                  onPressed: _next,
                  child: Text(_page >= 2 ? 'Get started' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Welcome to Church Journal',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Capture worship songs, sermon notes, and scriptures by date. '
            'Plan ahead for future services or look back on past ones.',
            style: TextStyle(fontSize: 16, color: AppColors.text, height: 1.5),
          ),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.seafoam,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Your journal stays on your device. You can back up anytime from Settings.',
                style: TextStyle(color: AppColors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleStep extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  const _RoleStep({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Who are you?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps tailor your experience. You can change it later in Settings.',
            style: TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 24),
          ...UserRole.values.map(
            (role) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RadioListTile<UserRole>(
                value: role,
                groupValue: selected,
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
                title: Text(role.label),
                tileColor: selected == role
                    ? AppColors.creamyYellow
                    : AppColors.offWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationStep extends StatelessWidget {
  final NotificationFrequency frequency;
  final NotificationSource source;
  final TimeOfDay morningTime;
  final TimeOfDay eveningTime;
  final ValueChanged<NotificationFrequency> onFrequencyChanged;
  final ValueChanged<NotificationSource> onSourceChanged;
  final ValueChanged<TimeOfDay> onMorningChanged;
  final ValueChanged<TimeOfDay> onEveningChanged;

  const _NotificationStep({
    required this.frequency,
    required this.source,
    required this.morningTime,
    required this.eveningTime,
    required this.onFrequencyChanged,
    required this.onSourceChanged,
    required this.onMorningChanged,
    required this.onEveningChanged,
  });

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final showMorning = frequency == NotificationFrequency.twiceDaily ||
        frequency == NotificationFrequency.morningOnly;
    final showEvening = frequency == NotificationFrequency.twiceDaily ||
        frequency == NotificationFrequency.eveningOnly;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Reminders',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how often you want reminders and what they should show.',
            style: TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 20),
          const Text('How often?', style: TextStyle(fontWeight: FontWeight.bold)),
          ...NotificationFrequency.values.map(
            (item) => RadioListTile<NotificationFrequency>(
              value: item,
              groupValue: frequency,
              onChanged: (value) {
                if (value != null) onFrequencyChanged(value);
              },
              title: Text(item.label),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Show content from', style: TextStyle(fontWeight: FontWeight.bold)),
          ...NotificationSource.values.map(
            (item) => RadioListTile<NotificationSource>(
              value: item,
              groupValue: source,
              onChanged: frequency == NotificationFrequency.none
                  ? null
                  : (value) {
                      if (value != null) onSourceChanged(value);
                    },
              title: Text(item.label),
            ),
          ),
          if (showMorning) ...[
            ListTile(
              title: const Text('Morning time'),
              trailing: Text(morningTime.format(context)),
              onTap: () => _pickTime(context, morningTime, onMorningChanged),
            ),
          ],
          if (showEvening) ...[
            ListTile(
              title: const Text('Evening time'),
              trailing: Text(eveningTime.format(context)),
              onTap: () => _pickTime(context, eveningTime, onEveningChanged),
            ),
          ],
        ],
      ),
    );
  }
}