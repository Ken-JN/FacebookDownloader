import 'package:dio/dio.dart';
import 'package:fb_downloader/models/media_model.dart';

/// Ekstraktor mandiri langsung di dalam HP tanpa memerlukan server backend
class DirectFbExtractor {
  static final Dio _dio = Dio(
    BaseOptions(
      followRedirects: true,
      maxRedirects: 5,
      connectTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
      },
    ),
  );

  static Future<MediaExtractionResult?> extract(String url) async {
    try {
      String targetUrl = url.trim();
      if (targetUrl.contains('facebook.com') && !targetUrl.contains('m.facebook.com')) {
        targetUrl = targetUrl
            .replaceFirst('www.facebook.com', 'm.facebook.com')
            .replaceFirst('web.facebook.com', 'm.facebook.com');
      }

      final response = await _dio.get(targetUrl);
      final html = response.data.toString();

      String? hdUrl = _findMatch(html, [
        r'"browser_native_hd_url":"([^"]+)"',
        r'"playable_url_quality_hd":"([^"]+)"',
        r'"hd_src":"([^"]+)"',
        r'"hd_src_no_ratelimit":"([^"]+)"',
      ]);

      String? sdUrl = _findMatch(html, [
        r'"browser_native_sd_url":"([^"]+)"',
        r'"playable_url":"([^"]+)"',
        r'"sd_src":"([^"]+)"',
        r'"sd_src_no_ratelimit":"([^"]+)"',
        r'<meta\s+property="og:video"\s+content="([^"]+)"',
        r'<meta\s+property="og:video:secure_url"\s+content="([^"]+)"',
      ]);

      String title = _findMatch(html, [
        r'<meta\s+property="og:title"\s+content="([^"]+)"',
        r'<title>([^<]+)<\/title>',
      ]) ?? 'Facebook Video';

      String? thumbnail = _findMatch(html, [
        r'<meta\s+property="og:image"\s+content="([^"]+)"',
        r'"thumbnailImage":{"uri":"([^"]+)"}',
      ]);

      List<MediaFormat> formats = [];
      if (hdUrl != null) {
        formats.add(MediaFormat(
          formatId: 'hd',
          qualityLabel: 'HD (Kualitas Tinggi)',
          ext: 'mp4',
          downloadUrl: _cleanUrl(hdUrl),
        ));
      }

      if (sdUrl != null && sdUrl != hdUrl) {
        formats.add(MediaFormat(
          formatId: 'sd',
          qualityLabel: 'SD (Kualitas Standar)',
          ext: 'mp4',
          downloadUrl: _cleanUrl(sdUrl),
        ));
      }

      if (formats.isNotEmpty) {
        return MediaExtractionResult(
          title: title,
          thumbnail: thumbnail != null ? _cleanUrl(thumbnail) : null,
          duration: null,
          mediaType: 'video',
          formats: formats,
        );
      }
    } catch (_) {
      // Direct extraction gagal, akan dilanjutkan dengan fallback backend
    }
    return null;
  }

  static String? _findMatch(String html, List<String> patterns) {
    for (final pattern in patterns) {
      final reg = RegExp(pattern, caseSensitive: false);
      final match = reg.firstMatch(html);
      if (match != null && match.group(1) != null) {
        return match.group(1);
      }
    }
    return null;
  }

  static String _cleanUrl(String raw) {
    return raw
        .replaceAll(r'\/', '/')
        .replaceAll(r'\u0025', '%')
        .replaceAll('&amp;', '&');
  }
}
