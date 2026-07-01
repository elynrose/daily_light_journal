import 'dart:async';

import 'package:flutter/material.dart';

import 'models/entry.dart';
import 'models/notification_payload.dart';
import 'screens/bible_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/songs_screen.dart';
import 'services/app_preferences_service.dart';
import 'services/bible_storage.dart';
import 'services/entry_storage.dart';
import 'services/journal_context.dart';
import 'services/notification_service.dart';
import 'services/photo_storage.dart';
import 'services/song_storage.dart';
import 'theme/app_colors.dart';
import 'widgets/app_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EntryStorage.instance.init();
  await SongStorage.instance.init();
  await PhotoStorage.instance.init();
  await AppPreferencesService.instance.init();
  await BibleStorage.instance.load();
  await NotificationService.instance.init();
  await NotificationService.instance.refreshScheduledReminders();
  runApp(const DailyLightJournalApp());
}

class DailyLightJournalApp extends StatelessWidget {
  const DailyLightJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppPreferencesService.instance,
      builder: (context, _) {
        final onboardingComplete =
            AppPreferencesService.instance.onboardingComplete;

        return MaterialApp(
          title: 'Church Journal',
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.offWhite,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.dustyBlue,
            ).copyWith(onSurface: AppColors.text),
            useMaterial3: true,
            textTheme: ThemeData.light().textTheme.apply(
                  bodyColor: AppColors.text,
                  displayColor: AppColors.text,
                ),
            appBarTheme: const AppBarTheme(
              foregroundColor: AppColors.text,
              backgroundColor: AppColors.dustyBlue,
            ),
            iconTheme: const IconThemeData(color: AppColors.text),
            inputDecorationTheme: const InputDecorationTheme(
              labelStyle: TextStyle(color: AppColors.text),
              hintStyle: TextStyle(color: AppColors.text),
            ),
          ),
          home: onboardingComplete ? const AppShell() : const OnboardingScreen(),
        );
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  AppTab _selectedTab = AppTab.notes;
  EntryCategory _journalCategory = EntryCategory.song;
  DateTime? _journalDate;
  ServicePeriod? _journalPeriod;
  int _journalRefreshToken = 0;
  String? _bibleInitialReference;
  int _bibleRefreshToken = 0;
  StreamSubscription<NotificationPayload>? _notificationTapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationTapSub =
        NotificationService.instance.onNotificationTap.listen(
      _openNotificationTarget,
    );

    final pending = NotificationService.instance.takePendingNotificationTap();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openNotificationTarget(pending);
      });
    }
  }

  @override
  void dispose() {
    _notificationTapSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(NotificationService.instance.refreshScheduledReminders());
    }
  }

  void _onTabSelected(AppTab tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  void _onAddedToJournal(EntryCategory category) {
    final journal = JournalContext.instance;
    setState(() {
      _selectedTab = AppTab.notes;
      _journalCategory = category;
      _journalDate = journal.date;
      _journalPeriod = journal.period;
      _journalRefreshToken++;
    });
  }

  void _onAddedSongToJournal() => _onAddedToJournal(EntryCategory.song);

  void _onAddedScriptureToJournal() =>
      _onAddedToJournal(EntryCategory.scripture);

  void _onOpenBibleReference(String reference) {
    setState(() {
      _selectedTab = AppTab.bible;
      _bibleInitialReference = reference;
      _bibleRefreshToken++;
    });
  }

  void _openNotificationTarget(NotificationPayload payload) {
    if (!mounted) return;

    switch (payload) {
      case JournalNotificationPayload():
        setState(() {
          _selectedTab = AppTab.notes;
          _journalCategory = payload.category;
          _journalDate = payload.date;
          _journalPeriod = payload.period;
          _journalRefreshToken++;
        });
      case BibleNotificationPayload():
        setState(() {
          _selectedTab = AppTab.bible;
          _bibleInitialReference = payload.reference;
          _bibleRefreshToken++;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: AppBottomNav(
        selectedTab: _selectedTab,
        onTabSelected: _onTabSelected,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case AppTab.notes:
        return JournalScreen(
          key: ValueKey(
            'journal-${_journalCategory.name}-'
            '${_journalDate?.millisecondsSinceEpoch ?? 'today'}-'
            '${_journalPeriod?.name ?? 'auto'}-'
            '$_journalRefreshToken',
          ),
          initialCategory: _journalCategory,
          initialDate: _journalDate,
          initialPeriod: _journalPeriod,
          onScriptureReferenceTap: _onOpenBibleReference,
        );
      case AppTab.songs:
        return SongsScreen(
          key: const ValueKey('songs'),
          onAddedToNotes: _onAddedSongToJournal,
        );
      case AppTab.bible:
        return BibleScreen(
          key: ValueKey(
            'bible-$_bibleRefreshToken-${_bibleInitialReference ?? ''}',
          ),
          initialReference: _bibleInitialReference,
          onAddedToScriptures: _onAddedScriptureToJournal,
        );
      case AppTab.gallery:
        return const GalleryScreen(key: ValueKey('gallery'));
      case AppTab.settings:
        return const SettingsScreen(key: ValueKey('settings'));
    }
  }
}
