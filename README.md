# Iuno IoT Dashboard

> **A smart, real-time IoT dashboard built with Flutter — connecting your ESP32 devices to a beautiful, modern interface.**

Iuno is a Flutter-based IoT dashboard that monitors sensor data in real-time and supports intelligent automation. It features a premium Slate-Teal design language, MQTT auto-discovery for zero-config device integration, and a built-in Edge AI assistant.

---

## ✨ Key Features

### 🧠 Native Edge AI (Fuzzy Logic)

Iuno doesn't just display data — it _thinks_. Without any external backend or Python server, the app calculates recommended targets (e.g. optimal temperature and humidity) directly on-device using a fuzzy logic engine.

### 📈 Real-Time Analytics & Live Trends

Telemetry charts are rendered in real-time using `fl_chart` with smooth curves, precise dynamic axis ranges per sensor category, and a live "LIVE TRENDS" badge.

### 🔌 MQTT Connectivity & Background Keep-Alive

- **TLS/SSL Encryption**: Supports local brokers and encrypted cloud brokers (e.g. HiveMQ Cloud) with automatic domain sanitization and authentication.
- **Background Service**: Powered by `flutter_foreground_task` — the MQTT client stays alive even when the phone screen is off or the app is in the background.
- **Lifecycle-Aware**: The background service automatically shuts down when the app is dismissed from the recents list, preserving battery life.

### 🎨 Modern UI/UX (Slate-Teal Palette)

- Premium Neubrutalism-inspired design with Slate, Navy, and Teal accent colors.
- Micro-animations: tactile spring button presses, 180° card rotation transitions, smooth expand/collapse.
- AI Assistant page styled like a modern chat messenger with adaptive message bubbles and active model status.

### 🛠️ Custom Device & Widget Creator

- Instantly create **Sensor**, **Switch**, or **Button** widgets via the `+` menu from inside any device page.
- **Long-press** any widget card to rename or delete it via an interactive dialog.
- Test without physical hardware using the built-in **Demo Mode**, which auto-generates realistic sensor waveforms.

### 📱 Dynamic Device Info & External Links

- Shows accurate hardware specs (OS Version, Device Model, CPU Cores) via `device_info_plus`.
- Opens the GitHub repository directly from the _About & Version_ section via `url_launcher`.

### 🔒 Secure Storage

- Sensitive settings (API Key, MQTT credentials) are encrypted at rest using `flutter_secure_storage`.
- Network security config restricts cleartext traffic to known local IP ranges only.

---

## 📡 MQTT Auto-Discovery Protocol

Iuno uses a **dynamic MQTT Auto-Discovery** system. Your ESP32 simply publishes a JSON configuration payload once when it connects to the MQTT broker. The Iuno app detects this automatically and renders the correct sensor/switch widgets — no Flutter code changes required.

### Discovery Topic Pattern

ESP32 publishes its configuration to:

```
iuno/<device_id>/discovery/<widget_id>
```

The Flutter app subscribes to the wildcard pattern:

```
iuno/+/discovery/#
```

### Discovery Payload Format

```json
{
  "id": "esp32_temp_sensor",
  "type": "sensor | switch | button",
  "name": "DHT22 Temperature",
  "unit": "°C",
  "state_topic": "iuno/esp32/temp",
  "command_topic": ""
}
```

| Field           | Required | Description                                                    |
| --------------- | -------- | -------------------------------------------------------------- |
| `id`            | ✅       | Unique widget identifier (max 64 chars)                        |
| `type`          | ✅       | `sensor`, `switch`, or `button`                                |
| `name`          | ✅       | Widget display title (max 100 chars)                           |
| `unit`          | ❌       | Unit of measurement (sensors only, e.g. `°C`, `%`)             |
| `state_topic`   | ✅       | Topic where the device publishes its current state/value       |
| `command_topic` | ❌       | Topic where the app sends ON/OFF commands (switch/button only) |

### Rediscover Signal

When the Iuno app launches or reconnects to the broker, it sends a `"rediscover"` message to:

```
iuno/device/cmd
```

**Every ESP32 must subscribe to this topic** and immediately re-publish its discovery payload when it receives this signal. This ensures the dashboard auto-populates correctly after a reconnection.

---

## ⚙️ ESP32 Firmware Setup

### Option A — Local Broker (Standard, No TLS)

This is the quickest setup for development on a local network (e.g. using Mosquitto on your laptop or a Raspberry Pi).

**Required Arduino Libraries:**

- `PubSubClient` by Nick O'Leary
- `ArduinoJson` by Benoît Blanchon

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// ─── 1. Wi-Fi Configuration ───────────────────────────────────────
const char* ssid     = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// ─── 2. MQTT Broker Configuration ─────────────────────────────────
// Must match the IP you set in the Iuno app's System Settings
const char* mqtt_server = "192.168.10.3";
const int   mqtt_port   = 1883;

