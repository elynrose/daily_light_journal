import 'package:flutter/material.dart';

import '../models/app_preferences.dart';
import '../models/entry.dart';
import '../theme/app_colors.dart';

class SideCategoryTabs extends StatelessWidget {
  final EntryCategory selectedCategory;
  final ValueChanged<EntryCategory> onCategoryChanged;
  final UserRole userRole;
  final VoidCallback? onSongsTap;

  const SideCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.userRole,
    this.onSongsTap,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabConfigs();

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(right: AppColors.borderSide),
      ),
      child: SizedBox(
        width: 44,
        child: Column(
          children: tabs.map((tab) {
            final isSelected =
                tab.isCategory && tab.category == selectedCategory;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (tab.isCategory) {
                    onCategoryChanged(tab.category!);
                  } else {
                    onSongsTap?.call();
                  }
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: tab.backgroundColor,
                    border: Border.all(
                      color: AppColors.border,
                      width: AppColors.borderWidth,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Center(
                      child: Text(
                        tab.label,
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<_SideTabConfig> _buildTabConfigs() {
    final configs = <_SideTabConfig>[];

    for (final category in EntryCategoryLabel.sideTabOrderFor(userRole)) {
      configs.add(
        _SideTabConfig.category(
          category: category,
          label: category.tabLabel,
          backgroundColor: category.backgroundColor,
        ),
      );

      if (EntryCategoryLabel.showsSongsLibraryTab(userRole) &&
          category == EntryCategory.scripture) {
        configs.add(
          _SideTabConfig.songsLibrary(
            backgroundColor: EntryCategory.song.backgroundColor,
          ),
        );
      }
    }

    return configs;
  }
}

class _SideTabConfig {
  final EntryCategory? category;
  final String label;
  final Color backgroundColor;

  const _SideTabConfig({
    required this.category,
    required this.label,
    required this.backgroundColor,
  });

  bool get isCategory => category != null;

  factory _SideTabConfig.category({
    required EntryCategory category,
    required String label,
    required Color backgroundColor,
  }) {
    return _SideTabConfig(
      category: category,
      label: label,
      backgroundColor: backgroundColor,
    );
  }

  factory _SideTabConfig.songsLibrary({required Color backgroundColor}) {
    return _SideTabConfig(
      category: null,
      label: 'SONGS',
      backgroundColor: backgroundColor,
    );
  }
}
