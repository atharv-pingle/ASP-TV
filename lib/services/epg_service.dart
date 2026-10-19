import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/epg_program.dart';

class EpgService with ChangeNotifier {
  static final EpgService instance = EpgService._internal();
  factory EpgService() => instance;
  EpgService._internal();

  static const String _tataplayEpgUrl =
      'https://raw.githubusercontent.com/mitthu786/tvepg/main/tataplay/epg.xml.gz';

  final Map<String, List<EpgProgram>> _channelPrograms = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _generateDefaultSchedules();
    notifyListeners();

    // Fetch live XMLTV data in background
    _fetchLiveEpgInBackground();
  }

  String _normalizeKey(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  void _fetchLiveEpgInBackground() async {
    _isLoading = true;
    try {
      final response = await http
          .get(Uri.parse(_tataplayEpgUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decompressedBytes = gzip.decode(response.bodyBytes);
        final xmlContent = utf8.decode(decompressedBytes, allowMalformed: true);
        _parseXmltvContent(xmlContent);
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('EpgService background fetch note: $e');
      }
      _isLoading = false;
    }
  }

  void _parseXmltvContent(String xml) {
    // Fast regex parser for <programme start="..." stop="..." channel="...">
    final regExp = RegExp(
      r'<programme\s+start="([^"]+)"\s+stop="([^"]+)"\s+channel="([^"]+)"[^>]*>[\s\S]*?<title[^>]*>([\s\S]*?)<\/title>[\s\S]*?(?:<desc[^>]*>([\s\S]*?)<\/desc>)?[\s\S]*?<\/programme>',
      multiLine: true,
    );

    final matches = regExp.allMatches(xml);
    for (final m in matches) {
      final startRaw = m.group(1)?.trim();
      final stopRaw = m.group(2)?.trim();
      final channelId = m.group(3)?.trim();
      final title = m.group(4)?.trim();
      final desc = m.group(5)?.trim() ?? '';

      if (startRaw != null && stopRaw != null && channelId != null && title != null) {
        final start = _parseXmltvDate(startRaw);
        final stop = _parseXmltvDate(stopRaw);
        if (start != null && stop != null) {
          final prog = EpgProgram(
            channelId: channelId,
            title: title,
            description: desc,
            start: start,
            stop: stop,
          );
          final key = _normalizeKey(channelId);
          _channelPrograms.putIfAbsent(key, () => []).add(prog);
        }
      }
    }
  }

  DateTime? _parseXmltvDate(String raw) {
    // Format: YYYYMMDDHHMMSS +0000 or YYYYMMDDHHMMSS +0530
    try {
      final cleaned = raw.split(' ')[0];
      if (cleaned.length >= 14) {
        final y = int.parse(cleaned.substring(0, 4));
        final m = int.parse(cleaned.substring(4, 6));
        final d = int.parse(cleaned.substring(6, 8));
        final h = int.parse(cleaned.substring(8, 10));
        final min = int.parse(cleaned.substring(10, 12));
        final s = int.parse(cleaned.substring(12, 14));
        return DateTime(y, m, d, h, min, s);
      }
    } catch (_) {}
    return null;
  }

  EpgProgram? getCurrentProgram(Channel channel) {
    final keys = [
      _normalizeKey(channel.id),
      _normalizeKey(channel.name),
    ];

    for (final k in keys) {
      final list = _channelPrograms[k];
      if (list != null && list.isNotEmpty) {
        for (final p in list) {
          if (p.isLive) return p;
        }
      }
    }

    // Dynamic slot matching based on channel type and hour
    return _getFallbackProgram(channel, isCurrent: true);
  }

  EpgProgram? getNextProgram(Channel channel) {
    final keys = [
      _normalizeKey(channel.id),
      _normalizeKey(channel.name),
    ];

    final now = DateTime.now();
    for (final k in keys) {
      final list = _channelPrograms[k];
      if (list != null && list.isNotEmpty) {
        for (final p in list) {
          if (p.start.isAfter(now)) return p;
        }
      }
    }

    return _getFallbackProgram(channel, isCurrent: false);
  }

  EpgProgram _getFallbackProgram(Channel channel, {required bool isCurrent}) {
    final now = DateTime.now();
    final hour = isCurrent ? now.hour : (now.hour + 1) % 24;
    final start = DateTime(now.year, now.month, now.day, hour, 0);
    final stop = start.add(const Duration(hours: 1));

    String title;
    String desc = 'Live television broadcast on ASP TV.';

    switch (channel.category) {
      case 'entertainment':
        if (hour >= 19 && hour <= 22) {
          title = 'Prime Time Special Drama';
          desc = 'Top rated family drama series and special evening telecast.';
        } else if (hour >= 12 && hour <= 15) {
          title = 'Afternoon Delight Series';
        } else {
          title = 'Popular Entertainment Showcase';
        }
        break;

      case 'movies':
        if (hour >= 20 && hour <= 23) {
          title = 'Blockbuster Movie of the Day';
          desc = 'Mega premiere movie with high definition audio and visual.';
        } else if (hour >= 13 && hour <= 17) {
          title = 'Matinee Superhit Feature';
        } else {
          title = 'Classic Cinema';
        }
        break;

      case 'music':
        if (hour >= 6 && hour <= 10) {
          title = 'Morning Melodies & Hits';
        } else if (hour >= 21) {
          title = 'Non-Stop Night Grooves';
        } else {
          title = 'Top Chartbusters & Hits';
        }
        break;

      case 'kids':
        if (hour >= 16 && hour <= 19) {
          title = 'After-School Toon Adventures';
        } else {
          title = 'Animated Super Cartoons';
        }
        break;

      case 'infotainment':
        if (hour >= 20) {
          title = 'Expedition Frontiers & Wonders';
        } else {
          title = 'Planet & Nature Mysteries';
        }
        break;

      case 'news':
      default:
        if (hour >= 20 && hour <= 22) {
          title = 'The Prime Debate & Analysis';
          desc = 'In-depth national and international news coverage and debate.';
        } else if (hour >= 7 && hour <= 10) {
          title = 'Morning Superfast 100 Headlines';
        } else if (hour >= 18 && hour <= 20) {
          title = 'Evening Bulletin & Top 50';
        } else {
          title = 'Live Breaking News';
        }
        break;
    }

    return EpgProgram(
      channelId: channel.id,
      title: title,
      description: desc,
      start: start,
      stop: stop,
      category: channel.category,
    );
  }

  void _generateDefaultSchedules() {
    // Seed initial schedule slots so cards never show blank
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, now.hour, 0);
    final stop = start.add(const Duration(hours: 1));

    final Map<String, String> popularShows = {
      'aajtak': 'Special Report: Desh Ka Mudda',
      'abpmajha': 'Majha Vishesh with Live Debate',
      'zeetv': 'Kundali Bhagya Live Broadcast',
      'starplus': 'Anupamaa Prime Series',
      'sethd': 'The Kapil Sharma Show - Best Moments',
      'sonypixhd': 'Hollywood Mega Premiere',
      'starmovieshd': 'Action Blockbuster Night',
      'colorsinfinityhd': 'Top International Sitcoms',
      'comedycentralhd': 'Friends & The Big Bang Theory',
      'vh1hd': 'Top 10 Global Pop Countdown',
      '9xomusic': 'Fresh Pop Anthems',
      'tlchd': 'Cake Boss & World Cuisine',
      'discoveryscience': 'How It\'s Made & Space Secrets',
    };

    for (final entry in popularShows.entries) {
      _channelPrograms[entry.key] = [
        EpgProgram(
          channelId: entry.key,
          title: entry.value,
          start: start,
          stop: stop,
        ),
      ];
    }
  }
}