// ─── 3. Hardware Pins ─────────────────────────────────────────────
const int RELAY_PIN = 2; // Onboard LED / Relay pin

WiFiClient   espClient;
PubSubClient client(espClient);
unsigned long lastMsg = 0;

// ─── Wi-Fi Setup ──────────────────────────────────────────────────
void setup_wifi() {
  Serial.print("Connecting to Wi-Fi");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWi-Fi connected! IP: " + WiFi.localIP().toString());
}

// ─── Auto-Discovery Publisher ──────────────────────────────────────
// Call this once on connect to register all widgets in the Iuno app
void publishDiscovery() {
  Serial.println("Publishing Auto-Discovery config...");

  // Widget 1: Temperature Sensor
  StaticJsonDocument<256> docTemp;
  docTemp["id"]            = "esp32_temp_dht22";
  docTemp["type"]          = "sensor";
  docTemp["name"]          = "DHT22 Temperature";
  docTemp["unit"]          = "°C";
  docTemp["state_topic"]   = "iuno/esp32/temp";
  docTemp["command_topic"] = "";
  char bufTemp[256];
  serializeJson(docTemp, bufTemp);
  client.publish("iuno/esp32/discovery/temp", bufTemp);

  // Widget 2: Humidity Sensor
  StaticJsonDocument<256> docHum;
  docHum["id"]            = "esp32_hum_dht22";
  docHum["type"]          = "sensor";
  docHum["name"]          = "DHT22 Humidity";
  docHum["unit"]          = "%";
  docHum["state_topic"]   = "iuno/esp32/humidity";
  docHum["command_topic"] = "";
  char bufHum[256];
  serializeJson(docHum, bufHum);
  client.publish("iuno/esp32/discovery/hum", bufHum);

  // Widget 3: Relay Switch
  StaticJsonDocument<256> docRelay;
  docRelay["id"]            = "esp32_relay_switch";
  docRelay["type"]          = "switch";
  docRelay["name"]          = "Relay Switch";
  docRelay["unit"]          = "";
  docRelay["state_topic"]   = "iuno/esp32/relay/state";
  docRelay["command_topic"] = "iuno/esp32/relay/cmd";
  char bufRelay[256];
  serializeJson(docRelay, bufRelay);
  client.publish("iuno/esp32/discovery/relay", bufRelay);
}

// ─── Incoming Message Handler ──────────────────────────────────────
void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (int i = 0; i < length; i++) message += (char)payload[i];

  Serial.println("Message [" + String(topic) + "]: " + message);

  // Respond to app rediscovery request
  if (String(topic) == "iuno/device/cmd" && message == "rediscover") {
    publishDiscovery();
  }

  // Respond to relay switch commands from the Iuno app
  if (String(topic) == "iuno/esp32/relay/cmd") {
    if (message == "ON") {
      digitalWrite(RELAY_PIN, HIGH);
      client.publish("iuno/esp32/relay/state", "ON");
    } else if (message == "OFF") {
      digitalWrite(RELAY_PIN, LOW);
      client.publish("iuno/esp32/relay/state", "OFF");
    }
  }
}

// ─── MQTT Reconnection Loop ────────────────────────────────────────
void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT... ");
    String clientId = "ESP32-" + String(random(0xffff), HEX);
    if (client.connect(clientId.c_str())) {
      Serial.println("Connected!");
      client.subscribe("iuno/device/cmd");
      client.subscribe("iuno/esp32/relay/cmd");
      publishDiscovery();
    } else {
      Serial.println("Failed (rc=" + String(client.state()) + "). Retrying in 5s...");
      delay(5000);
    }
  }
}

// ─── Arduino Setup ────────────────────────────────────────────────
void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  Serial.begin(115200);
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

// ─── Arduino Loop ─────────────────────────────────────────────────
void loop() {
  if (!client.connected()) reconnect();
  client.loop();

  unsigned long now = millis();
  if (now - lastMsg > 5000) { // Publish sensor data every 5 seconds
    lastMsg = now;

    // Replace these with real DHT22 readings in production
    float temp = 24.0 + random(0, 100) / 20.0;
    float hum  = 58.0 + random(0, 100) / 10.0;

    client.publish("iuno/esp32/temp",     String(temp, 1).c_str());
    client.publish("iuno/esp32/humidity", String(hum, 1).c_str());

    Serial.printf("Telemetry → Temp: %.1f°C | Humidity: %.1f%%\n", temp, hum);
  }
}
```

---

### Option B — HiveMQ Cloud (Secure TLS with Authentication)

HiveMQ Cloud is a popular managed cloud MQTT broker with TLS encryption on port **8883**. Use this setup for production deployments or remote access outside your local network.

**Required changes vs. Option A:**

#### 1. Replace `WiFiClient` with `WiFiClientSecure`

```cpp
#include <WiFiClientSecure.h>  // Replaces <WiFi.h> for TLS support

