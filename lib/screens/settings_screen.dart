import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_preferences.dart';
import '../services/app_preferences_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/song_storage.dart';
import '../utils/picked_file_reader.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefsService = AppPreferencesService.instance;
  late final TextEditingController _feedUrlController;

  @override
  void initState() {
    super.initState();
    _feedUrlController = TextEditingController(
      text: _prefsService.prefs.sermonFeedUrl,
    );
    _prefsService.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    _prefsService.removeListener(_onPrefsChanged);
    _feedUrlController.dispose();
    super.dispose();
  }

  void _onPrefsChanged() {
    final url = _prefsService.prefs.sermonFeedUrl;
    if (_feedUrlController.text != url) {
      _feedUrlController.text = url;
    }
    if (mounted) setState(() {});
  }

  AppPreferences get _prefs => _prefsService.prefs;

  Future<void> _pickTime({
    required TimeOfDay initial,
    required Future<void> Function(int hour, int minute) onSave,
  }) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await onSave(picked.hour, picked.minute);
    await NotificationService.instance.refreshScheduledReminders();
  }

  Future<void> _exportBackup() async {
    try {
      final csv = await BackupService.instance.exportToCsv();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/church_journal_backup_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Church Journal backup',
        text: 'Church Journal data backup',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    }
  }

  Future<void> _importBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This will replace all journal entries and songs currently on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      final csv = await readPickedFileText(result);
      if (csv == null) return;
      final importResult =
          await BackupService.instance.importFromCsv(csv, replace: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restored ${importResult.entriesImported} journal records, '
            '${importResult.songsImported} songs, and '
            '${importResult.photosImported} photos',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $error')),
      );
    }
  }

  Future<void> _shareApp() async {
    const message =
        'Church Journal helps you record worship songs, sermon notes, and scriptures by date. '
        'https://elynrose.github.io/church-journal-legal/';
    await Share.share(message, subject: 'Church Journal');
  }

  Future<void> _exportSongLibrary() async {
    try {
      final songs = SongStorage.instance.getAllSongs();
      if (songs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No songs to export yet')),
        );
        return;
      }

      final json = SongStorage.instance.exportLibraryJson();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/church_journal_songs_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Church Journal song library',
        text: 'Church Journal song library export',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    }
  }

  Future<void> _importSongLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import song library?'),
        content: const Text(
          'This will replace all songs currently on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      final json = await readPickedFileText(result);
      if (json == null) return;
      final imported = await SongStorage.instance.importFromLibraryJson(
        json,
        replace: true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported songs')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showMorning = _prefs.notificationFrequency ==
            NotificationFrequency.twiceDaily ||
        _prefs.notificationFrequency == NotificationFrequency.morningOnly;
    final showEvening = _prefs.notificationFrequency ==
            NotificationFrequency.twiceDaily ||
        _prefs.notificationFrequency == NotificationFrequency.eveningOnly;

    return ColoredBox(
      color: AppColors.offWhite,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Profile',
              child: Column(
                children: UserRole.values.map((role) {
                  return RadioListTile<UserRole>(
                    value: role,
                    groupValue: _prefs.userRole,
                    onChanged: (value) {
                      if (value != null) {
                        unawaited(_prefsService.updateUserRole(value));
                      }
                    },
                    title: Text(role.label),
                  );
                }).toList(),
              ),
            ),
            _SectionCard(
              title: 'Font size',
              child: Column(
                children: [
                  _FontSlider(
                    label: 'Bible',
                    value: _prefs.bibleFontScale,
                    onChanged: (value) =>
                        unawaited(_prefsService.updateBibleFontScale(value)),
                  ),
                  _FontSlider(
                    label: 'Notes & scriptures',
                    value: _prefs.notesFontScale,
                    onChanged: (value) =>
                        unawaited(_prefsService.updateNotesFontScale(value)),
                  ),
                  _FontSlider(
                    label: 'Song lyrics',
                    value: _prefs.lyricsFontScale,
                    onChanged: (value) =>
                        unawaited(_prefsService.updateLyricsFontScale(value)),
                  ),
                ],
              ),
            ),
            _SectionCard(
              title: 'Notifications',
              child: Column(
                children: [
                  ...NotificationFrequency.values.map(
                    (frequency) => RadioListTile<NotificationFrequency>(
                      value: frequency,
                      groupValue: _prefs.notificationFrequency,
                      onChanged: (value) async {
                        if (value == null) return;
                        await _prefsService.updateNotificationFrequency(value);
                        await NotificationService.instance
                            .refreshScheduledReminders();
                      },
                      title: Text(frequency.label),
                    ),
                  ),
                  ...NotificationSource.values.map(
                    (source) => RadioListTile<NotificationSource>(
                      value: source,
                      groupValue: _prefs.notificationSource,
                      onChanged: _prefs.notificationFrequency ==
                              NotificationFrequency.none
                          ? null
                          : (value) async {
                              if (value == null) return;
                              await _prefsService.updateNotificationSource(value);
                              await NotificationService.instance
                                  .refreshScheduledReminders();
                            },
                      title: Text(source.label),
                    ),
                  ),
                  if (showMorning)
                    ListTile(
                      title: const Text('Morning reminder'),
                      trailing: Text(
                        TimeOfDay(
                          hour: _prefs.morningHour,
                          minute: _prefs.morningMinute,
                        ).format(context),
                      ),
                      onTap: () => _pickTime(
                        initial: TimeOfDay(
                          hour: _prefs.morningHour,
                          minute: _prefs.morningMinute,
                        ),
                        onSave: _prefsService.updateMorningTime,
                      ),
                    ),
                  if (showEvening)
                    ListTile(
                      title: const Text('Evening reminder'),
                      trailing: Text(
                        TimeOfDay(
                          hour: _prefs.eveningHour,
                          minute: _prefs.eveningMinute,
                        ).format(context),
                      ),
                      onTap: () => _pickTime(
                        initial: TimeOfDay(
                          hour: _prefs.eveningHour,
                          minute: _prefs.eveningMinute,
                        ),
                        onSave: _prefsService.updateEveningTime,
                      ),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mood scriptures'),
                    subtitle: const Text(
                      'Include mood-based KJV verses in reminders. '
                      'Morning & evening also sends a midday mood verse.',
                    ),
                    value: _prefs.moodNotificationsEnabled,
                    onChanged: _prefs.notificationFrequency ==
                            NotificationFrequency.none
                        ? null
                        : (value) async {
                            await _prefsService
                                .updateMoodNotificationsEnabled(value);
                            await NotificationService.instance
                                .refreshScheduledReminders();
                          },
                  ),
                ],
              ),
            ),
            _SectionCard(
              title: 'Podcast feed',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Standard RSS 2.0 / podcast feed URL (title, author, pubDate, enclosure, category). '
                    'Optional channel fields: pin, order_by, order_direction.',
                    style: TextStyle(fontSize: 13, color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feedUrlController,
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/sermons.xml',
                      border: AppColors.outlineInputBorder,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    onSubmitted: (value) => unawaited(
                      _prefsService.updateSermonFeedUrl(value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => unawaited(
                        _prefsService.updateSermonFeedUrl(
                          _feedUrlController.text,
                        ),
                      ),
                      child: const Text('Save podcast URL'),
                    ),
                  ),
                ],
              ),
            ),
            _SectionCard(
              title: 'Song library',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.file_upload_outlined, color: AppColors.text),
                    title: const Text('Import'),
                    onTap: () => unawaited(_importSongLibrary()),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.ios_share, color: AppColors.text),
                    title: const Text('Export'),
                    onTap: _exportSongLibrary,
                  ),
                ],
              ),
            ),
            _SectionCard(
              title: 'Backup & restore',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_file, color: AppColors.text),
                    title: const Text('Export backup (CSV)'),
                    subtitle: const Text(
                      'Journal entries, sermon details, and songs',
                    ),
                    onTap: _exportBackup,
                  ),
                  ListTile(
                    leading: const Icon(Icons.download, color: AppColors.text),
                    title: const Text('Restore from backup'),
                    subtitle: const Text('Replace current data from a CSV file'),
                    onTap: _importBackup,
                  ),
                ],
              ),
            ),
            _SectionCard(
              title: 'Share',
              child: ListTile(
                leading: const Icon(Icons.share, color: AppColors.text),
                title: const Text('Share Church Journal'),
                subtitle: const Text('Tell others about the app'),
                onTap: _shareApp,
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'hello@churchjournal.app',
                style: TextStyle(color: AppColors.text, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _FontSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _FontSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.text)),
        Row(
          children: [
            const Text('A', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: value,
                min: 0.85,
                max: 1.5,
                divisions: 13,
                label: '${(value * 100).round()}%',
                onChanged: onChanged,
              ),
            ),
            const Text('A', style: TextStyle(fontSize: 18)),
          ],
        ),
      ],
    );
  }
}
