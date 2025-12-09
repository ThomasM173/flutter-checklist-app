/// Model representing a PDF document
class PdfItem {
  final String id;
  final String title;
  final DateTime createdAt;
  final String? localPath;
  final String? url;
  final int sizeBytes;

  PdfItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.localPath,
    this.url,
    this.sizeBytes = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'localPath': localPath,
    'url': url,
    'sizeBytes': sizeBytes,
  };

  factory PdfItem.fromJson(Map<String, dynamic> json) => PdfItem(
    id: json['id'],
    title: json['title'],
    createdAt: DateTime.parse(json['createdAt']),
    localPath: json['localPath'],
    url: json['url'],
    sizeBytes: json['sizeBytes'] ?? 0,
  );

  PdfItem copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    String? localPath,
    String? url,
    int? sizeBytes,
  }) {
    return PdfItem(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      localPath: localPath ?? this.localPath,
      url: url ?? this.url,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
