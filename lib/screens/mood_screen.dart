import 'dart:async';

import 'package:flutter/material.dart';

import '../models/mood_profile.dart';
import '../models/mood_scripture.dart';
import '../services/app_preferences_service.dart';
import '../services/mood_storage.dart';
import '../theme/app_colors.dart';

class MoodScreen extends StatefulWidget {
  final String? initialMoodName;
  final String? initialScriptureReference;

  const MoodScreen({
    super.key,
    this.initialMoodName,
    this.initialScriptureReference,
  });

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final _storage = MoodStorage.instance;
  final _prefsService = AppPreferencesService.instance;
  late final PageController _pageController;

  bool _loading = true;
  int _selectedIndex = 0;
  MoodScripture? _currentScripture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    unawaited(_load());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _storage.load();
    if (!mounted) return;

    final moods = _storage.moods;
    final targetMood =
        widget.initialMoodName ?? _prefsService.prefs.selectedMoodName;
    var index = 0;
    if (targetMood != null) {
      final found = moods.indexWhere((mood) => mood.name == targetMood);
      if (found >= 0) index = found;
    }

    MoodScripture? scripture;
    if (moods.isNotEmpty) {
      final moodName = moods[index].name;
      if (widget.initialScriptureReference != null) {
        scripture = _storage.findForMoodAndReference(
          moodName,
          widget.initialScriptureReference!,
        );
      }
      scripture ??= _storage.pickRandomForMood(moodName);
      await _prefsService.updateSelectedMoodName(moodName);
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _selectedIndex = index;
      _currentScripture = scripture;
    });

    if (index > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(index);
        }
      });
    }
  }

  Future<void> _onMoodIndexChanged(int index) async {
    final moods = _storage.moods;
    if (index < 0 || index >= moods.length) return;

    final moodName = moods[index].name;
    final scripture = _storage.pickRandomForMood(moodName);
    await _prefsService.updateSelectedMoodName(moodName);
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      _currentScripture = scripture;
    });
  }

  void _showAnotherScripture() {
    final moods = _storage.moods;
    if (moods.isEmpty) return;
    final moodName = moods[_selectedIndex].name;
    setState(() {
      _currentScripture = _storage.pickRandomForMood(moodName);
    });
  }

  void _stepMood(int delta) {
    final moods = _storage.moods;
    if (moods.isEmpty || !_pageController.hasClients) return;
    final next = (_selectedIndex + delta).clamp(0, moods.length - 1);
    if (next == _selectedIndex) return;
    unawaited(
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final moods = _storage.moods;
    if (moods.isEmpty) {
      return const Center(
        child: Text('No moods available', style: TextStyle(color: AppColors.text)),
      );
    }

    final selectedMood = moods[_selectedIndex];
    final profile = MoodProfile.forMood(selectedMood.name);
    final scripture = _currentScripture;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const _MoodHeader(),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                _CarouselArrow(
                  icon: Icons.chevron_left,
                  onPressed:
                      _selectedIndex > 0 ? () => _stepMood(-1) : null,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: moods.length,
                    onPageChanged: (index) => unawaited(_onMoodIndexChanged(index)),
                    itemBuilder: (context, index) {
                      return _MoodFace(
                        emoji: moods[index].emoji,
                        selected: index == _selectedIndex,
                      );
                    },
                  ),
                ),
                _CarouselArrow(
                  icon: Icons.chevron_right,
                  onPressed: _selectedIndex < moods.length - 1
                      ? () => _stepMood(1)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PageDots(
            count: moods.length,
            index: _selectedIndex,
          ),
          const SizedBox(height: 20),
          AppColors.listSeparator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    profile.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.tagsLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.message,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.text,
                    ),
                  ),
                  if (scripture != null) ...[
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _ScriptureBlock(
                        key: ValueKey(scripture.scripture),
                        scripture: scripture,
                        onAnother: _showAnotherScripture,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodHeader extends StatelessWidget {
  const _MoodHeader();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Select',
            style: TextStyle(
              fontSize: 28,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: AppColors.text,
              fontFamily: 'Georgia',
            ),
          ),
          const TextSpan(
            text: ' your mood',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.text,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _MoodFace extends StatelessWidget {
  final String emoji;
  final bool selected;

  const _MoodFace({
    required this.emoji,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 192,
        height: 192,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: AppColors.text,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 88),
        ),
      ),
    );
  }
}

class _ScriptureBlock extends StatelessWidget {
  final MoodScripture scripture;
  final VoidCallback onAnother;

  const _ScriptureBlock({
    super.key,
    required this.scripture,
    required this.onAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          scripture.scripture,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          scripture.scriptureText,
          style: const TextStyle(
            fontSize: 45,
            height: 1.45,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onAnother,
            child: const Text('Another scripture'),
          ),
        ),
      ],
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CarouselArrow({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed == null ? AppColors.border : AppColors.text,
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;

  const _PageDots({
    required this.count,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Container(
            width: i == index ? 8 : 7,
            height: i == index ? 8 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == index ? AppColors.text : Colors.transparent,
              border: Border.all(color: AppColors.text, width: 1),
            ),
          ),
        ],
      ],
    );
  }
}
