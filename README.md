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

## Protokol MQTT Auto-Discovery & Integrasi ESP32

Iuno menggunakan sistem **MQTT Auto-Discovery** yang dinamis. Mikrokontroler (ESP32) cukup mengirimkan berkas konfigurasi berbentuk JSON sekali saja saat terhubung ke broker MQTT. Dashboard aplikasi Iuno akan mendeteksi payload tersebut secara otomatis, lalu merender dan memvisualisasikan widget sensor/sakelar secara instan tanpa perlu melakukan koding ulang di aplikasi Flutter.

### 1. Struktur Payload Penemuan (Discovery Topic)
ESP32 mengirimkan konfigurasi pada topik ber-pattern:  
`iuno/<device_id>/discovery/<widget_id>`

Topik subscribe di aplikasi Flutter adalah:  
`iuno/+/discovery/#`

Struktur payload JSON yang dikirimkan oleh ESP32:
```json
{
  "id": "esp32_sensor_suhu",          // ID unik widget
  "type": "sensor | switch | button", // Tipe widget kontrol
  "name": "Suhu DHT22",               // Judul widget di dashboard
  "unit": "°C",                       // Satuan (opsional, hanya untuk sensor)
  "state_topic": "iuno/esp32/temp",   // Topik sensor mengirim data statusnya
  "command_topic": ""                 // Topik menerima perintah (opsional, hanya untuk switch/button)
}
```

### 2. Sinyal Rediscover (Permintaan Hub)
Saat aplikasi Iuno pertama kali berjalan atau berhasil terhubung ulang ke Broker, aplikasi akan mengirimkan pesan `"rediscover"` ke topik:  
`iuno/device/cmd`

Setiap mikrokontroler (ESP32) wajib berlangganan (*subscribe*) ke topik tersebut dan langsung memancarkan ulang berkas konfigurasi discovery-nya agar sinkronisasi dashboard kembali terjalin secara otomatis.

---

### 3. Kode Arduino / ESP32 Siap Pakai

Berikut adalah contoh *sketch* Arduino C++ lengkap menggunakan library **PubSubClient** dan **ArduinoJson** untuk ESP32:

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// 1. Konfigurasi Jaringan Wi-Fi Anda
const char* ssid = "NAMA_WIFI_ANDA";
const char* password = "PASSWORD_WIFI_ANDA";

// 2. Konfigurasi Broker MQTT (Sesuaikan dengan IP yang disetel pada System Settings aplikasi Iuno)
const char* mqtt_server = "192.168.10.3"; 
const int mqtt_port = 1883;

WiFiClient espClient;
PubSubClient client(espClient);

// Pin fisik aktuator/relay
const int RELAY_PIN = 2; // LED bawaan board ESP32

unsigned long lastMsg = 0;

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Menghubungkan ke ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWi-Fi terhubung!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
}

// Mengirim JSON Auto-Discovery untuk mendaftarkan Widget ke aplikasi Iuno secara otomatis
void publishDiscovery() {
  Serial.println("Mengirimkan Konfigurasi Auto-Discovery...");

  // A. Pendaftaran Widget 1: Sensor Suhu DHT22
  StaticJsonDocument<256> docTemp;
  docTemp["id"] = "esp32_suhu_dht22";
  docTemp["type"] = "sensor";
  docTemp["name"] = "Suhu DHT22";
  docTemp["unit"] = "°C";
  docTemp["state_topic"] = "iuno/esp32/suhu";
  docTemp["command_topic"] = "";
  
  char bufferTemp[256];
  serializeJson(docTemp, bufferTemp);
  client.publish("iuno/esp32/discovery/temp", bufferTemp);

  // B. Pendaftaran Widget 2: Sensor Kelembaban DHT22
  StaticJsonDocument<256> docHum;
  docHum["id"] = "esp32_kelembaban_dht22";
  docHum["type"] = "sensor";
  docHum["name"] = "Kelembaban DHT22";
  docHum["unit"] = "%";
  docHum["state_topic"] = "iuno/esp32/kelembaban";
  docHum["command_topic"] = "";
  
  char bufferHum[256];
  serializeJson(docHum, bufferHum);
  client.publish("iuno/esp32/discovery/hum", bufferHum);

  // C. Pendaftaran Widget 3: Sakelar Relay Fisik
  StaticJsonDocument<256> docRelay;
  docRelay["id"] = "esp32_relay_switch";
  docRelay["type"] = "switch";
  docRelay["name"] = "Relay Switch";
  docRelay["unit"] = "";
  docRelay["state_topic"] = "iuno/esp32/relay/state";
  docRelay["command_topic"] = "iuno/esp32/relay/cmd";
  
  char bufferRelay[256];
  serializeJson(docRelay, bufferRelay);
  client.publish("iuno/esp32/discovery/relay", bufferRelay);
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.print("Pesan masuk [");
  Serial.print(topic);
  Serial.print("]: ");
  Serial.println(message);

  // Tanggapi sinyal rediscovery dari aplikasi Flutter
  if (String(topic) == "iuno/device/cmd" && message == "rediscover") {
    publishDiscovery();
  }
  
  // Tanggapi kontrol Switch dari aplikasi Iuno
  if (String(topic) == "iuno/esp32/relay/cmd") {
    if (message == "ON") {
      digitalWrite(RELAY_PIN, HIGH);
      client.publish("iuno/esp32/relay/state", "ON"); // Kirim state balik ke app
      Serial.println("Relay aktif (ON)");
    } else if (message == "OFF") {
      digitalWrite(RELAY_PIN, LOW);
      client.publish("iuno/esp32/relay/state", "OFF"); // Kirim state balik ke app
      Serial.println("Relay non-aktif (OFF)");
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Mencoba koneksi MQTT...");
    String clientId = "ESP32Client-" + String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str())) {
      Serial.println("terhubung!");
      
      // Berlangganan topik perintah rediscover dan kontrol relay
      client.subscribe("iuno/device/cmd");
      client.subscribe("iuno/esp32/relay/cmd");
      
      // Kirim auto-discovery config saat berhasil terhubung
      publishDiscovery();
    } else {
      Serial.print("gagal, rc=");
      Serial.print(client.state());
      Serial.println(" Mencoba kembali dalam 5 detik...");
      delay(5000);
    }
  }
}

