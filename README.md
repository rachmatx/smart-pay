# Smart Pay App

Aplikasi prototipe dompet digital (e-wallet) interaktif yang dibangun menggunakan Flutter. Aplikasi ini dirancang secara modular agar dapat mensimulasikan pembayaran mandiri (melalui metode QRIS maupun Transfer Bank) dan terhubung secara dinamis ke sistem API lokal maupun remote (Production).

## Fitur Utama

- Pemindaian QRIS (QR Scanner): Menggunakan library `mobile_scanner` untuk membaca tautan pembayaran atau referensi QRIS secara real-time dari kamera perangkat.
- Transfer Bank Dinamis: Mampu membaca metadata JSON dari respons API backend dan secara otomatis menyesuaikan UI (seperti nama bank dan nama pemilik rekening atau merchant).
- Otentikasi Biometrik Tingkat Lanjut: Terintegrasi dengan sensor biometrik perangkat (Fingerprint atau FaceID) menggunakan package `local_auth`. Sistem keamanan ini memanfaatkan enkripsi lokal perangkat (Secure Enclave pada iOS atau Keystore pada Android) tanpa perlu menyimpan data biometrik di dalam database.
- Kalkulasi Saldo Otomatis: Sinkronisasi saldo dilakukan secara dinamis berdasarkan kalkulasi total nominal tagihan berstatus "SUCCESS" dari backend, dikurangi dari saldo dasar pengguna.
- Reusable Architecture: Semua teks merchant, status tagihan, dan detail transaksi diambil langsung dari backend API, sehingga aplikasi Flutter ini tidak memiliki data entitas merchant yang terikat mati (hardcoded).

## Panduan Instalasi dan Pengaturan Lingkungan (Environment Setup)

Agar aplikasi dapat berjalan dan berkomunikasi dengan API backend di lingkungan pengembangan lokal Anda, ikuti instruksi berikut:

### 1. Menyelaraskan Alamat IP Jaringan (Local Network)

Ketika menjalankan aplikasi di perangkat Android fisik melalui USB Debugging, perangkat tersebut tidak akan mengenali alamat `localhost` sebagai komputer Anda (karena `localhost` di dalam smartphone akan merujuk ke dirinya sendiri). Oleh karena itu, Anda diwajibkan untuk menggunakan alamat IP komputer server Anda.

1. Hubungkan komputer (Server API) dan smartphone Android ke dalam satu jaringan Wi-Fi (Atau gunakan jaringan Hotspot seluler yang sama).
2. Temukan alamat IPv4 Wi-Fi komputer Anda dengan menjalankan perintah `ipconfig` (Windows) atau `ifconfig` (Mac/Linux) di Command Prompt atau Terminal. (Contoh: `192.168.100.10`).
3. Buka file konfigurasi di dalam direktori `lib/config/merchant_config.dart`.
4. Ubah variabel `baseUrl` menggunakan alamat IPv4 tersebut beserta port API yang Anda gunakan.
   ```dart
   String baseUrl = 'http://192.168.100.10:3000';
   ```

### 2. Membangun dan Menjalankan Aplikasi (Testing Mode)

1. Buka direktori proyek ini di Terminal, Command Prompt, Android Studio, atau VS Code.
2. Unduh semua pustaka (dependencies) yang dibutuhkan oleh proyek:
   ```bash
   flutter pub get
   ```
3. Sambungkan smartphone Android Anda via kabel USB dan pastikan mode "USB Debugging" serta "Install via USB" telah diaktifkan di menu Developer Options.
4. Jalankan aplikasi menggunakan perintah:
   ```bash
   flutter run
   ```
5. Tunggu proses instalasi dan Gradle build selesai. Setelah aplikasi berhasil terbuka di layar smartphone, Anda dapat mencabut kabel USB. Aplikasi akan terus berjalan secara independen selama perangkat terhubung dengan jaringan Wi-Fi yang sama dengan server API Anda.

## Panduan Kompilasi Produksi (Membangun File APK)

Apabila aplikasi sudah berstatus final dan Anda ingin mendistribusikannya untuk diinstal pada perangkat Android lain tanpa melalui proses USB Debugging, Anda perlu membangun (build) file Android Package (APK).

