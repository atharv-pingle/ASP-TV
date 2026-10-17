import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../models/language.dart';

class ChannelService with ChangeNotifier {
  static const String _favoritesKey = 'tv_favorite_channel_ids';
  static const String _remoteCatalogUrl =
      'https://raw.githubusercontent.com/iptv-org/iptv/master/streams/in.m3u';

  List<Channel> _allChannels = [];
  Set<String> _favoriteIds = {};
  String _selectedLanguage = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  List<Channel> get allChannels => _allChannels;
  String get selectedLanguage => _selectedLanguage;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load favorites from storage
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList(_favoritesKey) ?? [];
      _favoriteIds = favList.toSet();

      // 2. Load bundled channels cache
      final jsonString =
          await rootBundle.loadString('assets/data/news_channels.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _allChannels = jsonList.map((e) {
        final ch = Channel.fromJson(e);
        ch.isFavorite = _favoriteIds.contains(ch.id);
        return ch;
      }).toList();

      _isLoading = false;
      notifyListeners();

      // 3. Trigger background update check
      _fetchRemoteUpdatesInBackground();
    } catch (e) {
      if (kDebugMode) print('Error initializing channels: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _fetchRemoteUpdatesInBackground() async {
    try {
      final res = await http
          .get(Uri.parse(_remoteCatalogUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        // Parse updated stream URLs for matching channels
        final lines = res.body.split('\n');
        final Map<String, List<String>> freshStreams = {};
        String? curTvgId;

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('#EXTINF:')) {
            final match = RegExp(r'tvg-id="([^"]+)"').firstMatch(trimmed);
            if (match != null) {
              final rawId = match.group(1)!;
              curTvgId = rawId.split('@')[0];
            }
          } else if (trimmed.isNotEmpty &&
              !trimmed.startsWith('#') &&
              curTvgId != null) {
            freshStreams.putIfAbsent(curTvgId, () => []);
            if (!freshStreams[curTvgId]!.contains(trimmed)) {
              freshStreams[curTvgId]!.add(trimmed);
            }
            curTvgId = null;
          }
        }

        // Apply any fresh streams to active channels
        bool hasUpdates = false;
        for (var ch in _allChannels) {
          if (freshStreams.containsKey(ch.id)) {
            final fresh = freshStreams[ch.id]!;
            if (fresh.isNotEmpty && fresh.first != ch.primaryStream) {
              ch.streams.clear();
              ch.streams.addAll(fresh);
              hasUpdates = true;
            }
          }
        }

        if (hasUpdates) {
          notifyListeners();
        }
      }
    } catch (_) {
      // Remote fetch failed, existing bundled channels remain active
    }
  }

  void selectLanguage(String code) {
    _selectedLanguage = code;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> toggleFavorite(Channel channel) async {
    channel.isFavorite = !channel.isFavorite;
    if (channel.isFavorite) {
      _favoriteIds.add(channel.id);
    } else {
      _favoriteIds.remove(channel.id);
    }

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
    } catch (e) {
      if (kDebugMode) print('Error saving favorites: $e');
    }
  }

  List<Channel> get filteredChannels {
    List<Channel> list = _allChannels;

    // Filter by language
    if (_selectedLanguage == 'fav') {
      list = list.where((c) => c.isFavorite).toList();
    } else if (_selectedLanguage != 'all') {
      list = list.where((c) => c.languageCode == _selectedLanguage).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              c.languageName.toLowerCase().contains(query) ||
              c.network.toLowerCase().contains(query))
          .toList();
    }

    return list;
  }

  List<LanguageCategory> get categoriesWithCounts {
    final Map<String, int> counts = {};
    for (var ch in _allChannels) {
      counts[ch.languageCode] = (counts[ch.languageCode] ?? 0) + 1;
    }

    return LanguageCategory.defaultCategories.map((cat) {
      int count = 0;
      if (cat.code == 'all') {
        count = _allChannels.length;
      } else if (cat.code == 'fav') {
        count = _favoriteIds.length;
      } else {
        count = counts[cat.code] ?? 0;
      }
      return LanguageCategory(
        code: cat.code,
        name: cat.name,
        icon: cat.icon,
        count: count,
      );
    }).toList();
  }
}
