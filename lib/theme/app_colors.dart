import 'package:flutter/material.dart';

import '../models/entry.dart';

/// Pastel palette — "In The Sunshine"
class AppColors {
  AppColors._();

  static const creamyYellow = Color(0xFFF8F1E1);
  static const mintGreen = Color(0xFFEEF6F4);
  static const offWhite = Color(0xFFF9F5F0);
  static const peach = Color(0xFFFBE3D9);
  static const seafoam = Color(0xFFE1EFEE);
  static const dustyBlue = Color(0xFFC1D9E0);

  static const textDark = Colors.black;
  static const textMuted = Colors.black;
  static const text = Colors.black;

  static const border = Colors.white;
  static const borderWidth = 0.5;
  static const borderSide = BorderSide(color: border, width: borderWidth);
  static const outlineInputBorder = OutlineInputBorder(borderSide: borderSide);

  static Widget listSeparator() => const Divider(
        height: borderWidth,
        thickness: borderWidth,
        color: border,
      );

  static Color categoryBackground(EntryCategory category) {
    switch (category) {
      case EntryCategory.song:
        return creamyYellow;
      case EntryCategory.quote:
        return peach;
      case EntryCategory.scripture:
        return mintGreen;
    }
  }

  static Color categoryAccent(EntryCategory category) {
    switch (category) {
      case EntryCategory.song:
        return const Color(0xFFDCCAB5);
      case EntryCategory.quote:
        return const Color(0xFFEACABD);
      case EntryCategory.scripture:
        return dustyBlue;
    }
  }
}

extension EntryCategoryColors on EntryCategory {
  Color get backgroundColor => AppColors.categoryBackground(this);
  Color get accentColor => AppColors.categoryAccent(this);
}
