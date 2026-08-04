#pragma once
#include <Arduino.h>

// Button event types
enum ButtonEvent : uint8_t {
  BTN_NONE = 0,
  BTN_PSH  = 1,  // Toggle fan
  BTN_CON  = 2,  // Toggle LED
  BTN_BAK  = 3   // Cycle LED mode
};

void initEncoder();
int8_t getEncoderDelta();    // Returns detent steps since last call (+/-)
ButtonEvent checkButtons();  // Returns which button was pressed (debounced)
