import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppTab { notes, songs, bible, mood, gallery, settings }

class AppBottomNav extends StatelessWidget {
  final AppTab selectedTab;
  final ValueChanged<AppTab> onTabSelected;

  const AppBottomNav({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.offWhite,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: AppColors.borderSide),
          ),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'HOME',
                    icon: Icons.home,
                    selected: selectedTab == AppTab.notes,
                    selectedColor: AppColors.offWhite,
                    onTap: () => onTabSelected(AppTab.notes),
                  ),
                ),
                Container(width: AppColors.borderWidth, color: AppColors.border),
                Expanded(
                  child: _TabButton(
                    label: 'SONGS',
                    icon: Icons.music_note,
                    selected: selectedTab == AppTab.songs,
                    selectedColor: AppColors.seafoam,
                    onTap: () => onTabSelected(AppTab.songs),
                  ),
                ),
                Container(width: AppColors.borderWidth, color: AppColors.border),
                Expanded(
                  child: _TabButton(
                    label: 'BIBLE',
                    icon: Icons.menu_book,
                    selected: selectedTab == AppTab.bible,
                    selectedColor: AppColors.mintGreen,
                    onTap: () => onTabSelected(AppTab.bible),
                  ),
                ),
                Container(width: AppColors.borderWidth, color: AppColors.border),
                Expanded(
                  child: _TabButton(
                    label: 'MOOD',
                    icon: Icons.sentiment_satisfied_alt,
                    selected: selectedTab == AppTab.mood,
                    selectedColor: const Color(0xFFF3E8F8),
                    onTap: () => onTabSelected(AppTab.mood),
                  ),
                ),
                Container(width: AppColors.borderWidth, color: AppColors.border),
                Expanded(
                  child: _TabButton(
                    label: 'PHOTOS',
                    icon: Icons.photo_library,
                    selected: selectedTab == AppTab.gallery,
                    selectedColor: AppColors.peach,
                    onTap: () => onTabSelected(AppTab.gallery),
                  ),
                ),
                Container(width: AppColors.borderWidth, color: AppColors.border),
                Expanded(
                  child: _TabButton(
                    label: 'SETTINGS',
                    icon: Icons.settings,
                    selected: selectedTab == AppTab.settings,
                    selectedColor: AppColors.dustyBlue,
                    onTap: () => onTabSelected(AppTab.settings),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const iconColor = AppColors.text;

    return Material(
      color: selected ? selectedColor : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 9,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