1. Pastikan seluruh konfigurasi API (Base URL dan API Key) di `merchant_config.dart` sudah diarahkan ke URL server produksi (Public Domain) dan menggunakan standar protokol `https`.
2. Jalankan perintah kompilasi rilis berikut di Terminal Anda:
   ```bash
   flutter build apk --release
   ```
3. Proses kompilasi kode (AOT Compilation) akan berjalan selama beberapa menit.
4. Setelah proses selesai, file APK final akan tersimpan secara otomatis di dalam direktori:
   `build/app/outputs/flutter-apk/app-release.apk`
5. Salin file `app-release.apk` tersebut dan Anda dapat membagikannya kepada klien atau pengguna lain untuk diinstal secara langsung di sistem operasi Android.

## Panduan Integrasi Antar Proyek (Reusability)

Salah satu nilai utama dari arsitektur Smart Pay adalah desain kode yang sangat dinamis dan dapat digunakan kembali secara instan. Jika Anda memiliki proyek Point of Sales (Kasir) atau E-Commerce lain di masa mendatang, Anda sama sekali tidak perlu mengubah struktur logika atau User Interface dari aplikasi Flutter ini.

Berikut adalah tahapan teknis untuk melakukan integrasi dengan sistem backend yang baru:

### 1. Standarisasi API Backend

Aplikasi Smart Pay beroperasi murni berdasarkan instruksi dari Payment API (menggunakan Node.js/Express.js atau kerangka bahasa pemrograman backend lainnya). Anda hanya perlu mengembangkan backend API di sistem yang baru, dengan syarat memastikan endpoint yang disediakan merespons dengan format JSON yang identik dengan Smart Pay Contract:
- Endpoint POST `/api/transactions` (Menerima permintaan pembuatan tagihan baru)
- Endpoint GET `/api/transactions/:id/status` (Memberikan respons status riwayat tagihan)
- Endpoint GET `/api/transactions/find-transfer-target` (Mengembalikan rincian data merchant/bank berdasarkan kode transfer)

### 2. Penyesuaian File Konfigurasi (Single Point of Configuration)

Tanpa perlu merombak seluruh barisan file UI, Anda hanya diwajibkan untuk merevisi dua nilai variabel pada file `lib/config/merchant_config.dart`. Perubahan ini akan menghubungkan aplikasi secara utuh ke ekosistem proyek yang baru.

```dart
class MerchantConfig {
  MerchantConfig._internal();
  static final MerchantConfig _instance = MerchantConfig._internal();
  static MerchantConfig get instance => _instance;

  // 1. Ubah alamat Base URL di bawah ke domain API / Server kasir Anda yang baru
  String baseUrl = 'https://api.proyek-baru-anda.com';

  // 2. Ubah baris ini sesuai dengan API Key autentikasi di server backend Anda yang baru
  String apiKey = 'API-KEY-PROYEK-BARU-RAHASIA';
}
```

Melalui prosedur konfigurasi singkat di atas, maka atribut-atribut seperti: teks identitas merchant, nama sistem penyedia layanan pada halaman struk transaksi, dan nomor rekening penampung tagihan, akan secara otomatis mengikuti data mutakhir yang dikirimkan oleh server baru Anda. Mekanisme ini menjamin Smart Pay untuk selalu berfungsi sebagai layanan Payment Gateway yang fleksibel dan independen.

---

## Sumber Daya Pengembangan (Resources)

Proyek ini adalah titik awal yang baik untuk aplikasi Flutter. Jika Anda memerlukan referensi untuk menangani bug, melakukan debugging, atau mempelajari cara kerja framework ini lebih dalam, Anda dapat merujuk pada sumber informasi resmi berikut:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

Untuk bantuan awal dan referensi komprehensif terkait ekosistem Flutter dan Dart, silakan baca dokumentasi resmi di [Flutter Online Documentation](https://docs.flutter.dev/). Di sana Anda akan menemukan panduan tutorial lengkap, sampel kode, panduan pengembangan arsitektur mobile, hingga referensi API secara menyeluruh.
