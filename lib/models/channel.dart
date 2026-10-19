class Channel {
  final String id;
  final String name;
  final String languageCode;
  final String languageName;
  final String network;
  final String logo;
  final String category;
  final List<String> streams;
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
    this.isFavorite = false,
  });

  String get primaryStream => streams.isNotEmpty ? streams.first.trim() : '';

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

    return Channel(
      id: json['id']?.toString().trim() ?? json['name']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? 'Unknown Channel',
      languageCode: json['language_code']?.toString().trim() ?? 'hin',
      languageName: json['language_name']?.toString().trim() ?? 'Hindi',
      network: json['network']?.toString().trim() ?? '',
      logo: json['logo']?.toString().trim() ?? '',
      category: json['category']?.toString().trim().toLowerCase() ?? 'news',
      streams: streamList,
      isFavorite: json['isFavorite'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language_code': languageCode,
      'language_name': languageName,
      'network': network,
      'logo': logo,
      'category': category,
      'streams': streams,
      'isFavorite': isFavorite,
    };
  }
}
