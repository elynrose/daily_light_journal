import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../theme/app_colors.dart';

class SideCategoryTabs extends StatelessWidget {
  final EntryCategory selectedCategory;
  final ValueChanged<EntryCategory> onCategoryChanged;

  const SideCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(right: AppColors.borderSide),
      ),
      child: SizedBox(
        width: 44,
        child: Column(
          children: EntryCategory.values.map((category) {
            final isSelected = category == selectedCategory;
            final tabColor = category.backgroundColor;

            return Expanded(
              child: GestureDetector(
                onTap: () => onCategoryChanged(category),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: tabColor,
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
                        category.tabLabel,
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
}
