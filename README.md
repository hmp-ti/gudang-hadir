# GudangHadir

![GudangHadir Banner](https://via.placeholder.com/1200x400.png?text=GudangHadir+Digital+System)

<div align="center">

**Sistem Informasi Gudang Terintegrasi dengan Absensi Digital**

[![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State-Riverpod-blue)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

Created with ❤️ by **Himpunan Mahasiswa Prodi Teknik Informatika (HMP-TI)**

</div>

---

## 📖 Tentang Aplikasi

**GudangHadir** adalah solusi all-in-one untuk manajemen stok gudang dan absensi karyawan yang dirancang khusus untuk operasional bisnis modern. Dibangun menggunakan teknologi **Flutter** terbaru, aplikasi ini menawarkan antarmuka yang modern, cepat, dan mudah digunakan (User Friendly).

### 🚀 Fitur Utama

#### 📦 Manajemen Gudang (Warehouse)
*   **Real-time Stock**: Pantau jumlah stok barang masuk dan keluar secara instan.
*   **Input Mudah**: Tambah barang baru atau update stok dengan beberapa ketukan.
*   **Low Stock Alert**: Notifikasi visual untuk barang yang stoknya menipis.

#### 📍 Absensi Cerdas (Attendance)
*   **QR Code Scan**: Presensi cepat dan aman dengan memindai kode QR unik.
*   **Geo-Tagging (GPS)**: Validasi lokasi karyawan untuk memastikan kehadiran di tempat kerja.
*   **Riwayat**: Karyawan dapat melihat log kehadiran mereka sendiri.

#### 👥 Manajemen Pengguna
*   **Multi-Role**: Dukungan untuk akun **Admin** dan **Karyawan**.
*   **Keamanan**: Sistem login yang aman dengan validasi sesi.

---

## 🛠️ Teknologi

Aplikasi ini dibangun menggunakan *stack* teknologi modern:
*   **Framework**: Flutter SDK (Minimal SDK 36)
*   **Language**: Dart 3.x
*   **State Management**: Flutter Riverpod
*   **Database**: SQLite (sqflite)
*   **Navigation**: GoRouter
*   **Features**: Mobile Scanner (QR), Geolocator (GPS)

---

## 📸 Screenshots

| Login Screen | Dashboard Admin | Scan QR |
|:---:|:---:|:---:|
| ![Login](https://via.placeholder.com/200x400?text=Login) | ![Dashboard](https://via.placeholder.com/200x400?text=Dashboard) | ![Scan](https://via.placeholder.com/200x400?text=Scan) |

*(Screenshot akan diperbarui saat rilis final)*

---

## 🔧 Cara Instalasi

1.  **Clone Repository**
    ```bash
    git clone https://github.com/hmp-ti/gudang-hadir.git
    cd gudang_hadir
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run Application**
    ```bash
    flutter run
    ```

---

## 🔐 Akun Demo

Untuk pengujian, gunakan akun berikut yang telah terdaftar secara default pada saat instalasi:

| Role | Username | Password |
| :--- | :--- | :--- |
| **Admin** | `admin` | `123456` |
| **Karyawan** | `user1` | `123456` |

> **Catatan**: Password disimpan dengan format sederhana untuk tujuan demonstrasi.

---

## © Copyright

**Himpunan Mahasiswa Prodi Teknik Informatika (HMP-TI)**
Universitas Islam Kalimantan Muhammad Arsyad Al-Banjari Banjarmasin.

*Made for educational purposes and internal management solutions.*
