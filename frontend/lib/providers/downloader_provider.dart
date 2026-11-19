import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:fb_downloader/models/media_model.dart';
import 'package:fb_downloader/core/services/download_service.dart';
import 'package:fb_downloader/core/services/direct_fb_extractor.dart';

// Ganti IP jika laptop berganti jaringan Wi-Fi
const String kDefaultBackendUrl = 'http://192.168.100.5:8000/api/extract';

enum FetchStatus { initial, loading, success, error }

class DownloaderState {
  final FetchStatus status;
  final MediaExtractionResult? mediaData;
  final String? errorMessage;
  final double downloadProgress;
  final String downloadSpeed;
  final bool isDownloading;

  DownloaderState({
    this.status = FetchStatus.initial,
    this.mediaData,
    this.errorMessage,
    this.downloadProgress = 0.0,
    this.downloadSpeed = '',
    this.isDownloading = false,
  });

  DownloaderState copyWith({
    FetchStatus? status,
    MediaExtractionResult? mediaData,
    String? errorMessage,
    double? downloadProgress,
    String? downloadSpeed,
    bool? isDownloading,
  }) {
    return DownloaderState(
      status: status ?? this.status,
      mediaData: mediaData ?? this.mediaData,
      errorMessage: errorMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }
}

class DownloaderNotifier extends Notifier<DownloaderState> {
  final Dio _dio = Dio();
  final DownloadService _downloadService = DownloadService();

  @override
  DownloaderState build() => DownloaderState();

  Future<void> fetchMetadata(String url) async {
    state = state.copyWith(status: FetchStatus.loading, errorMessage: null);

    // 1. Coba ekstraksi mandiri langsung di dalam HP terlebih dahulu (tanpa laptop)
    final directResult = await DirectFbExtractor.extract(url);
    if (directResult != null && directResult.formats.isNotEmpty) {
      state = state.copyWith(
        status: FetchStatus.success,
        mediaData: directResult,
      );
      return;
    }

    // 2. Jika ekstraksi langsung di HP belum berhasil, coba via Backend laptop (yt-dlp)
    try {
      final response = await _dio.post(
        kDefaultBackendUrl,
        data: {'url': url},
        options: Options(connectTimeout: const Duration(seconds: 15)),
      );

      final result = MediaExtractionResult.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(
        status: FetchStatus.success,
        mediaData: result,
      );
    } on DioException catch (e) {
      String msg;
      if (e.response?.data != null && e.response?.data is Map && e.response?.data['detail'] != null) {
        msg = e.response!.data['detail'].toString();
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        msg = 'Koneksi timeout. Pastikan backend di laptop aktif atau gunakan direct mode.';
      } else if (e.type == DioExceptionType.connectionError) {
        msg = 'Gagal mengekstrak video secara langsung & tidak dapat terhubung ke laptop ($kDefaultBackendUrl).';
      } else {
        msg = e.message ?? 'Gagal mengambil data Facebook.';
      }

      state = state.copyWith(
        status: FetchStatus.error,
        errorMessage: msg,
      );
    } catch (e) {
      state = state.copyWith(
        status: FetchStatus.error,
        errorMessage: 'Terjadi kesalahan: $e',
      );
    }
  }

  Future<void> startDownload(MediaFormat format) async {
    if (state.mediaData == null) return;

    state = state.copyWith(
      isDownloading: true,
      downloadProgress: 0.0,
      downloadSpeed: 'Menghubungkan...',
    );

    try {
      final isVideo = format.ext == 'mp4';
      final fileName = 'FB_${DateTime.now().millisecondsSinceEpoch}.${format.ext}';

      final savedPath = await _downloadService.downloadAndSaveToGallery(
        directUrl: format.downloadUrl,
        fileName: fileName,
        isVideo: isVideo,
        onProgress: (progress, speed, downloaded, total) {
          state = state.copyWith(
            downloadProgress: progress,
            downloadSpeed: '$speed ($downloaded / $total)',
          );
        },
      );

      // Simpan ke riwayat unduhan
      ref.read(historyProvider.notifier).addItem(
            DownloadedItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: state.mediaData!.title,
              filePath: savedPath,
              ext: format.ext,
              date: DateTime.now(),
            ),
          );

      state = state.copyWith(isDownloading: false, downloadProgress: 1.0);
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        errorMessage: 'Gagal mengunduh: $e',
      );
    }
  }

  void reset() {
    state = DownloaderState();
  }
}

final downloaderProvider =
    NotifierProvider<DownloaderNotifier, DownloaderState>(DownloaderNotifier.new);

// Notifier untuk Riwayat Unduhan
class HistoryNotifier extends Notifier<List<DownloadedItem>> {
  @override
  List<DownloadedItem> build() => [];

  void addItem(DownloadedItem item) {
    state = [item, ...state];
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearHistory() {
    state = [];
  }
}

final historyProvider =
    NotifierProvider<HistoryNotifier, List<DownloadedItem>>(HistoryNotifier.new);

// Provider untuk Pengaturan
class SettingsState {
  final bool autoDetectClipboard;
  SettingsState({this.autoDetectClipboard = true});

  SettingsState copyWith({bool? autoDetectClipboard}) {
    return SettingsState(
      autoDetectClipboard: autoDetectClipboard ?? this.autoDetectClipboard,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => SettingsState();

  void toggleAutoDetect(bool val) {
    state = state.copyWith(autoDetectClipboard: val);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
