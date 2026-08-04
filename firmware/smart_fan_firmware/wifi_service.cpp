#include "wifi_service.h"
#include "config.h"
#include "fan_controller.h"
#include "led_effects.h"
#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ESPmDNS.h>
#include <ArduinoJson.h>

static WebSocketsServer ws(WS_PORT);
static bool _wsClientConnected = false;
static String _ipAddr = "";
static float _cpuTemp = 0;
static float _gpuTemp = 0;

// ---- Process incoming JSON command from app ----
static void handleCommand(uint8_t clientNum, const char* payload) {
  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, payload);
  if (err) {
    Serial.printf("WS: JSON parse error: %s\n", err.c_str());
    return;
  }

  const char* cmd = doc["cmd"];
  if (!cmd) return;

  if (strcmp(cmd, "fan_speed") == 0) {
    uint8_t val = doc["value"] | 0;
    setFanSpeed(val);
    Serial.printf("WS: Fan speed -> %d%%\n", val);
  }
  else if (strcmp(cmd, "fan_state") == 0) {
    bool on = doc["value"] | 0;
    setFanOn(on);
    Serial.printf("WS: Fan %s\n", on ? "ON" : "OFF");
  }
  else if (strcmp(cmd, "led_mode") == 0) {
    uint8_t mode = doc["value"] | 0;
    setLedMode(mode);
    Serial.printf("WS: LED mode -> %d\n", mode);
  }
  else if (strcmp(cmd, "led_color") == 0) {
    uint8_t r = doc["r"] | 0;
    uint8_t g = doc["g"] | 0;
    uint8_t b = doc["b"] | 0;
    setLedColor(r, g, b);
    Serial.printf("WS: LED color R%d G%d B%d\n", r, g, b);
  }
  else if (strcmp(cmd, "led_brightness") == 0) {
    uint8_t val = doc["value"] | 0;
    setLedBrightness(val);
    Serial.printf("WS: LED brightness -> %d\n", val);
  }
  else if (strcmp(cmd, "temp") == 0) {
    _cpuTemp = doc["cpu"] | 0.0f;
    _gpuTemp = doc["gpu"] | 0.0f;
    Serial.printf("WS: Temps CPU=%.1f GPU=%.1f\n", _cpuTemp, _gpuTemp);
  }
}

// ---- WebSocket event handler ----
static void onWsEvent(uint8_t num, WStype_t type, uint8_t* payload, size_t length) {
  switch (type) {
    case WStype_CONNECTED:
      _wsClientConnected = true;
      Serial.printf("WS: Client #%u connected\n", num);
      break;

    case WStype_DISCONNECTED:
      _wsClientConnected = false;
      Serial.printf("WS: Client #%u disconnected\n", num);
      break;

    case WStype_TEXT:
      handleCommand(num, (const char*)payload);
      break;

    default:
      break;
  }
}

void initWiFiService() {
  // Start WiFi AP mode (always available, no router needed)
  // Append last 4 hex chars of MAC for unique SSID
  uint8_t mac[6];
  WiFi.macAddress(mac);
  char apSSID[32];
  snprintf(apSSID, sizeof(apSSID), "%s_%02X%02X", WIFI_AP_SSID, mac[4], mac[5]);

  WiFi.mode(WIFI_AP_STA);
  WiFi.softAP(apSSID, WIFI_AP_PASS, WIFI_AP_CHANNEL, 0, WIFI_AP_MAX_CONN);
  _ipAddr = WiFi.softAPIP().toString();
  Serial.printf("WiFi AP: %s @ %s\n", apSSID, _ipAddr.c_str());

  // Optionally connect to home router (STA mode)
  if (strlen(WIFI_STA_SSID) > 0) {
    Serial.printf("WiFi STA: Connecting to %s...\n", WIFI_STA_SSID);
    WiFi.begin(WIFI_STA_SSID, WIFI_STA_PASS);

    uint32_t start = millis();
    while (WiFi.status() != WL_CONNECTED && (millis() - start) < WIFI_STA_TIMEOUT) {
      delay(100);
    }

    if (WiFi.status() == WL_CONNECTED) {
      _ipAddr = WiFi.localIP().toString();
      Serial.printf("WiFi STA: Connected @ %s\n", _ipAddr.c_str());
    } else {
      Serial.println("WiFi STA: Failed, using AP only");
    }
  }

  // Start mDNS so app can find us at llanofan.local
  if (MDNS.begin(MDNS_NAME)) {
    MDNS.addService("ws", "tcp", WS_PORT);
    Serial.printf("mDNS: %s.local\n", MDNS_NAME);
  }

  // Start WebSocket server
  ws.begin();
  ws.onEvent(onWsEvent);
  Serial.printf("WebSocket: ws://%s:%d\n", _ipAddr.c_str(), WS_PORT);
}

void loopWiFiService() {
  ws.loop();
}

bool isWiFiConnected() {
  return _wsClientConnected;
}

String getWiFiIP() {
  return _ipAddr;
}

float getWiFiCpuTemp() {
  return _cpuTemp;
}

float getWiFiGpuTemp() {
  return _gpuTemp;
}

void wsNotifyRPM(uint16_t rpm) {
  if (!_wsClientConnected) return;

  char buf[32];
  snprintf(buf, sizeof(buf), "{\"rpm\":%u}", rpm);
  ws.broadcastTXT(buf);
}

void wsNotifyStatus(uint8_t fanPercent, bool fanOn, uint8_t ledMode, bool ledOn,
                    float cpuTemp, float gpuTemp) {
  if (!_wsClientConnected) return;

  // ponytail: snprintf over ArduinoJson for notify — cheaper, fixed schema
  char buf[160];
  snprintf(buf, sizeof(buf),
    "{\"fan_pct\":%u,\"fan_on\":%s,\"led_mode\":%u,\"led_on\":%s,\"rpm\":%u,\"cpu\":%.1f,\"gpu\":%.1f}",
    fanPercent, fanOn ? "true" : "false",
    ledMode, ledOn ? "true" : "false",
    getFanRPM(), cpuTemp, gpuTemp
  );
  ws.broadcastTXT(buf);
}
