// Sketch: ESP32 Bluetooth -> controlar servo por posición enviada desde la app
// Envíos aceptados:
//  - "P\n"  -> ping, responde "K\n"
//  - "90\n" -> mueve servo a 90 grados (también acepta "S90\n")

#include "BluetoothSerial.h"
#include <ESP32Servo.h> // librería recomendada para servos en ESP32

BluetoothSerial SerialBT;

// Pines / configuración
const int SERVO_PIN = 13;    // cambia por el pin que uses para el servo
const int LED_PIN = 2;       // led de estado (opcional)
const char* BT_NAME = "ESP32_Servo";

Servo myServo;

int currentAngle = 90; // ángulo actual inicial
const int MIN_ANGLE = 0;
const int MAX_ANGLE = 180;

// Para movimiento suave
const int STEP_DELAY_MS = 12; // ajuste para velocidad de giro (bajar = más rápido)

void setup() {
  Serial.begin(115200);
  SerialBT.begin(BT_NAME);
  Serial.println("Dispositivo iniciado. Empareja por Bluetooth!");
  Serial.println("Envía un número (0-180) o 'S90' y termina con '\\n' para mover el servo.");
  pinMode(LED_PIN, OUTPUT);

  myServo.setPeriodHertz(50); // frecuencia típica para servos
  myServo.attach(SERVO_PIN);

  // Coloca el servo en la posición inicial
  currentAngle = constrain(currentAngle, MIN_ANGLE, MAX_ANGLE);
  myServo.write(currentAngle);
  delay(300);
  digitalWrite(LED_PIN, HIGH);
}

void loop() {
  // Manejo de comandos/heartbeats entrantes de Bluetooth
  while (SerialBT.available()) {
    String line = SerialBT.readStringUntil('\n');
    line.trim(); // elimina espacios y CR/LF sobrantes

    if (line.length() == 0) continue;

    Serial.print("Recibido por BT: ");
    Serial.println(line);

    // Ping simple: si la línea empieza por 'P' -> responder ACK
    if (line.charAt(0) == 'P') {
      SerialBT.print("K\n");
      Serial.println("Ping recibido -> enviado 'K'");
      continue;
    }

    // Si la línea empieza por 'S' puede ser "S90"
    if (line.charAt(0) == 'S' || line.charAt(0) == 's') {
      String numberPart = line.substring(1);
      numberPart.trim();
      if (numberPart.length() == 0) continue;
      int target = numberPart.toInt();
      moveServoTo(constrain(target, MIN_ANGLE, MAX_ANGLE));
      continue;
    }

    // Si es solo número "90" o "-1"
    bool isNumber = true;
    for (size_t i = 0; i < line.length(); ++i) {
      char c = line.charAt(i);
      if (!(isDigit(c) || (i==0 && (c=='-' || c=='+')))) { isNumber = false; break; }
    }
    if (isNumber) {
      int target = line.toInt();
      moveServoTo(constrain(target, MIN_ANGLE, MAX_ANGLE));
      continue;
    }

    // Si no coincide con nada conocido -> log
    Serial.println("Comando no reconocido.");
  }

  // Puedes añadir aquí lecturas periódicas o tareas no bloqueantes
  delay(10);
}

void moveServoTo(int targetAngle) {
  targetAngle = constrain(targetAngle, MIN_ANGLE, MAX_ANGLE);
  if (targetAngle == currentAngle) {
    Serial.print("Ya en posición: ");
    Serial.println(currentAngle);
    // aún así confirmamos por BT
    SerialBT.print("S");
    SerialBT.print(currentAngle);
    SerialBT.print("\n");
    return;
  }

  Serial.print("Moviendo servo de ");
  Serial.print(currentAngle);
  Serial.print(" a ");
  Serial.println(targetAngle);

  if (targetAngle > currentAngle) {
    for (int a = currentAngle + 1; a <= targetAngle; ++a) {
      myServo.write(a);
      delay(STEP_DELAY_MS);
    }
  } else {
    for (int a = currentAngle - 1; a >= targetAngle; --a) {
      myServo.write(a);
      delay(STEP_DELAY_MS);
    }
  }

  currentAngle = targetAngle;
  Serial.print("Posición final: ");
  Serial.println(currentAngle);

  // enviar confirmación por Bluetooth
  SerialBT.print("S");
  SerialBT.print(currentAngle);
  SerialBT.print("\n");
}
