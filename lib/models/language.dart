class LanguageCategory {
  final String code;
  final String name;
  final String icon;
  final int count;
  final List<GenreCategory> genres;

  const LanguageCategory({
    required this.code,
    required this.name,
    this.icon = '📺',
    this.count = 0,
    this.genres = const [],
  });

  static const List<LanguageCategory> defaultCategories = [
    LanguageCategory(code: 'fav', name: 'Favorites & Recents', icon: '⭐'),
    LanguageCategory(code: 'all', name: 'All Channels', icon: '⚡'),
    LanguageCategory(code: 'mar', name: 'Marathi', icon: '🚩'),
    LanguageCategory(code: 'hin', name: 'Hindi', icon: '🇮🇳'),
    LanguageCategory(code: 'eng', name: 'English', icon: '🌐'),
    LanguageCategory(code: 'kids', name: 'Kids', icon: '🧸'),
    LanguageCategory(code: 'infotainment', name: 'Infotainment', icon: '🌍'),
  ];
}

class GenreCategory {
  final String code;
  final String name;
  final String icon;
  final int count;

  const GenreCategory({
    required this.code,
    required this.name,
    required this.icon,
    this.count = 0,
  });

  static const List<GenreCategory> defaultGenres = [
    GenreCategory(code: 'news', name: 'News', icon: '📰'),
    GenreCategory(code: 'entertainment', name: 'Entertainment', icon: '🎭'),
    GenreCategory(code: 'movies', name: 'Movies', icon: '🎬'),
    GenreCategory(code: 'music', name: 'Music', icon: '🎵'),
  ];
}
