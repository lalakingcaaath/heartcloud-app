#include <WiFi.h>
#include <WebServer.h> // Using WebServer library
#include <SPI.h>
#include <SD.h>

// --- Configuration for Audio ---
#define MIC_PIN 36                  // ADC pin for MAX4466
const uint32_t SAMPLE_RATE = 2000;    // Sample rate for audio (Hz)
// DURATION_SECONDS and AUDIO_DATA_SIZE are no longer const, will be set by user
uint32_t currentSelectedDurationSeconds = 30; // Default/initial duration
uint32_t currentAudioDataSize = SAMPLE_RATE * currentSelectedDurationSeconds;

// --- Configuration for SD Card ---
#define SD_CS_PIN 13                  // Chip Select pin for SD card module
const char* audioFilename = "/audio.wav"; // Filename on the SD card (will be overwritten)

// --- Configuration for Battery Monitor ---
const int batteryPin = 34;            // ADC pin for battery voltage

// --- Common Configuration (WiFi & Server) ---
const char* ssid = "GlobeAtHome_Fiber"; // << YOUR WIFI SSID >>
const char* password = "macmac62259";   // << YOUR WIFI PASSWORD >>
WebServer server(80);                 // Web server object on port 80

File recordingFile; // Global File object for the recording

// --- State Variables for Recording Control ---
bool recordingHasBeenStarted = false;
bool recordingIsFinished = false;

// --- Function Declarations ---
void connectWiFi();
void recordAudioToSD(uint32_t samplesToRecord); // Modified
void sendWAVHeaderToClient(Client& client);
int voltage_to_percentage(float voltage);
void handleRoot();
void handleStartRecording();
void handleAudioWAV();
void handleBattery();

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(MIC_PIN, INPUT);
  pinMode(batteryPin, INPUT);

  Serial.println("Initializing SPI bus...");
  SPI.begin(18, 19, 23, SD_CS_PIN);

  Serial.println("Initializing SD card...");
  if (!SD.begin(SD_CS_PIN, SPI)) {
    Serial.println("SD Card Mount Failed!");
    while (1);
  }
  uint64_t cardSize = SD.cardSize() / (1024 * 1024);
  Serial.printf("SD Card Size: %lluMB\n", cardSize);

  connectWiFi();

  server.on("/", HTTP_GET, handleRoot);
  server.on("/start_recording", HTTP_GET, handleStartRecording);
  server.on("/audio.wav", HTTP_GET, handleAudioWAV);
  server.on("/battery", HTTP_GET, handleBattery);

  server.begin();
  Serial.println("HTTP server started. Access it via:");
  Serial.print("IP Address: http://");
  Serial.println(WiFi.localIP());
}

void loop() {
  server.handleClient();
}

void connectWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.print(ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
}

// --- Audio Recording Function (writes to SD Card) ---
void recordAudioToSD(uint32_t samplesToRecord) { // Takes number of samples as argument
  const int baseline = 2048;
  const float gain = 2.0;
  float smoothed = baseline;
  const float alpha = 0.15;

  if (SD.exists(audioFilename)) {
    SD.remove(audioFilename);
    Serial.println("Existing audio file removed.");
  }

  recordingFile = SD.open(audioFilename, FILE_WRITE);
  if (!recordingFile) {
    Serial.println("Failed to open file for writing on SD card!");
    recordingHasBeenStarted = false; // Reset state
    return;
  }

  Serial.printf("Starting audio sampling for %lu seconds (%lu samples)...\n", samplesToRecord / SAMPLE_RATE, samplesToRecord);
  unsigned long startTime = micros();

  for (uint32_t i = 0; i < samplesToRecord; i++) {
    int raw = analogRead(MIC_PIN);
    smoothed = alpha * raw + (1.0 - alpha) * smoothed;
    int diff = (int)((smoothed - baseline) * gain);
    int sample8bit = constrain(diff + 128, 0, 255);
    recordingFile.write((uint8_t)sample8bit);

    if (i > 0 && (i % SAMPLE_RATE == 0)) { // Print progress every second
        uint32_t currentSecond = i / SAMPLE_RATE;
        uint32_t totalSeconds = samplesToRecord / SAMPLE_RATE;
        Serial.printf("Recorded %lu of %lu seconds...\n", currentSecond, totalSeconds);
    }

    unsigned long nextSampleTime = startTime + ((i + 1) * (1000000L / SAMPLE_RATE));
    long waitTime = nextSampleTime - micros();
    if (waitTime > 0) {
      delayMicroseconds(waitTime);
    }
  }
  recordingFile.close();
  Serial.println("Finished recording samples to SD card.");
}

