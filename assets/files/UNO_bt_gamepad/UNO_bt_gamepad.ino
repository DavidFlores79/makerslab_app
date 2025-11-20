/*
 * Proyecto: Control de Gamepad Arduino UNO Bluetooth
 * Descripción: Controla motores y servos usando Bluetooth HC-05.
 *             Diseñado para un coche brazo robótico o vehículo similar.
 *
 * Hardware:
 * - Arduino UNO
 * - Módulo Bluetooth HC-05
 * - Controlador de motor L298N
 * - Servos (ej. SG90, MG996R)
 *
 * Conexiones:
 * - Motores (L298N):
 *   - IN1 -> Pin 4
 *   - IN2 -> Pin 5
 *   - IN3 -> Pin 6
 *   - IN4 -> Pin 7
 *
 * - Servos:
 *   - Servo Derecho -> Pin 2
 *   - Servo Izquierdo -> Pin 8
 *   - Pinza Izquierda -> Pin 9
 *   - Pinza Derecha -> Pin 12
 *   - Servo Elevación -> Pin 13
 *
 * - Bluetooth HC-05:
 *   - TXD -> Pin 10 (RX Software)
 *   - RXD -> Pin 11 (TX Software)
 *
 * Bibliotecas Requeridas:
 * - SoftwareSerial (Incluida en Arduino IDE)
 * - Servo (Incluida en Arduino IDE)
 * - L298N (Instalar desde el Gestor de Bibliotecas si es necesaria, aunque este
 * código usa control directo)
 *
 * Comandos Bluetooth:
 * - 'P' -> Ping (Respuesta: 'K')
 * - 'F01' -> Avanzar
 * - 'B01' -> Retroceder
 * - 'L01' -> Girar Izquierda
 * - 'R01' -> Girar Derecha
 * - 'S00' -> Detener Motores
 * - 'B00' -> Agarrar objeto
 * - 'X00' -> Soltar objeto
 * - 'Y00' -> Subir servos
 * - 'A00' -> Secuencia automática
 */

#include <L298N.h>
#include <Servo.h>
#include <SoftwareSerial.h>

// Definición de Pines de Motores
const unsigned int IN1 = 4;
const unsigned int IN2 = 5;
const unsigned int IN3 = 6;
const unsigned int IN4 = 7;

const int MAX_SPEED = 255; // Velocidad máxima (PWM valor máx)

// Calibración de Motores (Ajustar para equilibrar velocidades)
const float LEFT_MOTOR_MULTIPLIER = 1.00;  // Rueda Izquierda (IN1/IN2)
const float RIGHT_MOTOR_MULTIPLIER = 0.70; // Rueda Derecha (IN3/IN4)

// Pines de Servos
int servoPinR = 2;
int servoPinL = 8;
int pinGripLeft = 9;
int pinGripRight = 12;
int pinLift = 13;

// Objetos Servo
Servo servoRight;
Servo servoLeft;
Servo gripperRight;
Servo gripperLeft;
Servo servoLift;

SoftwareSerial SerialBT(10, 11); // RX, TX

void setup() {
  Serial.begin(9600);
  Serial.println("Serial Listo!");

  SerialBT.begin(9600);
  Serial.println("Bluetooth Listo!");

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  servoLift.attach(pinLift);
  servoLift.write(0);

  servoLeft.attach(servoPinL);
  servoRight.attach(servoPinR);
  gripperLeft.attach(pinGripLeft);
  gripperRight.attach(pinGripRight);

  moveServosMiddle();

  Serial.println("Sistema iniciado correctamente.");
}

void loop() {
  // Manejo de comandos entrantes por Bluetooth
  while (SerialBT.available()) {
    String line = SerialBT.readStringUntil('\n');
    line.trim(); // Limpia \r o espacios

    if (line.length() == 0)
      continue;

    Serial.print("Recibido por BT: ");
    Serial.println(line);

    // === PING ===
    if (line.charAt(0) == 'P') {
      SerialBT.print("K\n");
      Serial.println("Ping recibido -> Enviado 'K'");
      continue;
    }

    // === Comando de movimiento / acción ===
    executeCommand(line);
  }

  // Eco serial opcional (para depuración desde monitor serial)
  if (Serial.available()) {
    SerialBT.write(Serial.read());
  }

  delay(5);
}

