# 🧲 Medan Magnet

Aplikasi **Toko Bangunan** berbasis Flutter dan Supabase, dibuat untuk memudahkan penjualan produk material bangunan.

---

## 🚀 Fitur Utama

- 🏠 **Halaman Admin**
  - Dashboard statistik (total user, pesanan, pendapatan, pesanan dibatalkan)
  - Manajemen produk (tambah / edit / hapus dengan upload gambar)
  - Manajemen pesanan (lihat, cari, ubah status pesanan)
  - Chat langsung dengan user

- 👤 **Halaman User**
  - Lihat produk dengan gambar & kategori
  - Pembelian produk (menambahkan ke keranjang)
  - Halaman profil & riwayat pesanan
  - Chat langsung dengan admin

- 📦 **Supabase Integration**
  - Database: user, product, orders, chat
  - Storage: upload gambar produk
  - Kebijakan RLS & storage policy tanpa Supabase Auth

---

## ⚙️ Instalasi

1. Clone repo:
    ```bash
    git clone https://github.com/afiflah/medanmagnet.git
    cd medanmagnet
    ```

2. Install dependencies:
    ```bash
    flutter pub get
    ```

3. Konfigurasi environment:
    - Buat file `.env` (atau masukkan variabel Supabase di `main.dart`)
    - Isi URL & anon key Supabase kamu

4. Run aplikasi:
    ```bash
    flutter run
    ```

---

## 📁 Struktur Project

/lib
├── pages/
│ ├── auth_page.dart
│ ├── home_admin_page.dart
│ ├── manajemen_produk_page.dart
│ ├── manajemen_pesanan_page.dart
│ ├── home_user_page.dart
│ ├── cart_page.dart
│ ├── history_page.dart
│ ├── profile_page.dart
│ ├── chat_admin_page.dart
│ ├── chat_user_page.dart
│ └── chat_detail_page.dart
├── components/
│ ├── admin_sidebar.dart
│ └── user_sidebar.dart
└── main.dart

🛠️ Konfigurasi Lain
- gitignore sudah disediakan untuk Flutter (build/, .dart_tool/, dll.).
- Login menggunakan tabel users, bukan Supabase Auth (email/password custom).
- Chat 1-on-1 antara admin dan user via tabel chat + chat_detail.

❓Masalah Umum
- StorageException 403 Unauthorized → pastikan policy di atas sudah dibuat.
- Fetch / Timeout → cek endpoint supabase, permissions, dan CORS.
- Merge / Git conflicts → konsultasi via issue di repo.

🙌 Kontribusi
Ingin bantu tambah fitur, perbaiki bug, atau optimasi UI? Silakan fork repository dan buat pull request.
