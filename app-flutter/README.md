# NexPos Laundry - Flutter

Aplikasi kasir outlet laundry berbasis Flutter. Dibangun ulang dari Android (Kotlin) ke Flutter untuk kemudahan debugging dan pengembangan lintas platform.

## Konfigurasi Server

Server URL: `https://nexpos-production-3747.up.railway.app`

Konfigurasi ada di: `lib/utils/constants.dart`

## Fitur

- Login device dengan kode aktivasi outlet
- Buat transaksi laundry (pilih pelanggan, layanan, jumlah)
- Lihat daftar transaksi dengan pencarian
- Update status transaksi (Diterima → Dicuci → Disetrika → Selesai)
- Kelola data layanan (tambah, edit, hapus)
- Kelola data pelanggan (tambah, edit, hapus)
- Ringkasan laporan di beranda
- Heartbeat device otomatis setiap 30 detik
- Ganti password akun

## Struktur Proyek

```
lib/
├── main.dart              # Entry point
├── models/                # Data models
│   ├── auth_models.dart
│   ├── transaction_models.dart
│   └── notification_models.dart
├── services/              # API & session
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── transaction_service.dart
│   ├── device_service.dart
│   └── session_service.dart
├── providers/             # State management
│   └── app_provider.dart
├── screens/               # UI screens
│   ├── auth/
│   ├── home/
│   ├── transaction/
│   ├── master/
│   └── account/
└── utils/                 # Utilities
    ├── constants.dart
    ├── app_theme.dart
    └── format_utils.dart
```

## Cara Menjalankan

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk --release
```

## API Endpoints yang Digunakan

```
POST /api/auth/login-device
POST /api/auth/change-password
GET  /api/transactions
POST /api/transactions
PUT  /api/transactions/status
DELETE /api/transactions/:id
GET  /api/services
POST /api/services
PUT  /api/services/:id
DELETE /api/services/:id
GET  /api/customers
POST /api/customers
PUT  /api/customers/:id
DELETE /api/customers/:id
GET  /api/reports/summary
POST /api/devices/heartbeat
```
