# Iuno IoT Dashboard

Iuno adalah aplikasi *dashboard* IoT cerdas berbasis Flutter yang dirancang untuk memantau data sensor secara *real-time* dan melakukan otomasi pengambilan keputusan (*Edge AI*). Aplikasi ini mengadopsi gaya desain **Neubrutalism** yang mencolok, modern, dan fungsional.

## Fitur Utama

✨ **Native Edge AI (Fuzzy Logic)**
Aplikasi ini tidak sekadar menampilkan data, tapi juga bisa "berpikir" sendiri! Tanpa bergantung pada server atau *backend* Python eksternal, Iuno mengalkulasikan target suhu dan kelembaban secara langsung di dalam perangkat (HP) secara otomatis.

📈 **Real-Time Analytics**
Grafik data suhu dan kelembaban langsung digambar secara *real-time* tanpa *lag* menggunakan `fl_chart`. Tampilan analitik tetap terlihat rapi meskipun ada banyak lonjakan titik data berkat optimalisasi render.

🔌 **Konektivitas MQTT Tanpa Hambatan**
Terhubung langsung ke mikrokontroler (misal: ESP32) menggunakan protokol MQTT via `broker.emqx.io`. Sangat ringan dan responsif!

🎨 **Neubrutalism UI/UX**
Antarmuka berani dengan *shadow* pekat, garis luar (border) tebal, serta font **Space Grotesk** yang memberikan kesan industrial sekaligus *playful*. Sistem navigasinya menggunakan `IndexedStack` sehingga transisi antar tab berjalan mulus tanpa efek berkedip (*flicker-free*).

## Topik MQTT yang Digunakan

Aplikasi berkomunikasi dengan perangkat *hardware* menggunakan topik-topik MQTT berikut:

**Subscribe (Menerima Data dari Sensor):**
- `+/sensor/suhu` : Membaca nilai suhu dari sensor.
- `+/sensor/kelembaban` : Membaca nilai kelembaban dari sensor.

**Publish (Mengirim Perintah ke Aktuator):**
- `iuno/ai/target/suhu` : Mengirimkan target suhu yang dihitung oleh AI ke mikrokontroler (misal: untuk menyalakan AC/Kipas).
- `iuno/ai/target/kelembaban` : Mengirimkan target kelembaban ke mikrokontroler.

## Teknologi yang Digunakan

- **Flutter / Dart** (Minimum Android API 21)
- **GetX** (State Management & Reactive UI)
- **mqtt_client** (Konektivitas MQTT)
- **fl_chart** (Visualisasi Grafik Data)
- **Google Fonts** (Tipografi Space Grotesk)

## Cara Menjalankan Aplikasi

1. Pastikan Anda telah menginstal [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Kloning repositori ini:
   ```bash
   git clone https://github.com/WilyArd/Iuno-Project.git
   ```
3. Pindah ke direktori proyek:
   ```bash
   cd Iuno-Project
   ```
4. Instal semua dependensi (package):
   ```bash
   flutter pub get
   ```
5. Jalankan aplikasi di perangkat Android atau emulator:
   ```bash
   flutter run
   ```

## Lisensi

[MIT License](LICENSE) (Jika ada)
