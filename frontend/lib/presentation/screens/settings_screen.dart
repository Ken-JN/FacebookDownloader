import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fb_downloader/providers/downloader_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.content_paste_go, color: Colors.blueAccent),
              title: const Text('Auto-Detect Clipboard', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Otomatis mendeteksi saat link Facebook disalin ke clipboard'),
              value: settings.autoDetectClipboard,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).toggleAutoDetect(val);
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_special_outlined, color: Colors.orange),
              title: const Text('Lokasi Penyimpanan', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Galeri Perangkat > Album "FBDownloader"'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: const Text('Versi Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('1.0.0 (Production Build)'),
            ),
          ),
        ],
      ),
    );
  }
}
