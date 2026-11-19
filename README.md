# Facebook Media Downloader (Video, Reels & Images)

Aplikasi mobile pengunduh media Facebook dengan fitur **Auto-Detect Clipboard**, **Download Manager Scoped Storage**, dan **Backend Extractor FastAPI**.

## Struktur Proyek

```
D:/CobaCoba/FacebookDownloader/
├── backend/                  # Extractor REST API (FastAPI + yt-dlp)
│   ├── main.py
│   └── requirements.txt
└── frontend/                 # Mobile App (Flutter + Riverpod)
    ├── android/
    ├── ios/
    └── lib/
        ├── core/
        │   ├── services/     # ClipboardObserver & DownloadService (Gal)
        │   └── utils/        # Regex Validator
        ├── models/           # MediaModel & FormatOption
        ├── providers/        # Riverpod State Notifiers
        └── presentation/     # HomeScreen, DownloadsScreen, SettingsScreen, MainNavScreen
```

## Panduan Menjalankan

### 1. Jalankan Backend (FastAPI)
Buka terminal di folder backend:
```bash
cd D:/CobaCoba/FacebookDownloader/backend
pip install -r requirements.txt
python main.py
```
Backend berjalan di `http://localhost:8000`. Dokumentasi Swagger: `http://localhost:8000/docs`.

### 2. Jalankan Frontend (Flutter)
Buka terminal di folder frontend:
```bash
cd D:/CobaCoba/FacebookDownloader/frontend
flutter pub get
flutter run
```
*Catatan Emulator Android:* Backend diakses via `http://10.0.2.2:8000/api/extract` (sudah disetel secara default).
