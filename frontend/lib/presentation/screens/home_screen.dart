import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fb_downloader/core/services/clipboard_observer.dart';
import 'package:fb_downloader/core/utils/fb_url_validator.dart';
import 'package:fb_downloader/models/media_model.dart';
import 'package:fb_downloader/providers/downloader_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  late ClipboardLifecycleManager _clipboardManager;

  @override
  void initState() {
    super.initState();
    _clipboardManager = ClipboardLifecycleManager(
      onLinkDetected: (detectedUrl) {
        final settings = ref.read(settingsProvider);
        if (settings.autoDetectClipboard) {
          _showClipboardConfirmationDialog(detectedUrl);
        }
      },
    );
    _clipboardManager.startListening();
  }

  @override
  void dispose() {
    _clipboardManager.stopListening();
    _urlController.dispose();
    super.dispose();
  }

  void _showClipboardConfirmationDialog(String url) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.content_paste_rounded, color: Colors.blue, size: 36),
              const SizedBox(height: 10),
              const Text(
                'Link Facebook Terdeteksi!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Mau langsung download videonya?',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Nanti Dulu', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _urlController.text = url;
                        ref.read(downloaderProvider.notifier).fetchMetadata(url);
                      },
                      icon: const Icon(Icons.download_rounded, size: 22),
                      label: const Text('Ya, Download!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloaderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Download Video Facebook',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Panduan Singkat
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Cara Pakai:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 6),
                  Text('1. Buka Facebook → cari video', style: TextStyle(fontSize: 14)),
                  Text('2. Tekan Bagikan → Salin Tautan', style: TextStyle(fontSize: 14)),
                  Text('3. Kembali ke sini → tekan Cari Video', style: TextStyle(fontSize: 14)),
                  Text('4. Pilih kualitas → tekan Unduh', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Input Link
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.grey, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Tempel link video Facebook di sini...',
                          hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_urlController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _urlController.clear(),
                        child: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Tombol Utama Cari Video
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: state.status == FetchStatus.loading
                    ? null
                    : () {
                        final url = _urlController.text.trim();
                        if (FbUrlValidator.isValid(url)) {
                          ref.read(downloaderProvider.notifier).fetchMetadata(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link Facebook tidak valid. Coba salin ulang dari aplikasi Facebook.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.search_rounded, size: 24),
                label: const Text('Cari Video',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Loading
            if (state.status == FetchStatus.loading)
              const Column(
                children: [
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text('Sedang mengambil info video...',
                      style: TextStyle(fontSize: 16, color: Colors.black54)),
                  SizedBox(height: 20),
                ],
              ),

            // Error
            if (state.status == FetchStatus.error)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gagal Mengambil Video',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
                          const SizedBox(height: 4),
                          Text(
                            state.errorMessage ?? 'Terjadi kesalahan. Pastikan videonya bukan video pribadi.',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Progress Unduh
            if (state.isDownloading)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sedang mengunduh...',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '${(state.downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: state.downloadProgress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(state.downloadSpeed,
                        style: const TextStyle(fontSize: 13, color: Colors.black45)),
                  ],
                ),
              ),

            // Preview & Pilihan Kualitas
            if (state.status == FetchStatus.success && state.mediaData != null)
              _buildPreviewCard(state.mediaData!),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(MediaExtractionResult media) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        if (media.thumbnail != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: media.thumbnail!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),

        const SizedBox(height: 14),

        // Judul
        Text(
          media.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 16),
        const Text('Pilih Kualitas Video:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // Tombol Kualitas
        ...media.formats.map((fmt) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton.icon(
                onPressed: state.isDownloading
                    ? null
                    : () => ref.read(downloaderProvider.notifier).startDownload(fmt),
                icon: Icon(
                  fmt.ext == 'mp3' ? Icons.audiotrack : Icons.hd_rounded,
                  size: 24,
                ),
                label: Text(fmt.qualityLabel,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: fmt.qualityLabel.contains('HD') ? Colors.green : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )),
      ],
    );
  }

  DownloaderState get state => ref.read(downloaderProvider);
}
