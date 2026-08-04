// ============================================================
// Llano Smart Fan - ESP32-S3 Firmware
// Controls: Fan PWM, RGB LED, Dual OLED, Rotary Encoder
// Comms: BLE + WiFi WebSocket (dual transport)
// Board: YD-ESP32-S3 (N16R8) + 44-Pin Terminal Adapter
// ============================================================

#include "config.h"
#include "fan_controller.h"
#include "encoder_input.h"
#include "led_effects.h"
#include "oled_display.h"
#include "ble_service.h"
#include "wifi_service.h"

// Timing trackers
static uint32_t lastDisplayUpdate = 0;
static uint32_t lastCommNotify = 0;
static uint32_t lastLedUpdate = 0;

void setup() {
  Serial.begin(115200);
  while (!Serial && millis() < 3000) delay(10);
  delay(1000);
  Serial.println("\n=== Llano Smart Fan v2.0 (BLE + WiFi) ===");

  Serial.println("[1/6] Fan...");
  initFan();
  Serial.println("[OK] Fan controller");

  Serial.println("[2/6] Encoder...");
  initEncoder();
  Serial.println("[OK] Encoder + buttons");

  Serial.println("[3/6] LEDs...");
  initLeds();
  Serial.println("[OK] LED strip");

  Serial.println("[4/6] OLEDs...");
  initDisplays();
  Serial.println("[OK] Dual OLED displays");

  Serial.println("[5/6] BLE...");
  initBLE();
  Serial.println("[OK] BLE service");

  Serial.println("[6/6] WiFi...");
  initWiFiService();
  Serial.println("[OK] WiFi + WebSocket service");

  // Default state: fan ON at 30%, LED rainbow
  setFanOn(true);
  setFanSpeed(30);
  setLedOn(true);
  setLedMode(LED_RAINBOW);

  Serial.println("=== System Ready ===\n");
}

void loop() {
  uint32_t now = millis();

  // ---- 0. Handle WiFi WebSocket events ----
  loopWiFiService();

  // ---- 1. Read encoder for speed adjustment ----
  int8_t encDelta = getEncoderDelta();
  if (encDelta != 0) {
    int16_t newSpeed = (int16_t)getFanPercent() + (encDelta * ENCODER_STEP);
    newSpeed = constrain(newSpeed, 0, 100);
    setFanSpeed((uint8_t)newSpeed);
    Serial.printf("Encoder: speed -> %d%%\n", newSpeed);
  }

  // ---- 2. Check button presses ----
  ButtonEvent btn = checkButtons();
  switch (btn) {
    case BTN_PSH:
      setFanOn(!isFanOn());
      Serial.printf("PSH: Fan %s\n", isFanOn() ? "ON" : "OFF");
      break;
    case BTN_CON:
      setLedOn(!isLedOn());
      Serial.printf("CON: LED %s\n", isLedOn() ? "ON" : "OFF");
      break;
    case BTN_BAK: {
      uint8_t nextMode = (getLedMode() + 1) % LED_MODE_COUNT;
      if (nextMode == LED_OFF) nextMode = LED_STATIC;  // Skip OFF in cycle
      setLedMode(nextMode);
      Serial.printf("BAK: LED mode -> %d\n", nextMode);
      break;
    }
    default:
      break;
  }

  // ---- 3. Update fan RPM calculation ----
  updateRPM();

  // ---- 4. Update LED effects (target ~30fps) ----
  if (now - lastLedUpdate >= 33) {
    setLedSpeedPercent(getFanPercent());
    updateLeds();
    lastLedUpdate = now;
  }

  // ---- 5. Update OLED displays (every 100ms) ----
  if (now - lastDisplayUpdate >= DISPLAY_UPDATE_MS) {
    float cpuT = getWiFiCpuTemp() > 0 ? getWiFiCpuTemp() : getBLECpuTemp();
    float gpuT = getWiFiGpuTemp() > 0 ? getWiFiGpuTemp() : getBLEGpuTemp();

    updateMainDisplay(getFanRPM(), getFanPercent(), getLedMode(), isFanOn());
    updateSecondaryDisplay(cpuT, gpuT,
                           isBLEConnected(), isWiFiConnected(),
                           isSTAConnected() ? getSTAIP().c_str() : getAPIP().c_str());
    lastDisplayUpdate = now;
  }

  // ---- 6. Notify clients on both transports (every 500ms) ----
  if (now - lastCommNotify >= COMM_NOTIFY_MS) {
    float cpuT = getWiFiCpuTemp() > 0 ? getWiFiCpuTemp() : getBLECpuTemp();
    float gpuT = getWiFiGpuTemp() > 0 ? getWiFiGpuTemp() : getBLEGpuTemp();

    // BLE notifications
    notifyRPM(getFanRPM());
    notifyStatus(getFanPercent(), isFanOn(), getLedMode(), isLedOn());

    // WiFi WebSocket notifications
    wsNotifyStatus(getFanPercent(), isFanOn(), getLedMode(), isLedOn(), cpuT, gpuT);

    lastCommNotify = now;
  }
}
