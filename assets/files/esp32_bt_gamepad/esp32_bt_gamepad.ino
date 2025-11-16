// ESP32 Bluetooth Classic + Gamepad Control (Motors + Servos)
//
// Conexiones:
// - Motores (usando L298N o similar):
//   - IN1 -> GPIO 25
//   - IN2 -> GPIO 26
//   - IN3 -> GPIO 27
//   - IN4 -> GPIO 14
//   - Motor VCC -> Fuente externa (6-12V dependiendo de tus motores)
//   - Motor GND -> GND (compartido con ESP32)
//
// - Servos:
//   - Servo Right Signal -> GPIO 2
//   - Servo Left Signal -> GPIO 15
//   - Gripper Right Signal -> GPIO 4
//   - Gripper Left Signal -> GPIO 5
//   - Servo Lift Signal -> GPIO 18
//   - Servos VCC -> 5V (o fuente externa si los servos consumen mucha corriente)
//   - Servos GND -> GND (compartido con ESP32)
//
// IMPORTANTE: ESP32 tiene Bluetooth Classic integrado, no necesitas módulo externo HC-05
//
// Bibliotecas necesarias:
// - BluetoothSerial (incluida en ESP32 Arduino Core)
// - ESP32Servo (instalar desde Library Manager)

#include "BluetoothSerial.h"
#include <ESP32Servo.h>

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to enable it
#endif

BluetoothSerial SerialBT;

// Pines de motores (L298N o similar)
const unsigned int IN1 = 25;
const unsigned int IN2 = 26;
const unsigned int IN3 = 27;
const unsigned int IN4 = 14;

const int MAX_SPEED = 255;  // Velocidad máxima PWM

// Calibración de motores (ajustar para balancear velocidades)
const float LEFT_MOTOR_MULTIPLIER = 1.00;  // Motor izquierdo (IN1/IN2)
const float RIGHT_MOTOR_MULTIPLIER = 0.70; // Motor derecho (IN3/IN4)

// Pines de servos
int servoPinR = 2;
int servoPinL = 15;
int pinGripLeft = 5;
int pinGripRight = 4;
int pinLift = 18;

Servo servoRight;
Servo servoLeft;
Servo gripperRight;
Servo gripperLeft;
Servo servoLift;

String incomingBuffer = ""; // Buffer para comandos entrantes

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 Gamepad Control iniciado");

  // Inicializar Bluetooth
  SerialBT.begin("ESP32_Gamepad"); // Nombre del dispositivo Bluetooth
  Serial.println("Bluetooth 'ESP32_Gamepad' listo");

  // Configurar pines de motores
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  // Inicializar servos
  servoLift.setPeriodHertz(50);
  servoLift.attach(pinLift);
  servoLift.write(0); // Posición inicial

  servoLeft.setPeriodHertz(50);
  servoLeft.attach(servoPinL);

  servoRight.setPeriodHertz(50);
  servoRight.attach(servoPinR);

  gripperLeft.setPeriodHertz(50);
  gripperLeft.attach(pinGripLeft);

  gripperRight.setPeriodHertz(50);
  gripperRight.attach(pinGripRight);

  // Posición inicial de servos
  moveServosMiddle();

  Serial.println("Sistema iniciado correctamente");
  Serial.println("Esperando comandos Bluetooth...");
}

void loop() {
  // ***** Manejo de comandos entrantes por Bluetooth *****
  while (SerialBT.available()) {
    char c = SerialBT.read();

    // Ignorar retorno de carro
    if (c == '\r') continue;

    // Fin de línea -> procesar comando
    if (c == '\n') {
      executeCommand(incomingBuffer);
      incomingBuffer = ""; // Limpiar buffer
    } else {
      incomingBuffer += c;

      // Límite de seguridad para el buffer
      if (incomingBuffer.length() > 16) {
        incomingBuffer = incomingBuffer.substring(incomingBuffer.length() - 16);
      }
    }
  }

  delay(5); // Pequeña pausa para estabilidad
}