// --- WAV Header Function ---
void sendWAVHeaderToClient(Client& client) {
  // Uses global currentAudioDataSize and SAMPLE_RATE
  uint32_t fileSize = 44 + currentAudioDataSize;
  uint32_t byteRate = SAMPLE_RATE * 1 * 8 / 8;
  uint16_t blockAlign = 1 * 8 / 8;
  uint16_t bitsPerSample = 8;
  uint16_t numChannels = 1;
  uint16_t audioFormat = 1;

  client.write((const uint8_t*)"RIFF", 4);
  client.write((uint8_t*)&fileSize, 4);
  client.write((const uint8_t*)"WAVE", 4);
  client.write((const uint8_t*)"fmt ", 4);
  uint32_t subChunk1Size = 16;
  client.write((uint8_t*)&subChunk1Size, 4);
  client.write((uint8_t*)&audioFormat, 2);
  client.write((uint8_t*)&numChannels, 2);
  client.write((uint8_t*)&SAMPLE_RATE, 4); // Global const
  client.write((uint8_t*)&byteRate, 4);
  client.write((uint8_t*)&blockAlign, 2);
  client.write((uint8_t*)&bitsPerSample, 2);
  client.write((const uint8_t*)"data", 4);
  client.write((uint8_t*)&currentAudioDataSize, 4); // Uses the current dynamic size
}

int voltage_to_percentage(float voltage) {
  if (voltage >= 4.2) return 100;
  if (voltage <= 3.0) return 0;
  return (int)(((voltage - 3.0) / (4.2 - 3.0)) * 100.0);
}

// --- Web Server Route Handlers ---
void handleRoot() {
  String html = "<html><head><title>ESP32 Server</title>";
  if (recordingHasBeenStarted && !recordingIsFinished) {
    html += "<meta http-equiv='refresh' content='5'>"; // Auto-refresh if recording
  }
  html += "<style>";
  html += ".button { padding: 10px 15px; color: white; text-decoration: none; border-radius: 5px; margin-right: 10px; display: inline-block; margin-bottom: 10px; }";
  html += ".green { background-color: green; }";
  html += ".blue { background-color: blue; }";
  html += ".orange { background-color: orange; }";
  html += "</style>";
  html += "</head><body>";
  html += "<h1>ESP32 Audio Recorder</h1>";

  if (!recordingHasBeenStarted || recordingIsFinished) { // Show options if not started or if finished (for re-recording)
    if (recordingIsFinished) {
        html += "<p><a href=\"/audio.wav\" class='button blue'>Download Last Recording (" + String(currentSelectedDurationSeconds) + "s)</a></p>";
        html += "<h3>Record New Audio:</h3>";
    } else {
        html += "<h3>Start New Audio Recording:</h3>";
    }
    html += "<p>";
    html += "<a href=\"/start_recording?duration=15\" class='button green'>Record 15 seconds</a>";
    html += "<a href=\"/start_recording?duration=30\" class='button green'>Record 30 seconds</a>";
    html += "<a href=\"/start_recording?duration=45\" class='button green'>Record 45 seconds</a>";
    html += "<a href=\"/start_recording?duration=60\" class='button green'>Record 1 minute</a>";
    html += "</p>";
  } else if (recordingHasBeenStarted && !recordingIsFinished) {
    html += "<p><strong>Recording in progress for " + String(currentSelectedDurationSeconds) + " seconds... Please wait.</strong> This page will refresh automatically.</p>";
  }

  html += "<p>Check <a href=\"/battery\">/battery</a> for battery status.</p>";
  html += "</body></html>";
  server.send(200, "text/html", html);
}

