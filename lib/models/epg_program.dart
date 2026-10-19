class EpgProgram {
  final String channelId;
  final String title;
  final String description;
  final DateTime start;
  final DateTime stop;
  final String category;

  EpgProgram({
    required this.channelId,
    required this.title,
    this.description = '',
    required this.start,
    required this.stop,
    this.category = '',
  });

  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(stop);
  }

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(stop)) return 1.0;
    final total = stop.difference(start).inSeconds;
    if (total <= 0) return 0.0;
    final current = now.difference(start).inSeconds;
    return (current / total).clamp(0.0, 1.0);
  }

  String get timeFormatted {
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final stopStr =
        '${stop.hour.toString().padLeft(2, '0')}:${stop.minute.toString().padLeft(2, '0')}';
    return '$startStr - $stopStr';
  }

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'title': title,
      'description': description,
      'start': start.toIso8601String(),
      'stop': stop.toIso8601String(),
      'category': category,
    };
  }

  factory EpgProgram.fromJson(Map<String, dynamic> json) {
    return EpgProgram(
      channelId: json['channelId'] ?? '',
      title: json['title'] ?? 'Live Broadcast',
      description: json['description'] ?? '',
      start: DateTime.tryParse(json['start'] ?? '') ?? DateTime.now(),
      stop: DateTime.tryParse(json['stop'] ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      category: json['category'] ?? '',
    );
  }
}
