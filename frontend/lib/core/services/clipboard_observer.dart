import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fb_downloader/core/utils/fb_url_validator.dart';

typedef OnFacebookLinkDetected = void Function(String validUrl);

class ClipboardLifecycleManager with WidgetsBindingObserver {
  final OnFacebookLinkDetected onLinkDetected;
  String _lastProcessedUrl = '';
  bool isEnabled = true;

  ClipboardLifecycleManager({required this.onLinkDetected});

  void startListening() {
    WidgetsBinding.instance.addObserver(this);
    checkClipboard();
  }

  void stopListening() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isEnabled) {
      checkClipboard();
    }
  }

  Future<void> checkClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text;

      if (text != null && text.isNotEmpty) {
        final detectedUrl = FbUrlValidator.extractFirstUrl(text);

        if (detectedUrl != null && detectedUrl != _lastProcessedUrl) {
          _lastProcessedUrl = detectedUrl;
          onLinkDetected(detectedUrl);
        }
      }
    } catch (_) {
      // Menangani pembatasan Android 12+ saat app belum aktif penuh
    }
  }
}