WiFiClientSecure espClient;    // Secure client instead of plain WiFiClient
PubSubClient     client(espClient);
```

#### 2. Set HiveMQ Credentials

```cpp
// Get your unique cluster host from your HiveMQ Cloud console
const char* mqtt_server = "xxxxxxxxxxxxxxxx.s2.eu.hivemq.cloud";
const int   mqtt_port   = 8883;  // Standard MQTT over TLS port
const char* mqtt_user   = "your_hivemq_username";
const char* mqtt_pass   = "your_hivemq_password";
```

#### 3. Enable Insecure TLS in `setup()` (Skip Root CA Verification)

```cpp
void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  Serial.begin(115200);
  setup_wifi();

  // Skip root certificate verification for simplicity.
  // For production, use espClient.setCACert(root_ca) instead.
  espClient.setInsecure();

  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}
```

#### 4. Add Credentials to `reconnect()`

```cpp
void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting to HiveMQ Cloud... ");
    String clientId = "ESP32Secure-" + String(random(0xffff), HEX);

    // Pass username & password for HiveMQ authentication
    if (client.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
      Serial.println("Securely connected!");
      client.subscribe("iuno/device/cmd");
      client.subscribe("iuno/esp32/relay/cmd");
      publishDiscovery();
    } else {
      Serial.println("Failed (rc=" + String(client.state()) + "). Retrying in 5s...");
      delay(5000);
    }
  }
}
```

> **In the Iuno app's System Settings:**
>
> - Select the **HiveMQ Cloud** preset.
> - Paste your cluster host into the **TLS Host** field.
> - Enter the same username and password you set in your HiveMQ console.
> - Enable the **Secure Connection (TLS)** toggle.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.11
- Android device or emulator running **API 21 (Android 5.0)** or higher
- An MQTT broker (local Mosquitto or HiveMQ Cloud)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/WilyArd/Iuno-Project.git

# 2. Enter the project directory
cd Iuno-Project

# 3. Install Flutter dependencies
flutter pub get

# 4. Run the app on a connected Android device or emulator
flutter run
```

### Build a Release APK (ARM64 only)

To build a production-ready APK optimized for modern ARM64 Android devices:

```bash
flutter build apk --release --target-platform android-arm64
```

The output file will be at:

```
build/app/outputs/flutter-apk/app-release.apk
```

> Using `--target-platform android-arm64` produces a smaller APK (~20 MB) by excluding 32-bit and x86 native libraries.

---

## 🤖 Automated Releases with GitHub Actions

This repository is configured with a GitHub Actions workflow that automatically builds and publishes an ARM64 APK to **GitHub Releases** whenever you push a new version tag.

### How to Release a New Version

```bash
# 1. Create and push a new version tag (use semantic versioning)
git tag v1.0.1-beta.2
git push origin v1.0.1-beta.2
```

That's it. GitHub Actions will:

1. Check out the code.
2. Set up Java 17 and the Flutter stable SDK.
3. Run `flutter pub get`.
4. Build the ARM64 release APK.
5. Create a new **GitHub Release** (marked as pre-release for beta tags) and upload `iuno-arm64-release.apk` as a downloadable asset.

Monitor the build progress in the **Actions** tab of this repository.

---

## 🧰 Technology Stack

| Package                     | Purpose                                            |
| --------------------------- | -------------------------------------------------- |
| **Flutter / Dart**          | Cross-platform UI framework (min Android API 21)   |
| **GetX**                    | State management, routing, and reactive UI         |
| **mqtt_client**             | MQTT protocol client for IoT connectivity          |
| **flutter_foreground_task** | Background service to keep MQTT alive              |
| **flutter_secure_storage**  | Encrypted local storage for sensitive credentials  |
| **fl_chart**                | Real-time telemetry chart rendering                |
| **device_info_plus**        | Dynamic hardware/OS specification detection        |
| **shared_preferences**      | Local storage for broker config and custom widgets |
| **google_fonts**            | Modern typography (Space Grotesk & Outfit)         |
| **url_launcher**            | Open external links in the device browser          |
| **http**                    | HTTP client for AI API provider requests           |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── layouts/          # Main app layout (desktop + mobile)
│   └── services/         # MQTT service & foreground task
├── features/
│   ├── analytics/        # Live trends and telemetry charts
│   ├── assistant/        # AI chat assistant
│   ├── dashboard/        # Device cards, widget grid, models
│   ├── splash/           # Splash/loading screen
│   └── system/           # Settings, broker config, about page
└── main.dart             # App entry point
```

---

## 🔐 Security Notes

- **Cleartext traffic** is restricted to known local IP ranges (`192.168.x.x`, `10.0.0.x`, `localhost`) via Android Network Security Config.
- **API keys and MQTT passwords** are stored using `flutter_secure_storage` (Android Keystore encryption), not in plain SharedPreferences.
- **TLS certificate validation bypass** (`onBadCertificate`) is gated behind `kDebugMode` only and does not affect release builds.
- **MQTT topic validation** prevents wildcard injection (`#`, `+`) in discovery payloads.
