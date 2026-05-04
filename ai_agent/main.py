import paho.mqtt.client as mqtt
import time
import json
import random

BROKER = "broker.emqx.io"
PORT = 1883
CLIENT_ID = f"iuno_ai_agent_{random.randint(1000, 9999)}"

# Topics to subscribe
TOPIC_SUHU = "+/sensor/suhu"
TOPIC_KELEMBABAN = "+/sensor/kelembaban"

# Topics to publish
TARGET_SUHU = "iuno/ai/target/suhu"
TARGET_KELEMBABAN = "iuno/ai/target/kelembaban"

# Basic AI logic (Fuzzy/Rules-based simulation)
def calculate_target_suhu(current_suhu):
    # Jika suhu panas banget, targetkan AC ke suhu nyaman
    if current_suhu > 28.0:
        return 24.0
    # Jika suhu sudah dingin, targetkan sedikit lebih tinggi agar hemat energi
    elif current_suhu < 22.0:
        return 25.0
    else:
        # Jika sudah nyaman, pertahankan
        return current_suhu

def calculate_target_kelembaban(current_kelembaban):
    # Jika kelembaban tinggi (pengap), targetkan lebih rendah
    if current_kelembaban > 70.0:
        return 50.0
    # Jika kelembaban sangat kering, targetkan lebih tinggi
    elif current_kelembaban < 40.0:
        return 55.0
    else:
        # Jika sudah optimal, pertahankan
        return current_kelembaban

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("AI Agent: Connected to MQTT Broker!")
        client.subscribe(TOPIC_SUHU)
        client.subscribe(TOPIC_KELEMBABAN)
        print(f"AI Agent: Subscribed to {TOPIC_SUHU} and {TOPIC_KELEMBABAN}")
    else:
        print(f"AI Agent: Failed to connect, return code {rc}")

def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode("utf-8")
        topic = msg.topic
        print(f"[{topic}] Received: {payload}")
        
        # Ekstrak nilai float dari payload
        value = float(payload)
        
        # Eksekusi AI Logic berdasarkan tipe sensor
        if "suhu" in topic:
            target = calculate_target_suhu(value)
            print(f"  -> [AI Decision] Target Suhu: {target}°C")
            client.publish(TARGET_SUHU, str(target))
            
        elif "kelembaban" in topic:
            target = calculate_target_kelembaban(value)
            print(f"  -> [AI Decision] Target Kelembaban: {target}%")
            client.publish(TARGET_KELEMBABAN, str(target))
            
    except ValueError:
        print(f"Error parsing value from payload: {msg.payload}")
    except Exception as e:
        print(f"Error processing message: {e}")

if __name__ == "__main__":
    print("Starting AI Agent...")
    client = mqtt.Client(CLIENT_ID)
    client.on_connect = on_connect
    client.on_message = on_message
    
    try:
        client.connect(BROKER, PORT, 60)
        # Loop forever
        client.loop_forever()
    except KeyboardInterrupt:
        print("\nAI Agent Stopped.")
        client.disconnect()
    except Exception as e:
        print(f"Connection failed: {e}")
