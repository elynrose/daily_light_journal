import 'dart:async';

import 'package:flutter/material.dart';

import 'models/entry.dart';
import 'screens/bible_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/songs_screen.dart';
import 'services/bible_storage.dart';
import 'services/entry_storage.dart';
import 'services/notification_service.dart';
import 'services/song_storage.dart';
import 'theme/app_colors.dart';
import 'widgets/app_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EntryStorage.instance.init();
  await SongStorage.instance.init();
  await SongStorage.instance.seedFromAssetIfEmpty();
  await BibleStorage.instance.load();
  await NotificationService.instance.init();
  await NotificationService.instance.refreshScheduledReminders();
  runApp(const DailyLightJournalApp());
}

class DailyLightJournalApp extends StatelessWidget {
  const DailyLightJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Light Journal',
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
      home: const AppShell(),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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

  void _onAddedToNotes() {
    setState(() {
      _selectedTab = AppTab.notes;
      _journalCategory = EntryCategory.song;
      _journalDate = EntryStorage.normalizeDate(DateTime.now());
      _journalPeriod = servicePeriodFromTime(DateTime.now());
      _journalRefreshToken++;
    });
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
        );
      case AppTab.songs:
        return SongsScreen(
          key: const ValueKey('songs'),
          onAddedToNotes: _onAddedToNotes,
        );
      case AppTab.bible:
        return const BibleScreen(key: ValueKey('bible'));
    }
  }
}
