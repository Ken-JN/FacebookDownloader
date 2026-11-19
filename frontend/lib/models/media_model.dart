class MediaFormat {
  final String formatId;
  final String qualityLabel;
  final String ext;
  final String downloadUrl;
  final int? filesizeApprox;

  MediaFormat({
    required this.formatId,
    required this.qualityLabel,
    required this.ext,
    required this.downloadUrl,
    this.filesizeApprox,
  });

  factory MediaFormat.fromJson(Map<String, dynamic> json) {
    return MediaFormat(
      formatId: json['format_id']?.toString() ?? '',
      qualityLabel: json['quality_label']?.toString() ?? '',
      ext: json['ext']?.toString() ?? 'mp4',
      downloadUrl: json['download_url']?.toString() ?? '',
      filesizeApprox: (json['filesize_approx'] as num?)?.toInt(),
    );
  }
}

class MediaExtractionResult {
  final String title;
  final String? thumbnail;
  final int? duration;
  final String mediaType;
  final List<MediaFormat> formats;

  MediaExtractionResult({
    required this.title,
    this.thumbnail,
    this.duration,
    required this.mediaType,
    required this.formats,
  });

  factory MediaExtractionResult.fromJson(Map<String, dynamic> json) {
    return MediaExtractionResult(
      title: json['title']?.toString() ?? 'Facebook Media',
      thumbnail: json['thumbnail']?.toString(),
      duration: (json['duration'] as num?)?.round(),
      mediaType: json['media_type']?.toString() ?? 'video',
      formats: (json['formats'] as List? ?? [])
          .map((f) => MediaFormat.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DownloadedItem {
  final String id;
  final String title;
  final String filePath;
  final String ext;
  final DateTime date;

  DownloadedItem({
    required this.id,
    required this.title,
    required this.filePath,
    required this.ext,
    required this.date,
  });
}
