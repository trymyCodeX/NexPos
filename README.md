# NexPos — Aplikasi POS Laundry

  NexPos adalah aplikasi kasir untuk usaha laundry. Terdiri dari dua aplikasi mobile yang saling terhubung ke satu server pusat.

  ---

  ## Dua Aplikasi

  ### NexPos Laundry (untuk Kasir)
  Digunakan oleh karyawan di meja kasir outlet laundry.

  - Login menggunakan kode aktivasi outlet
  - Buat transaksi laundry baru
  - Catat pelanggan dan layanan yang dipilih
  - Perbarui status cucian: Diterima → Dicuci → Disetrika → Selesai
  - Lihat riwayat transaksi

  ### NexPos Admin (untuk Pemilik)
  Digunakan oleh pemilik usaha untuk memantau dan mengelola.

  - Daftar dan masuk akun pemilik
  - Kelola outlet (tambah, ubah nama, hapus)
  - Pantau perangkat kasir yang terdaftar
  - Lihat semua transaksi di seluruh outlet
  - Laporan pendapatan dan statistik
  - Kirim notifikasi ke perangkat kasir

  ---

  ## Cara Pakai (Alur Umum)

  1. Pemilik membuat akun melalui aplikasi **NexPos Admin**
  2. Pemilik membuat outlet dan mendapatkan kode aktivasi
  3. Kasir membuka **NexPos Laundry**, masukkan kode aktivasi untuk login
  4. Kasir mulai membuat transaksi dan mengelola cucian
  5. Pemilik bisa memantau semua transaksi dan pendapatan dari aplikasinya

  ---

  ## Server

  Aplikasi terhubung ke server yang sudah berjalan di:

  ```
  https://nexpos-production-3747.up.railway.app
  ```

  Tidak perlu setup server tambahan — cukup install aplikasinya.

  Jika ingin menjalankan server sendiri secara lokal:

  ```bash
  cd server
  npm install
  npm run dev
  ```

  ---

  ## Build Aplikasi

  APK dibangun otomatis melalui GitHub Actions setiap kali ada perubahan kode.
  Hasil APK bisa diunduh langsung dari tab **Actions** di halaman GitHub ini.

  Untuk build manual di komputer:

  ```bash
  # Aplikasi Laundry
  cd app-flutter
  flutter pub get
  flutter build apk

  # Aplikasi Admin
  cd app-flutter-admin
  flutter pub get
  flutter build apk
  ```

  ---

  ## Struktur Folder

  ```
  app-flutter/          Aplikasi kasir (NexPos Laundry)
  app-flutter-admin/    Aplikasi pemilik (NexPos Admin)
  server/               Server backend
  ```

  ---

  *NexPos dibuat untuk memudahkan pengelolaan usaha laundry sehari-hari.*
  