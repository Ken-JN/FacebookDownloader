import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fb_downloader/providers/downloader_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Unduhan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Bersihkan Riwayat',
              onPressed: () {
                ref.read(historyProvider.notifier).clearHistory();
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada media yang diunduh',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.ext == 'mp3' ? Colors.purple.shade50 : Colors.blue.shade50,
                      child: Icon(
                        item.ext == 'mp3' ? Icons.audiotrack : Icons.movie_outlined,
                        color: item.ext == 'mp3' ? Colors.purple : Colors.blue,
                      ),
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Tersimpan di Galeri / FBDownloader • ${item.ext.toUpperCase()}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill, color: Colors.green),
                          tooltip: 'Buka File',
                          onPressed: () {
                            OpenFilex.open(item.filePath);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Hapus dari riwayat',
                          onPressed: () {
                            ref.read(historyProvider.notifier).removeItem(item.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
