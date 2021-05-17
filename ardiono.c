#include "Keyboard.h"
#include "Mouse.h"

int CONTROL_ENCODE_VALUE = 1024;
int ALT_ENCODE_VALUE = 2048;
int SHIFT_ENCODE_VALUE = 4096;

void setup() {
  Serial.begin(9600);
  Serial.setTimeout(50);
  Keyboard.begin();
  Mouse.begin();
}

int test = 0;

void doKeyboard(int keyValue) {
    if (keyValue & CONTROL_ENCODE_VALUE) {
      // hold control
      Keyboard.press(KEY_LEFT_CTRL);
      delay(1);
    }
    if (keyValue & ALT_ENCODE_VALUE) {
      // hold control
      Keyboard.press(KEY_LEFT_ALT);
      delay(1);
    }
    if (keyValue & SHIFT_ENCODE_VALUE) {
      // hold control
      Keyboard.press(KEY_LEFT_SHIFT);
      delay(1);
    }
    // if data is less than 100,
    Keyboard.press(136 + keyValue % 256);
    delay(5);
    Keyboard.release(136 + keyValue % 256);
    delay(2);
  
    if (keyValue & CONTROL_ENCODE_VALUE) {
      // hold control
      Keyboard.release(KEY_LEFT_CTRL);
      delay(1);
    }
    if (keyValue & ALT_ENCODE_VALUE) {
      // hold control
      Keyboard.release(KEY_LEFT_ALT);
      delay(1);
    }
    if (keyValue & SHIFT_ENCODE_VALUE) {
      // hold control
      Keyboard.release(KEY_LEFT_SHIFT);
    }
}
void mouseMove(long x, long y) {
  long max = max(abs(x), abs(y));
  int count = (int) (max / 127);
  signed char stepX = x / (count + 1);
  signed char stepY = y / (count + 1);
  for (int i = 0; i < count; i++) {
    Mouse.move(stepX, stepY, 0);
    delay(1);
  }
  signed char resX = x - (stepX * count);
  signed char resY = y - (stepY * count);
  if (resX != 0 || resY != 0) {
    Mouse.move(resX, resY, 0);
    delay(1);
  }
}

void doMouse(int firstValue, int lastValue) {
  mouseMove(firstValue, lastValue);
  delay(2);
  Mouse.click();
}

void loop() {
  if(Serial.available() > 0) {
    String a = Serial.readString();
    
    if (a[0] == 'm') {
      int commaIndex = a.indexOf(',');
      int firstValue = a.substring(1, commaIndex).toInt();
      int lastValue = a.substring(commaIndex + 1).toInt();
      
      doMouse(firstValue, lastValue);
    }
    else if (a[0] == 'k') {
      int value = a.substring(1).toInt();
      doKeyboard(value);
    }
    else {
      int value = a.toInt();
      doKeyboard(value);
    }
    Serial.println(a);
  }
}