import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

typedef DownloadProgressCallback = void Function(
    double progress, String speed, String downloadedSize, String totalSize);

class DownloadService {
  final Dio _dio = Dio();

  Future<String> downloadAndSaveToGallery({
    required String directUrl,
    required String fileName,
    required bool isVideo,
    required DownloadProgressCallback onProgress,
  }) async {
    // 1. Cek & Minta Izin Galeri
    final hasAccess = await Gal.hasPermission(toAlbum: true);
    if (!hasAccess) {
      final granted = await Gal.requestPermission(toAlbum: true);
      if (!granted) {
        throw Exception('Izin akses galeri ditolak oleh pengguna.');
      }
    }

    // 2. Siapkan File Penampung Sementara di Cache Directory
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/$fileName';
    final file = File(tempPath);
    if (await file.exists()) await file.delete();

    int lastTime = DateTime.now().millisecondsSinceEpoch;
    int lastBytes = 0;

    // 3. Download dengan Progress Tracker Real-time
    await _dio.download(
      directUrl,
      tempPath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          final timeDiff = (currentTime - lastTime) / 1000.0;

          String speed = '0 KB/s';
          if (timeDiff >= 0.5) {
            final byteDiff = received - lastBytes;
            final speedBytesPerSec = byteDiff / timeDiff;
            speed = _formatSpeed(speedBytesPerSec);
            lastTime = currentTime;
            lastBytes = received;
          }

          final progress = received / total;
          final downloadedStr = _formatSize(received);
          final totalStr = _formatSize(total);

          onProgress(progress, speed, downloadedStr, totalStr);
        }
      },
    );

    // 4. Simpan ke Galeri Pengguna (Album: FBDownloader)
    if (isVideo) {
      await Gal.putVideo(tempPath, album: 'FBDownloader');
    } else {
      await Gal.putImage(tempPath, album: 'FBDownloader');
    }

    return tempPath;
  }

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec >= 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}
