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
const char* apiKey = "sb_publishable_C6eynsUVAhJmRfTjC5i4QQ_oikzrVQa"; 

// IMPORTANT: Replace this with the actual device token you got from registering your device in the app
// When you register a device in the SafeHajj app, you'll see a long token - copy it and paste it here
const char* deviceSecret = "trLZje3Z4FfZhFFB5ptYxLGZm6WN9Jk2Y8B20ge-HJFOv8Ktp0zTh2E6pyEgtv4L"; 

// --- PINS ---
#define RX_PIN 2      // GPS TX -> Pin 2
#define TX_PIN 1      // GPS RX -> Pin 1
#define GPS_BAUD 9600
#define SDA_PIN 4     // MAX30102 SDA
#define SCL_PIN 5     // MAX30102 SCL
#define PANIC_BUTTON_PIN 13  // Panic button connected to GPIO 13 (ESP32 Mini)

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

// Panic button variables
bool panicButtonPressed = false;
unsigned long lastDebounceTime = 0;
unsigned long debounceDelay = 50;  // 50ms debounce time
int lastButtonState = HIGH;
int buttonState = HIGH;

void setup() {
  Serial.begin(115200);
  while (!Serial); // Wait for serial monitor to open
  delay(1000);  // Give it a second to stabilize
  
  // Print continuously until Serial Monitor is definitely open
  for(int i = 0; i < 10; i++) {
    Serial.println("\n\n==========================================");
    Serial.println("🚀 ESP32 STARTING UP...");
    Serial.println("==========================================");
    delay(500);
  }

  // INIT PANIC BUTTON FIRST (before anything else that might fail)
  Serial.println("Step 1: Initializing panic button on GPIO 13...");
  pinMode(PANIC_BUTTON_PIN, INPUT_PULLUP);
  delay(100);
  int testReading = digitalRead(PANIC_BUTTON_PIN);
  Serial.print("   Button reading: ");
  Serial.println(testReading);
  Serial.println(testReading == HIGH ? "   ✓ Button OK (HIGH)" : "   ⚠ Button shows LOW");
  Serial.println("Step 1: COMPLETE\n");

  // 1. Init GPS
  Serial.println("Step 2: Initializing GPS...");
  gpsSerial.begin(GPS_BAUD, SERIAL_8N1, RX_PIN, TX_PIN);
  Serial.println("Step 2: COMPLETE\n");

  // 2. Init MAX30102
  Serial.println("Step 3: Initializing MAX30102 sensor...");
  Wire.begin(SDA_PIN, SCL_PIN);
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 not found. Check wiring.");
    while (1);
  }
  particleSensor.setup(); 
  particleSensor.setPulseAmplitudeRed(0x0A); 
  particleSensor.setPulseAmplitudeGreen(0);
  particleSensor.enableDIETEMPRDY();
  Serial.println("Step 3: COMPLETE\n");

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
  // --- CHECK PANIC BUTTON (with debouncing) ---
  int reading = digitalRead(PANIC_BUTTON_PIN);
  
  // Debug: Print button state every 2 seconds (more frequent for testing)
  static unsigned long lastButtonDebug = 0;
  if (millis() - lastButtonDebug > 2000) {
    Serial.println("==========================================");
    Serial.print("🔘 PANIC BUTTON STATUS: ");
    Serial.println(reading == HIGH ? "HIGH (not pressed)" : "LOW (PRESSED!)");
    Serial.print("   GPIO 13 pin reading: ");
    Serial.println(reading);
    Serial.println("==========================================");
    lastButtonDebug = millis();
  }
  
  // If the button state changed (due to noise or pressing)
  if (reading != lastButtonState) {
    lastDebounceTime = millis();
    Serial.print("Button change detected: ");
    Serial.println(reading == HIGH ? "HIGH" : "LOW");
  }
  
  // If enough time has passed since the last state change
  if ((millis() - lastDebounceTime) > debounceDelay) {
    // If the button state has changed
    if (reading != buttonState) {
      buttonState = reading;
      
      // If button is pressed (LOW because of pull-up resistor)
      if (buttonState == LOW) {
        panicButtonPressed = true;
        Serial.println("⚠️⚠️⚠️ PANIC BUTTON PRESSED! ⚠️⚠️⚠️");
        Serial.println("Panic flag set to TRUE");
      } else {
        Serial.println("Button released (HIGH)");
      }
    }
  }
  lastButtonState = reading;

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

  // --- SEND PANIC ALERT IMMEDIATELY ---
  if (panicButtonPressed) {
    Serial.println("Sending panic alert to cloud...");
    sendDataToCloud(beatAvg, irValue, temperature, true);
    panicButtonPressed = false;  // Reset the flag
    delay(1000);  // Prevent multiple rapid alerts
  }

  // --- SEND DATA TO SUPABASE (Every 10 Seconds) ---
  static unsigned long lastSend = 0;
  if (millis() - lastSend > 10000) {
    
    // We send data if we have a heartbeat OR a GPS lock
    if (irValue > 50000 || gps.location.isValid()) {
      sendDataToCloud(beatAvg, irValue, temperature, false);
    } else {
      Serial.println("Idle: No finger & No GPS fix yet.");
    }
    lastSend = millis();
  }
}

void sendDataToCloud(int bpm, long ir, float temp, bool isPanicAlert) {
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
    
    // Construct the JSON for the RPC function
    StaticJsonDocument<400> doc;  // Increased size to accommodate panic flag
    doc["p_device_key"] = deviceSecret;
    
    // The "p_payload" is a nested JSON object containing our sensor data
    JsonObject payload = doc.createNestedObject("p_payload");
    payload["heart_rate"] = bpm;  // Changed from "bpm" to match app expectations
    payload["ir"] = ir;
    payload["temperature"] = temp;  // Body/sensor temperature in Celsius
    payload["battery"] = 85;  // You can add actual battery reading here
    payload["panic_alert"] = isPanicAlert;  // Add panic alert flag
    
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

    if (isPanicAlert) {
      Serial.println("🚨 SENDING PANIC ALERT: " + requestBody);
    } else {
      Serial.println("Sending: " + requestBody);
    }
    
    int httpCode = http.POST(requestBody);
    
    if(httpCode > 0) {
      Serial.print("Data Sent! Code: "); Serial.println(httpCode);
      String response = http.getString();
      Serial.println("Response: " + response);
      if (isPanicAlert) {
        Serial.println("✓ Panic alert successfully sent to admin!");
      }
    } else {
      Serial.print("Error: "); Serial.println(httpCode);
      if (isPanicAlert) {
        Serial.println("✗ Failed to send panic alert!");
      }
    }
    http.end();
  }
}