void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  Serial.begin(115200);
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long now = millis();
  if (now - lastMsg > 5000) { // Kirim data sensor berkala setiap 5 detik
    lastMsg = now;
    
    // Ganti nilai random di bawah ini dengan pembacaan sensor DHT22 / sensor fisik Anda yang sebenarnya
    float temp = 24.0 + random(0, 100) / 20.0;
    float hum = 58.0 + random(0, 100) / 10.0;
    
    client.publish("iuno/esp32/suhu", String(temp, 1).c_str());
    client.publish("iuno/esp32/kelembaban", String(hum, 1).c_str());
    
    Serial.print("Mengirim Telemetri -> Suhu: "); Serial.print(temp);
    Serial.print("°C | Kelembaban: "); Serial.print(hum); Serial.println("%");
  }
}
```

---

### 4. Alternatif: Koneksi ke HiveMQ Cloud (Secure TLS dengan Username & Password)

HiveMQ Cloud adalah broker *cloud* MQTT terenkripsi yang sangat populer untuk proyek IoT berskala produksi. Karena HiveMQ Cloud menggunakan enkripsi SSL/TLS pada port **8883** dan mewajibkan autentikasi, Anda perlu memodifikasi kode ESP32 dasar di atas seperti berikut:

#### A. Ubah Import dan Inisialisasi Client
Ganti `WiFiClient espClient` dengan `WiFiClientSecure` untuk menangani enkripsi TLS:
```cpp
#include <WiFi.h>
#include <WiFiClientSecure.h> // Library bawaan ESP32 untuk koneksi aman
#include <PubSubClient.h>
#include <ArduinoJson.h>

// Set SSL Client
WiFiClientSecure espClient;
PubSubClient client(espClient);
```

#### B. Sesuaikan Kredensial HiveMQ Anda
Masukkan alamat host unik dari konsol HiveMQ Cloud Anda, gunakan port **8883**, dan tentukan Username/Password MQTT Anda:
```cpp
const char* mqtt_server = "xxxxxxxxxxxxxxxx.s2.eu.hivemq.cloud"; // Host HiveMQ Anda
const int mqtt_port = 8883; // Port TLS SSL standard
const char* mqtt_user = "username_mqtt_anda"; // Dibuat di tab credentials HiveMQ
const char* mqtt_pass = "password_mqtt_anda";
```

#### C. Konfigurasi Sertifikat SSL di `setup()`
Agar ESP32 dapat bernegosiasi secara aman via SSL, tambahkan perintah `setInsecure()` pada setup untuk melewati verifikasi rantai sertifikat (sangat direkomendasikan untuk kemudahan pengujian tanpa perlu menyalin string sertifikat Root CA yang panjang):
```cpp
void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  Serial.begin(115200);
  setup_wifi();
  
  // Lewati verifikasi sertifikat root (menjaga agar tetap aman tanpa repot menyalin CA certificate)
  espClient.setInsecure(); 
  
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}
```

#### D. Sesuaikan Fungsi `reconnect()` dengan Autentikasi
Saat melakukan panggilan `client.connect()`, Anda harus menyertakan argumen username dan password agar diizinkan masuk oleh HiveMQ:
```cpp
void reconnect() {
  while (!client.connected()) {
    Serial.print("Mencoba koneksi MQTT HiveMQ...");
    String clientId = "ESP32SecureClient-" + String(random(0xffff), HEX);
    
    // Sertakan username dan password untuk autentikasi HiveMQ
    if (client.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
      Serial.println("terhubung aman ke HiveMQ!");
      
      client.subscribe("iuno/device/cmd");
      client.subscribe("iuno/esp32/relay/cmd");
      
      publishDiscovery();
    } else {
      Serial.print("gagal terhubung, rc=");
      Serial.print(client.state());
      Serial.println(" Mencoba kembali dalam 5 detik...");
      delay(5000);
    }
  }
}
```

---

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
