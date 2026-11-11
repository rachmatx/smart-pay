# Pengaturan Payment API manual — Smart Pay 1.0.1

Tab **Saya** sekarang berisi konfigurasi server. Pasang versi aplikasi yang memuat fitur ini satu kali; sesudah itu perubahan alamat/API key tidak memerlukan edit source atau build ulang.

## Cara pakai

1. Buka **Saya → Konfigurasi server**.
2. Isi alamat Payment API: contoh lokal `http://192.168.1.10:3000`, atau alamat online HTTPS milik server Anda. Ganti contoh IP dengan IPv4 Wi-Fi laptop.
3. Isi **API key merchant**, sama dengan `API_KEY` di `.env` Payment API dan `PAYMENT_API_KEY` pada Laundry. Bukan token GitHub atau secret webhook.
4. **Uji koneksi** memeriksa `/health`, lalu akses merchant secara read-only. Tidak membuat atau membayar invoice. Pemeriksaan draft belum mengubah server aktif.
5. Pilih **Simpan konfigurasi**, periksa alamat pada dialog lalu konfirmasi. Pengaturan bisa disimpan walaupun server sementara mati. Hasil cek koneksi sebelumnya dibersihkan ketika input diedit.

Alamat tidak ditambah `/api/transactions`, `/health`, akun, query atau fragment. HTTP dibatasi pada localhost/IP privat; server internet menggunakan HTTPS. `localhost` di HP adalah HP sendiri, sedangkan `10.0.2.2` hanya untuk emulator. HP/laptop harus satu Wi-Fi dan port 3000 harus dapat dijangkau HP untuk server lokal.

API key disamarkan pada form, bisa ditampilkan melalui ikon mata dan disimpan melalui Flutter Secure Storage bersama alamat dalam satu record. Tidak ada API key bawaan pada source baru. Startup yang tidak dapat membaca konfigurasi kembali ke halaman Saya tanpa mengirim credential fallback. Android backup dinonaktifkan untuk menghindari pemulihan data terenkripsi tanpa kunci perangkat.

## Pergantian server

Penyimpanan berhasil membuat scope request baru dan mereset navigasi, riwayat/feed serta saldo top-up prototype. Layar server sebelumnya dibuang. Instance layanan pembayaran lama menolak request baru dan hasil respons lama setelah konfigurasi berubah. Instance untuk konfirmasi pembayaran dibuat sebelum proses PIN/biometrik, sehingga callback lama tidak memulai pembayaran ke server baru.

Ini tidak membatalkan invoice atau request pembayaran yang sudah dikirim ke server lama. Periksa status pada server asal bila sebelumnya sudah menekan bayar. Perubahan tidak membuat pembayaran bank nyata; Payment API pasangan masih simulator. Secret webhook tetap hanya berada pada server.

Kesalahan koneksi, key salah, transaksi tidak ditemukan, konflik dan expiry memakai pesan yang dapat dibaca. Redirect HTTP tidak diikuti dengan merchant credential. Request memiliki timeout dan batas ukuran respons.

## Pemeriksaan

```sh
flutter pub get
flutter analyze
flutter test
```

Tes mencakup persistensi/restart, kegagalan secure storage, URL tidak valid, isolasi host/merchant, respons server lama, koneksi read-only, penolakan redirect, key salah tanpa echo credential, dialog simpan/batal, navigasi lama yang dibersihkan, dan form/navigasi lebar 320 px dengan teks besar.

Screenshot opt-in memakai merchant fiktif di `docs/screenshots/`. Capture memerlukan font Roboto dari SDK lokal sesuai path pada tool. Native secure storage, kamera, fingerprint dan koneksi LAN tetap memerlukan uji HP fisik.
