#include <WiFi.h>
#include <HTTPClient.h>
#include <TinyGPS++.h>
#include <HardwareSerial.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include "MAX30105.h" 
#include "heartRate.h"

// ==========================================
// 1. CONFIGURATION
// ==========================================
const char* ssid = "Idamannetizan_5GHz";
const char* password = "99000203";

// Your Supabase URL + The RPC function path
const char* serverUrl = "https://ojzmzxokwzwiccbgkuxf.supabase.co/rest/v1/rpc/rpc_insert_device_payload";
const char* apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qem16eG9rd3p3aWNjYmdrdXhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyNDIwMzAsImV4cCI6MjA3NzgxODAzMH0.lVr70zs6t0d7xInKVTbuxQ5R11H3fie__5vsGTpSRkw"; 

// IMPORTANT: Replace this with the actual device token you got from registering your device in the app
// When you register a device in the SafeHajj app, you'll see a long token - copy it and paste it here
const char* deviceSecret = "REPLACE_WITH_YOUR_ACTUAL_DEVICE_TOKEN_FROM_APP"; 

// --- PINS ---
#define RX_PIN 2      // GPS TX -> Pin 2
#define TX_PIN 1      // GPS RX -> Pin 1
#define GPS_BAUD 9600
#define SDA_PIN 4     // MAX30102 SDA
#define SCL_PIN 5     // MAX30102 SCL

// --- OBJECTS ---
TinyGPSPlus gps;
HardwareSerial gpsSerial(1);
MAX30105 particleSensor;

// --- VARIABLES ---
const byte RATE_SIZE = 4; 
byte rates[RATE_SIZE]; 
byte rateSpot = 0;
long lastBeat = 0; 
int beatAvg = 0;
float temperature = 0.0;

void setup() {
  Serial.begin(115200);
  delay(1000);

  // 1. Init GPS
  gpsSerial.begin(GPS_BAUD, SERIAL_8N1, RX_PIN, TX_PIN);

  // 2. Init MAX30102
  Wire.begin(SDA_PIN, SCL_PIN);
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 not found. Check wiring.");
    while (1);
  }
  particleSensor.setup(); 
  particleSensor.setPulseAmplitudeRed(0x0A); 
  particleSensor.setPulseAmplitudeGreen(0);
  
  // Enable temperature reading
  particleSensor.enableDIETEMPRDY(); 

  // 3. Init WiFi
  Serial.println("Connecting to WiFi...");
  Serial.print("SSID: ");
  Serial.println(ssid);
  
  WiFi.mode(WIFI_STA);  // Set WiFi to station mode
  WiFi.disconnect();     // Disconnect from any previous connection
  delay(100);
  
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 40) {  // 20 second timeout
    delay(500);
    Serial.print(".");
    attempts++;
    
    if (attempts % 10 == 0) {
      Serial.println();
      Serial.print("Still trying... Signal strength: ");
      Serial.println(WiFi.RSSI());
    }
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✓ WiFi Connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Signal Strength (RSSI): ");
    Serial.println(WiFi.RSSI());
  } else {
    Serial.println("\n✗ WiFi Connection Failed!");
    Serial.println("Possible issues:");
    Serial.println("1. Wrong WiFi name or password");
    Serial.println("2. 5GHz WiFi - ESP32 may not support all 5GHz channels");
    Serial.println("3. WiFi out of range");
    Serial.println("\nTrying to continue anyway...");
  }
}

void loop() {
  // --- READ SENSORS ---
  long irValue = particleSensor.getIR();
  
  // Heart Rate Math
  if (checkForBeat(irValue) == true) {
    long delta = millis() - lastBeat;
    lastBeat = millis();
    float beatsPerMinute = 60 / (delta / 1000.0);
    if (beatsPerMinute < 255 && beatsPerMinute > 20) {
      rates[rateSpot++] = (byte)beatsPerMinute; 
      rateSpot %= RATE_SIZE; 
      beatAvg = 0;
      for (byte x = 0 ; x < RATE_SIZE ; x++) beatAvg += rates[x];
      beatAvg /= RATE_SIZE;
    }
  }

  // Read GPS
  while (gpsSerial.available() > 0) gps.encode(gpsSerial.read());

  // Read Temperature (every loop iteration)
  temperature = particleSensor.readTemperature();

  // --- SEND DATA TO SUPABASE (Every 10 Seconds) ---
  static unsigned long lastSend = 0;
  if (millis() - lastSend > 10000) {
    
    // We send data if we have a heartbeat OR a GPS lock
    if (irValue > 50000 || gps.location.isValid()) {
      sendDataToCloud(beatAvg, irValue, temperature);
    } else {
      Serial.println("Idle: No finger & No GPS fix yet.");
    }
    lastSend = millis();
  }
}

void sendDataToCloud(int bpm, long ir, float temp) {
  // Check WiFi and reconnect if needed
  if(WiFi.status() != WL_CONNECTED){
    Serial.println("WiFi disconnected. Reconnecting...");
    WiFi.disconnect();
    WiFi.begin(ssid, password);
    int retries = 0;
    while (WiFi.status() != WL_CONNECTED && retries < 20) {
      delay(500);
      Serial.print(".");
      retries++;
    }
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("\nReconnection failed. Skipping this data send.");
      return;
    }
    Serial.println("\nReconnected!");
  }
  
  if(WiFi.status() == WL_CONNECTED){
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", apiKey);
    http.addHeader("Authorization", String("Bearer ") + apiKey);
    
    // Construct the JSON for the RPC function
    StaticJsonDocument<300> doc;
    doc["p_device_key"] = deviceSecret;
    
    // The "p_payload" is a nested JSON object containing our sensor data
    JsonObject payload = doc.createNestedObject("p_payload");
    payload["heart_rate"] = bpm;  // Changed from "bpm" to match app expectations
    payload["ir"] = ir;
    payload["temperature"] = temp;  // Body/sensor temperature in Celsius
    payload["battery"] = 85;  // You can add actual battery reading here
    
    if (gps.location.isValid()) {
      payload["latitude"] = gps.location.lat();   // Changed from "lat"
      payload["longitude"] = gps.location.lng();  // Changed from "lng"
      payload["speed"] = gps.speed.kmph();
    } else {
      payload["latitude"] = 0.0;
      payload["longitude"] = 0.0;
    }

    String requestBody;
    serializeJson(doc, requestBody);

    Serial.println("Sending: " + requestBody);
    
    int httpCode = http.POST(requestBody);
    
    if(httpCode > 0) {
      Serial.print("Data Sent! Code: "); Serial.println(httpCode);
      String response = http.getString();
      Serial.println("Response: " + response);
    } else {
      Serial.print("Error: "); Serial.println(httpCode);
    }
    http.end();
  }
}
