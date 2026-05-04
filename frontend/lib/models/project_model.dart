class Project {
  final String id;
  final String owner;
  final String repo;
  final String fullName;
  final String description;
  final int stars;
  final int forks;
  final String primaryLanguage;
  final Map<String, dynamic> languages;
  final List<String> topics;
  final List<String> techStack;
  final String aiSummary;
  final String mermaidDiagram;
  final String aiStatus; // "pending" | "done" | "failed"
  final String liveUrl;
  final String videoUrl;
  final String heartbeatStatus; // "live" | "down" | "unknown"
  final DateTime? lastHeartbeatCheck;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.owner,
    required this.repo,
    required this.fullName,
    required this.description,
    required this.stars,
    required this.forks,
    required this.primaryLanguage,
    required this.languages,
    required this.topics,
    required this.techStack,
    required this.aiSummary,
    required this.mermaidDiagram,
    required this.aiStatus,
    required this.liveUrl,
    required this.videoUrl,
    required this.heartbeatStatus,
    this.lastHeartbeatCheck,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['_id']?.toString() ?? '',
      owner: json['owner'] ?? '',
      repo: json['repo'] ?? '',
      fullName: json['fullName'] ?? '',
      description: json['description'] ?? '',
      stars: (json['stars'] ?? 0) as int,
      forks: (json['forks'] ?? 0) as int,
      primaryLanguage: json['primaryLanguage'] ?? 'Unknown',
      languages: Map<String, dynamic>.from(json['languages'] ?? {}),
      topics: List<String>.from(json['topics'] ?? []),
      techStack: List<String>.from(json['techStack'] ?? []),
      aiSummary: json['aiSummary'] ?? '',
      mermaidDiagram: json['mermaidDiagram'] ?? '',
      aiStatus: json['aiStatus'] ?? 'pending',
      liveUrl: json['liveUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      heartbeatStatus: json['heartbeatStatus'] ?? 'unknown',
      lastHeartbeatCheck: json['lastHeartbeatCheck'] != null
          ? DateTime.tryParse(json['lastHeartbeatCheck'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'owner': owner,
        'repo': repo,
        'fullName': fullName,
        'description': description,
        'stars': stars,
        'forks': forks,
        'primaryLanguage': primaryLanguage,
        'languages': languages,
        'topics': topics,
        'techStack': techStack,
        'aiSummary': aiSummary,
        'mermaidDiagram': mermaidDiagram,
        'aiStatus': aiStatus,
        'liveUrl': liveUrl,
        'videoUrl': videoUrl,
        'heartbeatStatus': heartbeatStatus,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Convenience: total language bytes for percentage calculations
  int get totalLanguageBytes =>
      languages.values.fold(0, (sum, v) => sum + (v as int? ?? 0));

  /// Language percentage map for display
  Map<String, double> get languagePercentages {
    final total = totalLanguageBytes;
    if (total == 0) return {};
    return Map.fromEntries(
      languages.entries.map(
        (e) => MapEntry(e.key, ((e.value as int) / total) * 100),
      ),
    );
  }

  Project copyWith({
    String? heartbeatStatus,
    String? aiStatus,
    String? aiSummary,
    String? mermaidDiagram,
    DateTime? lastHeartbeatCheck,
  }) {
    return Project(
      id: id,
      owner: owner,
      repo: repo,
      fullName: fullName,
      description: description,
      stars: stars,
      forks: forks,
      primaryLanguage: primaryLanguage,
      languages: languages,
      topics: topics,
      techStack: techStack,
      aiSummary: aiSummary ?? this.aiSummary,
      mermaidDiagram: mermaidDiagram ?? this.mermaidDiagram,
      aiStatus: aiStatus ?? this.aiStatus,
      liveUrl: liveUrl,
      videoUrl: videoUrl,
      heartbeatStatus: heartbeatStatus ?? this.heartbeatStatus,
      lastHeartbeatCheck: lastHeartbeatCheck ?? this.lastHeartbeatCheck,
      createdAt: createdAt,
    );
  }
}
