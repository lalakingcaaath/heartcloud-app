#include <Arduino.h>

int myFunction(int, int);

void setup() {
  int result = myFunction(2, 3);
}

void loop() {
  Serial.begin(115200);

  Serial.println("Hello");

  delay(1000);
  

// put function definitions here:
int myFunction(int x, int y) {
  return x + y;
}
