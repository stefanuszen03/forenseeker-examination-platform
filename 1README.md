# ForenSeeker - Platform Eksaminasi Forensik Digital Otomatis

## Deskripsi
ForenSeeker adalah platform otomatis untuk eksaminasi forensik digital yang mendukung analisis file gambar, jaringan (PCAP), memori, dan filesystem.

## Perbaikan yang Telah Dilakukan

### 1. **Keamanan**
- ✅ **Token Telegram Aman**: Token bot Telegram tidak lagi terpapar dalam kode
- ✅ **Konfigurasi Terpisah**: File `config.sh` untuk menyimpan konfigurasi sensitif
- ✅ **Pengecekan Konfigurasi**: Validasi konfigurasi Telegram sebelum digunakan

### 2. **Validasi Input**
- ✅ **Validasi File**: Pengecekan keberadaan file sebelum analisis
- ✅ **Validasi Parameter**: Pesan error yang jelas untuk parameter yang salah
- ✅ **Quoting Variables**: Penggunaan tanda kutip untuk mencegah masalah dengan nama file yang mengandung spasi

### 3. **Error Handling**
- ✅ **Pengecekan Tools**: Validasi keberadaan tools sebelum digunakan
- ✅ **Graceful Degradation**: Skrip tetap berjalan meskipun beberapa tools tidak tersedia
- ✅ **Pesan Error Informatif**: Pesan error yang jelas dan membantu

### 4. **Optimasi Kode**
- ✅ **Fungsi Reusable**: Fungsi `perform_hash_examination()` dan `create_final_report()` untuk mengurangi duplikasi
- ✅ **Path Validation**: Pengecekan keberadaan NetworkMiner di berbagai lokasi
- ✅ **Modular Design**: Kode yang lebih terorganisir dan mudah dipelihara

## Cara Penggunaan

### 1. Setup Awal
```bash
# Berikan permission eksekusi
chmod +x forenseeker.sh

# Konfigurasi Telegram (opsional)
cp config.sh.example config.sh
# Edit config.sh dengan token dan chat ID Anda
```

### 2. Konfigurasi Telegram
Edit file `config.sh`:
```bash
TELEGRAM_BOT_TOKEN="your_bot_token_here"
TELEGRAM_CHAT_ID="your_chat_id_here"
```

### 3. Penggunaan
```bash
# Menu interaktif
sudo ./forenseeker.sh

# Analisis file gambar
sudo ./forenseeker.sh -img evidence.jpg

# Analisis file PCAP
sudo ./forenseeker.sh -pcap network.pcap

# Analisis file memori
sudo ./forenseeker.sh -mem memory.dmp

# Analisis filesystem
sudo ./forenseeker.sh -f disk.img
```

## Tools yang Didukung

### Image Analysis
- ExifTool (metadata)
- Binwalk (file structure)
- Foremost (file carving)
- Zsteg (steganography)
- ImageMagick (image processing)
- Aletheia (manipulation detection)

### Network Analysis
- TShark (packet analysis)
- NetworkMiner (network forensics)
- BruteShark (password extraction)

### Memory Analysis
- Volatility3 (memory forensics)
- Rekall (memory analysis)

### Filesystem Analysis
- The Sleuth Kit (filesystem forensics)
- Foremost (file carving)
- Bulk Extractor (data extraction)
- Strings (text extraction)
- Binwalk (file structure)
- XXD (hex dump)

## Struktur Output
```
results/
├── images/
│   ├── executive_summary.txt
│   ├── sha256.txt
│   ├── md5.txt
│   ├── sha1.txt
│   ├── exiftool_result.txt
│   ├── binwalk_result.txt
│   └── ...
├── pcap/
├── memory/
└── filesystem/
```

## Troubleshooting

### 1. Tools Tidak Ditemukan
Skrip akan menampilkan warning dan melanjutkan dengan tools yang tersedia.

### 2. Konfigurasi Telegram
Jika konfigurasi Telegram belum diatur, fitur notifikasi akan dinonaktifkan secara otomatis.

### 3. Permission Denied
Pastikan menjalankan skrip dengan `sudo` untuk akses ke tools forensik.

## Keamanan
- Jangan commit file `config.sh` yang berisi token asli ke repository publik
- Gunakan environment variables untuk production environment
- Pastikan file evidence tidak mengandung informasi sensitif

## Lisensi
Platform ini dibuat oleh Stefanus Zen untuk tujuan akademis dan forensik digital. 
