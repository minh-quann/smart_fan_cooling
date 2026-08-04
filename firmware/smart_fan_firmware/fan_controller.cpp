#include "fan_controller.h"
#include "config.h"

static volatile uint32_t _tachCount = 0;
static uint16_t _rpm = 0;
static uint8_t _fanPercent = 0;
static bool _fanOn = false;
static uint32_t _lastRpmCalc = 0;

// Interrupt handler for tachometer pulses
static void IRAM_ATTR tachISR() {
  _tachCount++;
}

void initFan() {
  // Setup PWM via LEDC (old API for Arduino Core 2.x compatibility)
  ledcSetup(FAN_PWM_CHANNEL, FAN_PWM_FREQ, FAN_PWM_RES);
  ledcAttachPin(PIN_FAN_PWM, FAN_PWM_CHANNEL);
  ledcWrite(FAN_PWM_CHANNEL, 0);

  // Setup tachometer interrupt
  pinMode(PIN_FAN_TACH, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PIN_FAN_TACH), tachISR, FALLING);

  _lastRpmCalc = millis();
}

void setFanSpeed(uint8_t percent) {
  if (percent > 100) percent = 100;
  _fanPercent = percent;

  if (_fanOn && percent > 0) {
    uint8_t duty = map(percent, 0, 100, 0, 255);
    ledcWrite(FAN_PWM_CHANNEL, duty);
  } else {
    ledcWrite(FAN_PWM_CHANNEL, 0);
  }
}

void setFanOn(bool on) {
  _fanOn = on;
  if (!on) {
    ledcWrite(FAN_PWM_CHANNEL, 0);
  } else {
    setFanSpeed(_fanPercent);
  }
}

bool isFanOn() {
  return _fanOn;
}

uint8_t getFanPercent() {
  return _fanPercent;
}

uint16_t getFanRPM() {
  return _rpm;
}

void updateRPM() {
  uint32_t now = millis();
  uint32_t elapsed = now - _lastRpmCalc;

  if (elapsed >= RPM_CALC_MS) {
    // Atomically read and reset counter
    noInterrupts();
    uint32_t count = _tachCount;
    _tachCount = 0;
    interrupts();

    // RPM = (pulses / PPR) * (60000 / elapsed_ms)
    _rpm = (uint16_t)((count * 60000UL) / (FAN_TACH_PPR * elapsed));
    _lastRpmCalc = now;
  }
}
