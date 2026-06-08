/*
 * ─────────────────────────────────────────────────────────────────────────────
 * IUNO IoT Dashboard — DHT11 Sensor Example
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * This sketch publishes DHT11 temperature and humidity readings to the
 * Iuno app via MQTT Auto-Discovery. The app will automatically create
 * two sensor widgets (Temperature and Humidity) on the dashboard.
 *
 * Required Libraries (install via Arduino Library Manager):
 *   - DHT sensor library  by Adafruit
 *   - Adafruit Unified Sensor  by Adafruit
 *   - PubSubClient  by Nick O'Leary
 *   - ArduinoJson  by Benoît Blanchon
 *
 * Wiring:
 *   DHT11 Pin 1 (VCC) → 3.3V or 5V
 *   DHT11 Pin 2 (DATA) → GPIO 4 (with a 10kΩ pull-up to VCC)
 *   DHT11 Pin 4 (GND) → GND
 * ─────────────────────────────────────────────────────────────────────────────
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <DHT.h>

// ── 1. CONFIGURATION ─────────────────────────────────────────────────────────

// Wi-Fi
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// MQTT Broker — must match what you enter in the Iuno app's System settings
// For local Mosquitto: use your PC/Raspberry Pi's LAN IP (e.g. 192.168.1.100)
// For HiveMQ Cloud:   see the HiveMQ Cloud section in README
const char* MQTT_SERVER = "192.168.10.3";
const int   MQTT_PORT   = 1883;
// const char* MQTT_USER = "your_username"; // Uncomment for authenticated brokers
// const char* MQTT_PASS = "your_password"; // Uncomment for authenticated brokers

// DHT11 sensor
#define DHT_PIN  4      // GPIO pin connected to DHT11 data line
#define DHT_TYPE DHT11  // Change to DHT22 if you're using that sensor

// How often to publish sensor data (milliseconds)
const unsigned long PUBLISH_INTERVAL_MS = 5000; // every 5 seconds

// ── 2. INTERNAL — don't change below this line ────────────────────────────────

DHT          dht(DHT_PIN, DHT_TYPE);
WiFiClient   espClient;
PubSubClient client(espClient);
unsigned long lastPublishTime = 0;

// ── MQTT Auto-Discovery ───────────────────────────────────────────────────────
// Tells the Iuno app what widgets to create on the dashboard.
// Called once after connecting, and again whenever the app sends "rediscover".
void publishDiscovery() {
  Serial.println("[MQTT] Publishing Auto-Discovery...");
  char buf[256];
  StaticJsonDocument<256> doc;

  // Widget 1: Temperature
  doc.clear();
  doc["id"]          = "dht11_temperature";
  doc["type"]        = "sensor";
  doc["name"]        = "DHT11 Temperature";
  doc["unit"]        = "\u00b0C";           // °C (unicode escaped for C++ safety)
  doc["state_topic"] = "iuno/dht11/temperature";
  serializeJson(doc, buf);
  client.publish("iuno/dht11/discovery/temperature", buf, true); // retained=true
  Serial.println("[MQTT] Discovery → Temperature widget registered");

  // Widget 2: Humidity
  doc.clear();
  doc["id"]          = "dht11_humidity";
  doc["type"]        = "sensor";
  doc["name"]        = "DHT11 Humidity";
  doc["unit"]        = "%";
  doc["state_topic"] = "iuno/dht11/humidity";
  serializeJson(doc, buf);
  client.publish("iuno/dht11/discovery/humidity", buf, true); // retained=true
  Serial.println("[MQTT] Discovery → Humidity widget registered");
}

// ── MQTT Incoming Message Handler ────────────────────────────────────────────
// The Iuno app sends "rediscover" to iuno/device/cmd when it reconnects.
// ESP32 must respond by re-publishing its discovery payload.
void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) message += (char)payload[i];

  Serial.printf("[MQTT] Message received [%s]: %s\n", topic, message.c_str());

  if (String(topic) == "iuno/device/cmd" && message == "rediscover") {
    Serial.println("[MQTT] Rediscover request received — republishing discovery...");
    publishDiscovery();
  }
}

// ── Wi-Fi Connection ──────────────────────────────────────────────────────────
void connectWiFi() {
  Serial.printf("[WiFi] Connecting to %s", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.printf("\n[WiFi] Connected! IP: %s\n", WiFi.localIP().toString().c_str());
}

// ── MQTT Connection & Reconnect Loop ─────────────────────────────────────────
void connectMQTT() {
  while (!client.connected()) {
    String clientId = "ESP32-DHT11-" + String(random(0xffff), HEX);
    Serial.printf("[MQTT] Connecting as %s to %s:%d ...\n",
                  clientId.c_str(), MQTT_SERVER, MQTT_PORT);

    bool connected = client.connect(clientId.c_str());
    // If using authentication:
    // bool connected = client.connect(clientId.c_str(), MQTT_USER, MQTT_PASS);

    if (connected) {
      Serial.println("[MQTT] Connected! ✓");

      // Subscribe to the rediscover command topic
      client.subscribe("iuno/device/cmd");

      // Announce widgets to the Iuno app immediately
      publishDiscovery();
    } else {
      Serial.printf("[MQTT] Failed (rc=%d). Retrying in 5s...\n", client.state());
      delay(5000);
    }
  }
}

// ── Arduino Setup ─────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n=== IUNO DHT11 Sensor Node ===");

  dht.begin();
  connectWiFi();

  client.setServer(MQTT_SERVER, MQTT_PORT);
  client.setCallback(onMqttMessage);
}

// ── Arduino Loop ──────────────────────────────────────────────────────────────
void loop() {
  // Maintain MQTT connection
  if (!client.connected()) connectMQTT();
  client.loop();

  // Publish sensor readings on interval
  unsigned long now = millis();
  if (now - lastPublishTime >= PUBLISH_INTERVAL_MS) {
    lastPublishTime = now;

    float temperature = dht.readTemperature(); // Celsius
    float humidity    = dht.readHumidity();    // Percent

    // Validate readings — DHT11 can return NaN on read error
    if (isnan(temperature) || isnan(humidity)) {
      Serial.println("[DHT11] Read error — check wiring and pull-up resistor!");
      return;
    }

    // Publish to state topics (plain numeric value as string)
    String tempStr = String(temperature, 1); // e.g. "28.5"
    String humStr  = String(humidity, 1);    // e.g. "65.0"

    client.publish("iuno/dht11/temperature", tempStr.c_str());
    client.publish("iuno/dht11/humidity",    humStr.c_str());

    Serial.printf("[DHT11] Published → Temp: %s°C | Humidity: %s%%\n",
                  tempStr.c_str(), humStr.c_str());
  }
}
