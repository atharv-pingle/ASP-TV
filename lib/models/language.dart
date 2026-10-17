import 'package:flutter/material.dart';

class LanguageCategory {
  final String code;
  final String name;
  final String icon;
  final IconData iconData;
  final int count;

  const LanguageCategory({
    required this.code,
    required this.name,
    this.icon = '📺',
    this.iconData = Icons.tv_rounded,
    this.count = 0,
  });

  static const List<LanguageCategory> defaultCategories = [
    LanguageCategory(code: 'all', name: 'All News', icon: '⚡', iconData: Icons.live_tv_rounded),
    LanguageCategory(code: 'fav', name: 'Favorites', icon: '⭐', iconData: Icons.star_rounded),
    LanguageCategory(code: 'mar', name: 'Marathi', icon: '🚩', iconData: Icons.feed_rounded),
    LanguageCategory(code: 'hin', name: 'Hindi', icon: '🇮🇳', iconData: Icons.newspaper_rounded),
    LanguageCategory(code: 'eng', name: 'English', icon: '🌐', iconData: Icons.language_rounded),
  ];
}