void handleStartRecording() {
  if (recordingHasBeenStarted && !recordingIsFinished) {
    server.send(200, "text/html", "<h1>Recording Already in Progress</h1><p>Please wait until it finishes. <a href='/'>Back to Home</a></p>");
    return;
  }

  if (server.hasArg("duration")) {
    currentSelectedDurationSeconds = server.arg("duration").toInt();
    if (currentSelectedDurationSeconds <= 0) { // Basic validation
        currentSelectedDurationSeconds = 30; // Default to 30 if invalid
    }
  } else {
    currentSelectedDurationSeconds = 30; // Default if no duration is provided
  }
  currentAudioDataSize = SAMPLE_RATE * currentSelectedDurationSeconds; // Calculate actual data size

  Serial.printf("'/start_recording' accessed. Duration: %d seconds. Audio data size: %d bytes.\n", currentSelectedDurationSeconds, currentAudioDataSize);
  
  recordingHasBeenStarted = true;
  recordingIsFinished = false;

  String TTR = String(currentSelectedDurationSeconds);
  String message = "<h1>Recording Commenced</h1>";
  message += "<p>Audio recording for " + TTR + " seconds has started.</p>";
  message += "<p>Please wait. You will be redirected to the home page shortly, or you can <a href='/'>click here to go back</a> where you can see the status.</p>";
  message += "<script>setTimeout(function(){ window.location.href = '/'; }, 3000);</script>";

  server.send(200, "text/html", message);

  recordAudioToSD(currentAudioDataSize); // Pass the calculated number of samples

  recordingIsFinished = true;
  Serial.println("Audio recording to SD card complete (triggered by web).");
}

void handleAudioWAV() {
  Serial.println("Client requested audio.wav");

  if (!recordingIsFinished) {
    Serial.println("Audio recording is not finished or not started yet.");
    server.send(404, "text/plain", "ERROR: Audio not recorded or recording not complete.");
    return;
  }

  File audioFile = SD.open(audioFilename, FILE_READ);
  if (!audioFile) {
    Serial.println("Failed to open audio file from SD card for reading.");
    server.send(404, "text/plain", "ERROR: Audio file not found on SD card.");
    return;
  }

  // For more accuracy, ContentLength should use actual file size, header uses calculated currentAudioDataSize
  size_t actualFileSizeOnSD = audioFile.size();
  if (actualFileSizeOnSD != currentAudioDataSize) {
    Serial.printf("Warning: File size on SD (%d) does not match expected currentAudioDataSize (%d) for %d seconds.\n", actualFileSizeOnSD, currentAudioDataSize, currentSelectedDurationSeconds);
    // We'll use currentAudioDataSize for the header, but the actual file size from SD for streaming.
    // The Content-Length header for the HTTP response should reflect the header + actual data payload.
  }
  
  String downloadFilename = "recorded_audio_" + String(currentSelectedDurationSeconds) + "s.wav";
  server.sendHeader("Content-Type", "audio/wav");
  server.sendHeader("Content-Disposition", "attachment; filename=\"" + downloadFilename + "\"");
  // The WAV header itself specifies currentAudioDataSize. The HTTP Content-Length is for the whole response body.
  server.setContentLength(44 + actualFileSizeOnSD); // WAV header size + actual data size from file

  server.send(200, "audio/wav", ""); 

  Client& client = server.client();
  sendWAVHeaderToClient(client); // Sends the 44-byte WAV header based on currentAudioDataSize

  const size_t streamBufferSize = 1024;
  uint8_t streamBuffer[streamBufferSize];
  size_t bytesRead;

  Serial.println("Streaming audio data to client...");
  unsigned long bytesSent = 0;
  while (audioFile.available()) {
    bytesRead = audioFile.read(streamBuffer, streamBufferSize);
    if (bytesRead > 0) {
      client.write(streamBuffer, bytesRead);
      bytesSent += bytesRead;
    } else {
      break;
    }
  }
  audioFile.close();
  Serial.printf("Audio data streaming complete. Total bytes sent (payload): %lu\n", bytesSent);
}

void handleBattery() {
  int adcValue = analogRead(batteryPin);
  float voltage = adcValue / 4095.0 * 3.3 * 2.0;
  int percent = voltage_to_percentage(voltage);

  String jsonResponse = "{\"voltage\":" + String(voltage, 2) + ", \"percentage\":" + String(percent) + "}";
  server.send(200, "application/json", jsonResponse);
  Serial.println("Battery status sent: " + String(voltage,2) + "V, " + String(percent) + "%");
}