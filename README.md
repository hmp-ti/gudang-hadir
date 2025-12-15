# GudangHadir

Sistem Informasi Gudang + Absensi Digital (Offline).

## Fitur Utama
- **100% Offline**: Menggunakan SQLite.
- **Manajemen Gudang**: Stok Masuk/Keluar, Riwayat Transaksi.
- **Absensi**: QR Code & GPS (Geofencing).
- **Multi User**: Admin & Karyawan.

## Akun Demo
Saat pertama kali install, gunakan akun berikut:

**Admin:**
- Username: `admin`
- Password: `123456`

**Karyawan:**
- Username: `user1`
- Password: `123456`

## Cara Menjalankan
1.  Pastikan Flutter SDK terinstall.
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Jalankan aplikasi:
    ```bash
    flutter run
    ```

## Struktur Project
- `lib/core`: Database & Utils.
- `lib/features`: Auth, Warehouse, Attendance, Users, Settings, Profile.
- `lib/app`: Router & Theme.
