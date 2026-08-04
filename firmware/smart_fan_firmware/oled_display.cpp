#include "oled_display.h"
#include "config.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SH110X.h>
#include <Adafruit_SSD1306.h>

// I2C buses
static TwoWire I2C1 = TwoWire(0);
static TwoWire I2C2 = TwoWire(1);

// Display objects
static Adafruit_SH1106G oled1(OLED_WIDTH, OLED1_HEIGHT, &I2C1, -1);
static Adafruit_SSD1306 oled2(OLED_WIDTH, OLED2_HEIGHT, &I2C2, -1);

// LED mode names for display
static const char* LED_MODE_NAMES[] = {
  "OFF", "STATIC", "RAINBOW", "BREATH", "SYNC", "WAVE", "FIRE"
};

void initDisplays() {
  // Init I2C buses with assigned pins
  I2C1.begin(PIN_OLED1_SDA, PIN_OLED1_SCL, 400000);
  I2C2.begin(PIN_OLED2_SDA, PIN_OLED2_SCL, 400000);

  // Init main 1.3" OLED (SH1106)
  if (oled1.begin(OLED_ADDR, true)) {
    oled1.clearDisplay();
    oled1.setTextColor(SH110X_WHITE);
    oled1.setTextSize(1);
    oled1.setCursor(20, 28);
    oled1.print("Llano Smart Fan");
    oled1.display();
  }

  // Init secondary 0.96" OLED (SSD1306)
  if (oled2.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    oled2.clearDisplay();
    oled2.setTextColor(SSD1306_WHITE);
    oled2.setTextSize(1);
    oled2.setCursor(30, 28);
    oled2.print("System Info");
    oled2.display();
  }
}

void updateMainDisplay(uint16_t rpm, uint8_t fanPercent, uint8_t ledMode, bool fanOn) {
  oled1.clearDisplay();

  // Title bar
  oled1.setTextSize(1);
  oled1.setCursor(0, 0);
  oled1.print("LLANO SMART FAN");

  // Horizontal divider
  oled1.drawLine(0, 10, 127, 10, SH110X_WHITE);

  // Fan status - large text
  oled1.setTextSize(2);
  oled1.setCursor(0, 14);
  if (fanOn) {
    oled1.print(fanPercent);
    oled1.print("%");
  } else {
    oled1.print("OFF");
  }

  // RPM display
  oled1.setTextSize(1);
  oled1.setCursor(75, 14);
  oled1.print("RPM");
  oled1.setTextSize(2);
  oled1.setCursor(75, 24);
  oled1.print(rpm);

  // Divider
  oled1.drawLine(0, 42, 127, 42, SH110X_WHITE);

  // Fan speed bar (visual gauge)
  oled1.setTextSize(1);
  oled1.setCursor(0, 46);
  oled1.print("PWM:");

  // Draw progress bar
  int barWidth = map(fanOn ? fanPercent : 0, 0, 100, 0, 80);
  oled1.drawRect(30, 45, 82, 8, SH110X_WHITE);
  oled1.fillRect(31, 46, barWidth, 6, SH110X_WHITE);

  // LED mode
  oled1.setCursor(0, 56);
  oled1.print("LED: ");
  if (ledMode < LED_MODE_COUNT) {
    oled1.print(LED_MODE_NAMES[ledMode]);
  }

  oled1.display();
}

void updateSecondaryDisplay(float cpuTemp, float gpuTemp,
                            bool bleConnected, bool wifiConnected, const char* wifiIP) {
  oled2.clearDisplay();

  // Title
  oled2.setTextSize(1);
  oled2.setCursor(0, 0);
  oled2.print("SYSTEM MONITOR");
  oled2.drawLine(0, 10, 127, 10, SSD1306_WHITE);

  // CPU Temperature
  oled2.setCursor(0, 14);
  oled2.print("CPU:");
  if (cpuTemp > 0) {
    oled2.setCursor(30, 14);
    oled2.print(cpuTemp, 0);
    oled2.print("C");
  } else {
    oled2.setCursor(30, 14);
    oled2.print("N/A");
  }

  // GPU Temperature
  oled2.setCursor(68, 14);
  oled2.print("GPU:");
  if (gpuTemp > 0) {
    oled2.setCursor(98, 14);
    oled2.print(gpuTemp, 0);
    oled2.print("C");
  } else {
    oled2.setCursor(98, 14);
    oled2.print("N/A");
  }

  // Connection status divider
  oled2.drawLine(0, 26, 127, 26, SSD1306_WHITE);

  // BLE status
  oled2.setCursor(0, 30);
  oled2.print("BLE: ");
  oled2.print(bleConnected ? "OK" : "--");

  // WiFi status
  oled2.setCursor(68, 30);
  oled2.print("WS: ");
  oled2.print(wifiConnected ? "OK" : "--");

  // WiFi IP address
  oled2.drawLine(0, 42, 127, 42, SSD1306_WHITE);
  oled2.setCursor(0, 46);
  oled2.print("IP:");
  oled2.setCursor(20, 46);
  oled2.print(wifiIP);

  // Port info
  oled2.setCursor(0, 56);
  oled2.print("WS:");
  oled2.print(WS_PORT);
  oled2.setCursor(68, 56);
  oled2.print(MDNS_NAME);
  oled2.print(".local");

  oled2.display();
}