void executeCommand(String command) {
  command.trim();

  if (command.length() == 0) return;

  Serial.print("Comando recibido: ");
  Serial.println(command);

  // ***** Ping *****
  if (command.charAt(0) == 'P' || command.charAt(0) == 'p') {
    SerialBT.print("K\n");
    Serial.println("Ping recibido -> enviado 'K'");
    return;
  }

  // ***** Comandos de movimiento *****
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
    returnContainerBack();
  } else if (command == "R02") {
    emptyTrashContainer();
  } else {
    Serial.print("Comando no reconocido: ");
    Serial.println(command);
    SerialBT.print("ERROR\n");
  }
}

// =======================
// Funciones de Servos
// =======================

void pickUpObject() {
  Serial.println("Acción: Agarrar objeto");
  int currentPosition = gripperLeft.read();
  for (int angle = currentPosition; angle <= 170; angle++) {
    gripperLeft.write(angle);
    gripperRight.write(abs(angle - 180));
    delay(5);
  }
}

void releaseObject() {
  Serial.println("Acción: Soltar objeto");
  int currentPosition = gripperLeft.read();
  for (int angle = currentPosition; angle >= 90; angle--) {
    gripperLeft.write(angle);
    gripperRight.write(abs(angle - 180));
    delay(5);
  }
}

void moveServosDown() {
  Serial.println("Acción: Bajar servos");
  int currentPosition = servoLeft.read();
  for (int angle = currentPosition; angle >= 1; angle--) {
    servoLeft.write(angle);
    servoRight.write(abs(angle - 180));
    delay(5);
  }
}

void moveServosUp() {
  Serial.println("Acción: Subir servos");
  int currentPosition = servoLeft.read();
  for (int angle = currentPosition; angle <= 80; angle++) {
    servoLeft.write(angle);
    servoRight.write(abs(angle - 180));
    delay(5);
  }
}

void moveServosMiddle() {
  Serial.println("Acción: Servos a posición media");
  int currentPosition = servoLeft.read();
  int targetPosition = 70;

  if (currentPosition < targetPosition) {
    for (int angle = currentPosition; angle <= targetPosition; angle++) {
      servoLeft.write(angle);
      servoRight.write(abs(angle - 180));
      delay(5);
    }
  } else if (currentPosition > targetPosition) {
    for (int angle = currentPosition; angle >= targetPosition; angle--) {
      servoLeft.write(angle);
      servoRight.write(abs(angle - 180));
      delay(5);
    }
  }
}

void emptyTrashContainer() {
  Serial.println("Acción: Vaciar contenedor");
  int currentPosition = servoLift.read();
  for (int angle = currentPosition; angle <= 150; angle++) {
    servoLift.write(angle);
    delay(5);
  }
}

void returnContainerBack() {
  Serial.println("Acción: Regresar contenedor");
  int currentPosition = servoLift.read();
  for (int angle = currentPosition; angle >= 0; angle--) {
    servoLift.write(angle);
    delay(5);
  }
}

// =======================
// Funciones de Motores
// =======================

void stopMotors() {
  Serial.println("Motores: Detenidos");
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}

void turnLeft() {
  Serial.println("Motores: Girar izquierda");
  analogWrite(IN1, 0);
  analogWrite(IN2, MAX_SPEED * 0.75 * LEFT_MOTOR_MULTIPLIER);
  analogWrite(IN3, MAX_SPEED * 0.75 * RIGHT_MOTOR_MULTIPLIER);
  analogWrite(IN4, 0);
}

void turnRight() {
  Serial.println("Motores: Girar derecha");
  analogWrite(IN1, MAX_SPEED * 0.75 * LEFT_MOTOR_MULTIPLIER);
  analogWrite(IN2, 0);
  analogWrite(IN3, 0);
  analogWrite(IN4, MAX_SPEED * 0.75 * RIGHT_MOTOR_MULTIPLIER);
}

void moveBackward() {
  Serial.println("Motores: Retroceder");
  analogWrite(IN1, 0);
  analogWrite(IN2, MAX_SPEED * LEFT_MOTOR_MULTIPLIER);
  analogWrite(IN3, 0);
  analogWrite(IN4, MAX_SPEED * RIGHT_MOTOR_MULTIPLIER);
}

void moveForward() {
  Serial.println("Motores: Avanzar");
  analogWrite(IN1, MAX_SPEED * LEFT_MOTOR_MULTIPLIER);
  analogWrite(IN2, 0);
  analogWrite(IN3, MAX_SPEED * RIGHT_MOTOR_MULTIPLIER);
  analogWrite(IN4, 0);
}
