# 🗄️ Database & Storage Schema

Ini adalah panduan lengkap untuk mengatur Database dan Storage di Appwrite agar aplikasi **GudangHadir** berjalan dengan baik.

---

## 🏗️ Struktur Database

**Database ID**: `gudang_hadir_db`

### 1. 👥 Collection: Users
*Collection ID*: `users`

| Attribute Name | Type | Size | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| `name` | String | 128 | Yes | Nama lengkap pengguna |
| `email` | Email | - | Yes | Email login |
| `role` | String | 32 | Yes | `admin`, `owner`, atau `karyawan` |
| `is_active` | Boolean | - | Yes | Status keaktifan akun user |
| `photoUrl` | Url | - | No | Foto profil user (dari Bucket) |

> **Security Note:** User ID di dokumen ini harus sama dengan User ID di Appwrite Auth jika ingin sinkronisasi 1:1.

### 2. 📦 Collection: Items
*Collection ID*: `items`

| Attribute Name | Type | Size | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| `code` | String | 64 | Yes | Kode barang/SKU (Unique) |
| `name` | String | 128 | Yes | Nama barang |
| `description` | String | 1024 | No | Deskripsi barang |
| `stock` | Integer | - | Yes | Stok saat ini (Min: 0) |
| `minStock` | Integer | - | Yes | Batas minimum stok (Warning limit) |
| `unit` | String | 32 | Yes | Satuan (Pcs, Box, Liter, dll) |
| `price` | Double | - | Yes | Harga dasar/beli |
| `category` | String | 64 | Yes | Kategori barang |
| `rackLocation` | String | 64 | No | Lokasi rak gudang |
| `manufacturer` | String | 64 | No | Nama pembuat/merk |
| `discontinued` | Boolean | - | Yes | Status barang sudah tidak dijual (Default: false) |
| `updatedAt` | Datetime | - | Yes | Waktu terakhir update stok |

### 3. 📝 Collection: Transactions
*Collection ID*: `transactions`

| Attribute Name | Type | Size | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| `itemId` | String | 36 | Yes | ID Barang (Relasi ke Items) |
| `type` | String | 16 | Yes | Tipe transaksi: `IN` atau `OUT` |
| `qty` | Integer | - | Yes | Jumlah barang |
| `note` | String | 255 | No | Catatan transaksi |
| `createdAt` | Datetime | - | Yes | Waktu transaksi |
| `createdBy` | String | 36 | Yes | User ID yang input (Relasi ke Users) |

### 4. 📍 Collection: Attendances
*Collection ID*: `attendances`

| Attribute Name | Type | Size | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| `userId` | String | 36 | Yes | ID Karyawan (Relasi ke Users) |
| `userName` | String | 128 | No | Nama karyawan (Snapshot/Cache) |
| `date` | String | 20 | Yes | Tanggal Absen (Format: YYYY-MM-DD) |
| `checkInTime` | Datetime | - | No | Waktu Check-In |
| `checkOutTime` | Datetime | - | No | Waktu Check-Out |
| `checkInMethod` | String | 32 | Yes | `QR` atau `GPS` |
| `checkOutMethod` | String | 32 | No | `QR` atau `GPS` |
| `lat` | Double | - | No | Latitude (GPS) |
| `lng` | Double | - | No | Longitude (GPS) |
| `isValid` | Boolean | - | Yes | Apakah lokasi valid (dalam radius) |
| `note` | String | 255 | No | Catatan kehadiran |
| `totalDuration` | Double | - | No | Total jam kerja (CheckOut - CheckIn) |
| `overtimeHours` | Double | - | No | Total lembur |

### 5. 🛌 Collection: Leaves
*Collection ID*: `leaves`

| Attribute Name | Type | Size | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| `userId` | String | 36 | Yes | ID Pengaju Cuti (Relasi ke Users) |
| `userName` | String | 128 | No | Nama Pengaju |
| `reason` | String | 512 | Yes | Alasan cuti |
| `startDate` | String | 32 | Yes | Tanggal mulai |
| `endDate` | String | 32 | Yes | Tanggal selesai |
| `status` | String | 16 | Yes | `pending`, `approved`, `rejected` |
| `adminId` | String | 36 | No | ID Admin yang menyetujui |
| `pdfFileId` | String | 64 | No | ID File PDF Surat Cuti |

### 6. 📊 Collection: Generated Reports
*Collection ID*: `generated_reports`

| Attribute Name | Type | Size | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| `title` | String | 255 | Yes | Judul Laporan |
| `reportType` | String | 64 | Yes | Jenis Laporan |
| `format` | String | 16 | Yes | `pdf` atau `excel` |
| `fileId` | String | 64 | Yes | ID File di Storage |
| `fileUrl` | Url | - | No | Direct Link Download |
| `filterType` | String | 32 | No | Filter yang digunakan |
| `startDate` | Datetime | - | No | Filter Periode Awal |
| `endDate` | Datetime | - | No | Filter Periode Akhir |
| `createdBy` | String | 36 | Yes | User ID pembuat laporan |

---

### 7. 💵 Collection: Payroll Configs
*Collection ID*: `payroll_configs`

| Attribute Name | Type | Size | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| `userId` | String | 36 | Yes | ID Karyawan (Relasi ke Users) |
| `baseSalary` | Double | - | Yes | Gaji Pokok |
| `transportAllowance` | Double | - | Yes | Tunjangan Transport (Harian) |
| `mealAllowance` | Double | - | Yes | Uang Makan (Harian) |
| `overtimeRate` | Double | - | Yes | Upah Lembur (Per Jam) |
| `latePenalty` | Double | - | Yes | Denda Terlambat (Per Menit) |
| `absentPenalty` | Double | - | Yes | Denda Tidak Masuk (Per Hari) |
| `shiftStartTime` | String | 5 | Yes | Jam Masuk Kerja (Format HH:MM) |

### 8. 🧾 Collection: Payrolls (Slip Gaji)
*Collection ID*: `payrolls`

| Attribute Name | Type | Size | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| `userId` | String | 36 | Yes | ID Karyawan (Relasi ke Users) |
| `periodStart` | String | 10 | Yes | Periode Awal (YYYY-MM-DD) |
| `periodEnd` | String | 10 | Yes | Periode Akhir (YYYY-MM-DD) |
| `baseSalary` | Double | - | Yes | Gaji Pokok (Snapshot) |
| `totalAllowance` | Double | - | Yes | Total Tunjangan |
| `totalOvertime` | Double | - | Yes | Total Lembur |
| `totalDeduction` | Double | - | Yes | Total Potongan |
| `netSalary` | Double | - | Yes | Gaji Bersih (Take Home Pay) |
| `detail` | String | 5000 | Yes | JSON Detail Perhitungan |
| `status` | String | 16 | Yes | `draft` atau `paid` |

---

## 🗂️ Storage Buckets

### Bucket: `general_storage`
Gunakan bucket ini untuk menyimpan semua file:
*   Foto Profil User
*   Dokumen PDF Laporan
*   File Excel Exports
*   Dokumen Surat Cuti

**Permission Settings:**
*   **Users**: Create, Read
*   **Admins**: Create, Read, Update, Delete
