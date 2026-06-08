# Iuno IoT Dashboard

> A real-time Flutter IoT dashboard that auto-discovers ESP32 sensors via MQTT.

---

## ✨ What It Does

- **Auto-discovers** ESP32 devices — no app code changes needed
- **Real-time charts** for sensor data (temperature, humidity, etc.)
- **Switch/Relay control** from your phone
- **Works with any sensor** — DHT11, DHT22, BMP280, soil moisture, etc.
- **Supports local broker** (Mosquitto) and **cloud broker** (HiveMQ Cloud / TLS)
- **Background MQTT** keeps the connection alive with screen off

---

## 📱 Quick Start (App)

```bash
git clone https://github.com/WilyArd/Iuno-Project.git
cd Iuno-Project
flutter pub get
flutter run
```

> Requires Flutter ≥ 3.11 and Android API 21+.

**Configure the broker in-app:**
1. Open the app → go to **System** tab
2. Under **MQTT Broker**, enter your broker host and port
3. Tap **Save Settings** then **Connect Now**

---

## 📡 How Auto-Discovery Works

When the ESP32 connects to the broker, it publishes a small JSON config message.
The Iuno app picks it up and **automatically creates the sensor widget** — no restart needed.

**Topic pattern the ESP32 publishes to:**
```
iuno/<device_id>/discovery/<widget_id>
```

**Discovery payload format:**
```json
{
  "id": "unique_widget_id",
  "type": "sensor",
  "name": "Widget Display Name",
  "unit": "°C",
  "state_topic": "iuno/mydevice/temperature"
}
```

| Field | Required | Description |
|---|---|---|
| `id` | ✅ | Unique ID (max 64 chars, no spaces recommended) |
| `type` | ✅ | `sensor`, `switch`, or `button` |
| `name` | ✅ | Label shown on the dashboard card |
| `unit` | ❌ | Unit label shown next to the value (e.g. `°C`, `%`, `lux`) |
| `state_topic` | ✅ | Topic where the ESP32 publishes sensor values |
| `command_topic` | ❌ | Topic where the app sends ON/OFF commands (for `switch` only) |

> When the app reconnects, it sends `"rediscover"` to `iuno/device/cmd`.
> Your ESP32 must subscribe to that topic and re-publish discovery on receiving it.

---

## 🔌 ESP32 Setup

### Option A — Local Broker (Mosquitto, no TLS)

**Libraries needed:** `PubSubClient`, `ArduinoJson`

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

const char* ssid        = "YOUR_WIFI_SSID";
const char* password    = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "192.168.10.3"; // Your local broker IP
const int   mqtt_port   = 1883;

WiFiClient   espClient;
PubSubClient client(espClient);

void publishDiscovery() {
  StaticJsonDocument<256> doc;
  char buf[256];

  doc["id"]          = "esp32_temp";
  doc["type"]        = "sensor";
  doc["name"]        = "Temperature";
  doc["unit"]        = "°C";
  doc["state_topic"] = "iuno/esp32/temp";
  serializeJson(doc, buf);
  client.publish("iuno/esp32/discovery/temp", buf);
}

void callback(char* topic, byte* payload, unsigned int length) {
  String msg = "";
  for (int i = 0; i < length; i++) msg += (char)payload[i];
  if (String(topic) == "iuno/device/cmd" && msg == "rediscover") publishDiscovery();
}

void reconnect() {
  while (!client.connected()) {
    if (client.connect(("ESP32-" + String(random(0xffff), HEX)).c_str())) {
      client.subscribe("iuno/device/cmd");
      publishDiscovery();
    } else { delay(5000); }
  }
}

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) delay(500);
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) reconnect();
  client.loop();
  // Publish your sensor value
  client.publish("iuno/esp32/temp", "25.4");
  delay(5000);
}
```

---

### Option B — HiveMQ Cloud (TLS, port 8883)

**Additional library:** `WiFiClientSecure`

```cpp
#include <WiFiClientSecure.h>
#include <PubSubClient.h>

const char* mqtt_server = "xxxx.s2.eu.hivemq.cloud";
const int   mqtt_port   = 8883;
const char* mqtt_user   = "your_username";
const char* mqtt_pass   = "your_password";

WiFiClientSecure espClient;
PubSubClient     client(espClient);

void setup() {
  // ...WiFi setup...
  espClient.setInsecure(); // Skip cert verification (fine for dev)
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void reconnect() {
  while (!client.connected()) {
    if (client.connect("ESP32Secure", mqtt_user, mqtt_pass)) {
      client.subscribe("iuno/device/cmd");
      publishDiscovery();
    } else { delay(5000); }
  }
}
```

**In the Iuno app System settings:** select HiveMQ Cloud preset, enter your cluster host, username & password, and enable the TLS toggle.

---

## 🌡️ Sample: DHT11 Sensor Detection

See [`examples/dht11_sensor/dht11_sensor.ino`](examples/dht11_sensor/dht11_sensor.ino) for the complete ready-to-flash sketch.

It publishes **two widgets** to the Iuno dashboard:
- 🌡️ **Temperature** (°C)
- 💧 **Humidity** (%)

Both appear automatically as separate sensor cards when the ESP32 connects to the broker.

---

## 🚀 Releasing a New Version

Releases are built automatically via GitHub Actions whenever you push a version tag:

```bash
git tag v1.0.1-beta.5
git push origin main
git push origin v1.0.1-beta.5
```

GitHub Actions will build an **ARM64 APK** and publish it as a pre-release on the **Releases** page.

---

## 🧰 Tech Stack

| Package | Purpose |
|---|---|
| GetX | State management & routing |
| mqtt_client | MQTT connectivity |
| flutter_foreground_task | Background MQTT keep-alive |
| flutter_secure_storage | Encrypted credential storage |
| fl_chart | Real-time sensor charts |
| shared_preferences | Device config persistence |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── layouts/       # App shell & navigation
│   └── services/      # MqttService, foreground task
└── features/
    ├── dashboard/     # Device cards, widget models
    ├── analytics/     # Live charts
    ├── assistant/     # AI chat
    └── system/        # Settings & broker config
```
