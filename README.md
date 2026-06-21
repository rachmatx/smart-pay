# SmartPay

Aplikasi simulasi pembayaran Flutter yang terhubung ke backend payment API kustom. Mendukung metode pembayaran **QRIS** dan **Transfer Bank**.

> Proyek ini adalah **prototipe** — dirancang untuk kejelasan dan kemudahan reuse, bukan untuk production.

---

## Fitur

- Buat transaksi baru (input nominal + deskripsi)
- Pilih metode pembayaran: QRIS atau Transfer Bank
- Konfirmasi pembayaran
- Cek status transaksi secara real-time (dengan tombol refresh)
- Konfigurasi merchant yang mudah di-swap per proyek

---

## Tech Stack

| Layer       | Teknologi                      |
|-------------|-------------------------------|
| Frontend    | Flutter (Dart) + Material 3   |
| Backend     | Node.js + Express             |
| Auth        | API Key via `X-Api-Key` header|
| HTTP Client | `http` package                |
| State       | `provider` package            |

---

## Struktur Folder

```
lib/
├── config/
│   └── merchant_config.dart     ← Konfigurasi baseUrl + apiKey
├── models/
│   └── transaction.dart         ← Model data transaksi (null-safe)
├── services/
│   └── payment_service.dart     ← Semua HTTP call ke backend
├── screens/
│   ├── home_screen.dart         ← Form buat transaksi baru
│   ├── payment_method_screen.dart     ← Pilih QRIS / Transfer Bank
│   ├── payment_confirmation_screen.dart ← Konfirmasi pembayaran
│   └── status_screen.dart       ← Tampilkan status transaksi
├── widgets/
│   ├── primary_button.dart      ← Tombol utama (themed)
│   ├── amount_input.dart        ← Input nominal format Rupiah
│   └── status_badge.dart        ← Badge status berwarna
└── main.dart                    ← Entry point + tema aplikasi
```

---

## Endpoint API

| Method | Endpoint                          | Deskripsi              |
|--------|-----------------------------------|------------------------|
| POST   | `/api/transactions`               | Buat transaksi baru    |
| POST   | `/api/transactions/:id/pay`       | Proses pembayaran      |
| GET    | `/api/transactions/:id/status`    | Cek status transaksi   |

---

## Setup & Konfigurasi

### 1. Konfigurasi Merchant

Edit file `lib/config/merchant_config.dart`:

```dart
class MerchantConfig {
  // Ganti dengan IP jaringan lokal server backend kamu
  String baseUrl = 'http://192.168.1.100:3000';

  // Ganti dengan API key yang valid
  String apiKey = 'your-api-key-here';
}
```

> **Penting:** Gunakan IP jaringan lokal (contoh: `192.168.1.x`), bukan `localhost`, karena app berjalan di device fisik.

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Jalankan di Device

Pastikan device Android terhubung via USB dan USB debugging aktif:

```bash
flutter run
```

---

## Alur Aplikasi

```
Home (input nominal & deskripsi)
  └─► Pilih Metode (QRIS / Transfer Bank)
       └─► Konfirmasi Pembayaran
            └─► Status Transaksi (pending / berhasil / gagal)
                 └─► Refresh atau Buat Transaksi Baru
```

---

## Catatan

- **Cleartext traffic** sudah diaktifkan di `AndroidManifest.xml` untuk koneksi HTTP ke server lokal. Untuk production, gunakan HTTPS.
- Semua komentar kode ditulis dalam **Bahasa Indonesia**.
- Tidak ada warna yang di-hardcode — semua menggunakan `Theme.of(context)` (Material 3 color scheme).
- Target device: **Android fisik** (tanpa emulator).

---

## Lisensi

Prototipe internal — bebas digunakan dan dimodifikasi untuk keperluan pengembangan.
# smart_pay

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
