class LanguageCategory {
  final String code;
  final String name;
  final String icon;
  final int count;

  const LanguageCategory({
    required this.code,
    required this.name,
    this.icon = '📺',
    this.count = 0,
  });

  static const List<LanguageCategory> defaultCategories = [
    LanguageCategory(code: 'all', name: 'All News', icon: '⚡'),
    LanguageCategory(code: 'fav', name: 'Favorites', icon: '⭐'),
    LanguageCategory(code: 'mar', name: 'Marathi', icon: '🚩'),
    LanguageCategory(code: 'hin', name: 'Hindi', icon: '🇮🇳'),
    LanguageCategory(code: 'eng', name: 'English', icon: '🌐'),
  ];
}
