class Channel {
  final String id;
  final String name;
  final String languageCode;
  final String languageName;
  final String network;
  final String logo;
  final String category;
  final List<String> streams;
  final List<String> audioLanguages;
  final String? customProvider;
  bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.languageName,
    this.network = '',
    required this.logo,
    this.category = 'news',
    required this.streams,
    List<String>? audioLanguages,
    this.isFavorite = false,
    String? provider,
  }) : customProvider = provider,
       audioLanguages = audioLanguages ?? _defaultAudioLanguages(category, languageName);

  static List<String> _defaultAudioLanguages(String cat, String lang) {
    if (cat == 'infotainment' || cat == 'kids') {
      return ['Hindi', 'English', 'Original'];
    }
    if (cat == 'movies' || cat == 'entertainment') {
      return [lang, 'Hindi', 'Original'];
    }
    return [lang, 'Original'];
  }

  String get primaryStream => streams.isNotEmpty ? streams.first.trim() : '';

  String get providerTag {
    if (customProvider != null && customProvider!.trim().isNotEmpty) {
      return customProvider!.trim();
    }
    final stream = primaryStream.toLowerCase();
    final net = network.toLowerCase();
    final chId = id.toLowerCase();

    if (stream.contains('samsung') || net.contains('samsung') || chId.contains('samsung')) {
      return 'Samsung TV+';
    }
    if (stream.contains('pluto') || net.contains('pluto') || chId.contains('pluto')) {
      return 'Pluto TV';
    }
    if (stream.contains('plex') || net.contains('plex') || chId.contains('plex')) {
      return 'Plex';
    }
    if (stream.contains('wurl') || stream.contains('amagi') || stream.contains('dai.google.com') || stream.contains('rakuten')) {
      return 'FAST TV';
    }
    if (net.contains('tataplay') || net.contains('tata play') || stream.contains('tataplay')) {
      return 'Tata Play';
    }
    if (network.isNotEmpty && network.length <= 16 && !network.contains('http')) {
      return network;
    }
    return 'Live TV';
  }

  factory Channel.fromJson(Map<String, dynamic> json) {
    List<String> streamList = [];
    if (json['streams'] is List) {
      streamList = (json['streams'] as List)
          .map((e) => e.toString().trim())
          .where((s) => s.startsWith('http://') || s.startsWith('https://'))
          .toList();
    } else if (json['streamUrl'] != null) {
      final s = json['streamUrl'].toString().trim();
      if (s.startsWith('http://') || s.startsWith('https://')) {
        streamList = [s];
      }
    }

    final cat = json['category']?.toString().trim().toLowerCase() ?? 'news';
    final langName = json['language_name']?.toString().trim() ?? 'Hindi';

    List<String>? customAudios;
    if (json['audio_languages'] is List) {
      customAudios = (json['audio_languages'] as List).map((e) => e.toString()).toList();
    }

    final prov = json['provider']?.toString().trim();

    return Channel(
      id: json['id']?.toString().trim() ?? json['name']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? 'Unknown Channel',
      languageCode: json['language_code']?.toString().trim() ?? 'hin',
      languageName: langName,
      network: json['network']?.toString().trim() ?? '',
      logo: json['logo']?.toString().trim() ?? '',
      category: cat,
      streams: streamList,
      audioLanguages: customAudios,
      isFavorite: json['isFavorite'] == true,
      provider: prov,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language_code': languageCode,
      'language_name': languageName,
      'network': network,
      'provider': providerTag,
      'logo': logo,
      'category': category,
      'streams': streams,
      'audio_languages': audioLanguages,
      'isFavorite': isFavorite,
    };
  }
}
