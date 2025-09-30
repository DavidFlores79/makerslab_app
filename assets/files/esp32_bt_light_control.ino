#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

#define ledPin    2    // Pin del LED
#define buttonPin 4    // Pin del botón

int ledState = LOW;           // 0 o 1
int buttonState = LOW;        // estado debounced
int lastButtonReading = LOW;  // última lectura cruda

unsigned long lastDebounceTime = 0;
const unsigned long debounceDelay = 50; // ms

unsigned long lastSendMillis = 0;
const unsigned long sendInterval = 2000; // ms: intervalo para enviar estado por BT

String incomingBuf = ""; // buffer no bloqueante para datos entrantes

void setup() {
  Serial.begin(115200);
  SerialBT.begin("ESP32test");
  Serial.println("Dispositivo iniciado. Empareja por Bluetooth!");

  pinMode(ledPin, OUTPUT);
  // Si tu botón está conectado a GND y usas pull-up interna:
  // pinMode(buttonPin, INPUT_PULLUP);
  // y ajusta la lógica inversa (activo LOW).
  pinMode(buttonPin, INPUT);

  digitalWrite(ledPin, ledState);
}

void processCommand(String cmd) {
  cmd.trim();
  if (cmd.length() == 0) return;

  // Aceptamos "0" o "1" para controlar el LED
  if (cmd == "0" || cmd == "1") {
    int v = cmd.toInt();
    if (v != ledState) {
      ledState = v;
      digitalWrite(ledPin, ledState);
      Serial.print("Comando BT: ledState set a ");
      Serial.println(ledState);
    } else {
      Serial.print("Comando BT recibido pero ledState ya es ");
      Serial.println(ledState);
    }
    // opcional: enviar confirmación inmediata
    SerialBT.print(String(ledState) + "\n");
  } else {
    // otros comandos (si quieres) se pueden manejar aquí
    Serial.print("Comando BT no reconocido: ");
    Serial.println(cmd);
  }
}

void loop() {
  // --- Lectura no bloqueante de Bluetooth (montamos líneas terminadas en '\n') ---
  while (SerialBT.available()) {
    char c = SerialBT.read();
    if (c == '\r') continue;        // ignorar CR si hay
    if (c == '\n') {
      // procesar línea completa
      processCommand(incomingBuf);
      incomingBuf = "";
    } else {
      incomingBuf += c;
      // por seguridad, evitar buffer muy grande
      if (incomingBuf.length() > 64) {
        incomingBuf = incomingBuf.substring(incomingBuf.length() - 64);
      }
    }
  }

  // --- Debounce del botón ---
  int reading = digitalRead(buttonPin);

  if (reading != lastButtonReading) {
    lastDebounceTime = millis();
    lastButtonReading = reading;
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (reading != buttonState) {
      buttonState = reading;
      // Asumo botón activo HIGH; si usas INPUT_PULLUP cambia la condición a (buttonState == LOW)
      if (buttonState == HIGH) {
        // toggle al presionar
        ledState = !ledState;
        digitalWrite(ledPin, ledState);
        Serial.print("Botón: toggle -> ledState = ");
        Serial.println(ledState);

        // enviar estado inmediato tras cambio físico
        SerialBT.print(String(ledState) + "\n");
        SerialBT.flush();
      }
    }
  }

  // --- Envío periódico del estado actual del LED ---
  if (millis() - lastSendMillis >= sendInterval) {
    lastSendMillis = millis();
    // formato simple: "0\n" o "1\n"
    SerialBT.print(String(ledState) + "\n");
    Serial.print("Envio periódico estado LED: ");
    Serial.println(ledState);
  }

  delay(10); // pequeña pausa para estabilidad
}