void executeCommand(String command) {
  if (command == "S00") {
    stopMotors();
  } else if (command == "F01") {
    moveForward();
  } else if (command == "B01") {
    moveBackward();
  } else if (command == "R01") {
    turnRight();
  } else if (command == "L01") {
    turnLeft();
  } else if (command == "Y00") {
    moveServosUp();
    stopMotors();
  } else if (command == "B00") {
    pickUpObject();
    stopMotors();
  } else if (command == "X00") {
    releaseObject();
    stopMotors();
  } else if (command == "A00") {
    releaseObject();
    moveServosDown();
    pickUpObject();
    stopMotors();
  } else if (command == "L02") {
    // Marcador de posición para futura implementación
    // returnContainerBack();
  } else if (command == "R02") {
    // Marcador de posición para futura implementación
    // emptyTrashContainer();
  } else {
    Serial.print("Comando no reconocido: ");
    Serial.println(command);
  }
}

// =======================
// Funciones auxiliares
// =======================

void pickUpObject() {
  int currentPosition = gripperLeft.read();
  for (int angle = currentPosition; angle <= 170; angle++) {
    gripperLeft.write(angle);
    gripperRight.write(abs(angle - 180));
    delay(5);
  }
}

void releaseObject() {
  int currentPosition = gripperLeft.read();
  for (int angle = currentPosition; angle >= 90; angle--) {
    gripperLeft.write(angle);
    gripperRight.write(abs(angle - 180));
    delay(5);
  }
}

void moveServosDown() {
  int currentPosition = servoLeft.read();
  for (int angle = currentPosition; angle >= 1; angle--) {
    servoLeft.write(angle);
    servoRight.write(abs(angle - 180));
    delay(5);
  }
}

void moveServosUp() {
  int currentPosition = servoLeft.read();
  for (int angle = currentPosition; angle <= 80; angle++) {
    servoLeft.write(angle);
    servoRight.write(abs(angle - 180));
    delay(5);
  }
}

void moveServosMiddle() {
  int currentPosition = servoLeft.read();
  int targetPosition = 70;

  if (currentPosition < targetPosition) {
    // Mover hacia arriba (incrementar ángulo)
    for (int angle = currentPosition; angle <= targetPosition; angle++) {
      servoLeft.write(angle);
      servoRight.write(abs(angle - 180));
      delay(5);
    }
  } else if (currentPosition > targetPosition) {
    // Mover hacia abajo (decrementar ángulo)
    for (int angle = currentPosition; angle >= targetPosition; angle--) {
      servoLeft.write(angle);
      servoRight.write(abs(angle - 180));
      delay(5);
    }
  }
}

void emptyTrashContainer() {
  int currentPosition = servoLift.read();
  for (int angle = currentPosition; angle <= 150; angle++) {
    servoLift.write(angle);
    delay(5);
  }
}

void returnContainerBack() {
  int currentPosition = servoLift.read();
  for (int angle = currentPosition; angle >= 0; angle--) {
    servoLift.write(angle);
    delay(5);
  }
}

// =======================
// Movimiento de motores
// =======================

void stopMotors() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}

void turnLeft() {
  analogWrite(IN1, 0);
  analogWrite(IN2, MAX_SPEED * 0.75 * LEFT_MOTOR_MULTIPLIER);
  analogWrite(IN3, MAX_SPEED * 0.75 * RIGHT_MOTOR_MULTIPLIER);
  analogWrite(IN4, 0);
}

void turnRight() {
  analogWrite(IN1, MAX_SPEED * 0.75 * LEFT_MOTOR_MULTIPLIER);
  analogWrite(IN2, 0);
  analogWrite(IN3, 0);
  analogWrite(IN4, MAX_SPEED * 0.75 * RIGHT_MOTOR_MULTIPLIER);
}

void moveBackward() {
  analogWrite(IN1, 0);
  analogWrite(IN2, MAX_SPEED * LEFT_MOTOR_MULTIPLIER);
  analogWrite(IN3, 0);
  analogWrite(IN4, MAX_SPEED * RIGHT_MOTOR_MULTIPLIER);
}

void moveForward() {
  analogWrite(IN1, MAX_SPEED * LEFT_MOTOR_MULTIPLIER);
  analogWrite(IN2, 0);
  analogWrite(IN3, MAX_SPEED * RIGHT_MOTOR_MULTIPLIER);
  analogWrite(IN4, 0);
}
