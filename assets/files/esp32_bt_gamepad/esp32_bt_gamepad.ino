/*
 * Proyecto: Control de Gamepad Bluetooth ESP32
 * Descripción: Controla motores y servos usando Bluetooth Classic.
 *             Diseñado para un coche brazo robótico o vehículo similar.
 *
 * Hardware:
 * - Placa de desarrollo ESP32
 * - Controlador de motor L298N (o similar)
 * - Servos (ej. SG90, MG996R)
 *
 * Conexiones:
 * - Motores (L298N):
 *   - IN1 -> GPIO 25
 *   - IN2 -> GPIO 26
 *   - IN3 -> GPIO 27
 *   - IN4 -> GPIO 14
 *   - Motor VCC -> Fuente externa (6-12V)
 *   - Motor GND -> GND (Compartido con ESP32)
 *
 * - Servos:
 *   - Señal Servo Derecho -> GPIO 2
 *   - Señal Servo Izquierdo -> GPIO 15
 *   - Señal Pinza Derecha -> GPIO 4
 *   - Señal Pinza Izquierda -> GPIO 5
 *   - Señal Servo Elevación -> GPIO 18
 *   - Servos VCC -> 5V (Se recomienda fuente externa para múltiples servos)
 *   - Servos GND -> GND (Compartido con ESP32)
 *
 * Bibliotecas Requeridas:
 * - BluetoothSerial (Integrada en el núcleo Arduino ESP32)
 * - ESP32Servo (Instalar desde el Gestor de Bibliotecas)
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
 * - 'A00' -> Secuencia automática (Soltar -> Bajar -> Agarrar)
 */

#include "BluetoothSerial.h"
#include <ESP32Servo.h>

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error ¡Bluetooth no está habilitado! Por favor ejecuta `make menuconfig` para habilitarlo
#endif

BluetoothSerial SerialBT;

// Pines de Motores (L298N)
const unsigned int IN1 = 25;
const unsigned int IN2 = 26;
const unsigned int IN3 = 27;
const unsigned int IN4 = 14;

const int MAX_SPEED = 255; // Velocidad máxima PWM (0-255)

// Calibración de Motores (Ajustar para equilibrar velocidades si un lado es más
// rápido)
const float LEFT_MOTOR_MULTIPLIER = 1.00;  // Motor Izquierdo (IN1/IN2)
const float RIGHT_MOTOR_MULTIPLIER = 0.70; // Motor Derecho (IN3/IN4)

// Pines de Servos
int servoPinR = 2;
int servoPinL = 15;
int pinGripLeft = 5;
int pinGripRight = 4;
int pinLift = 18;

// Objetos Servo
Servo servoRight;
Servo servoLeft;
Servo gripperRight;
Servo gripperLeft;
Servo servoLift;

String incomingBuffer = ""; // Buffer para comandos entrantes

void setup() {
  Serial.begin(115200);
  Serial.println("Control de Gamepad ESP32 Iniciado");

  // Inicializar Bluetooth
  SerialBT.begin("ESP32_Gamepad"); // Nombre del dispositivo Bluetooth
  Serial.println("Bluetooth 'ESP32_Gamepad' listo");

  // Configurar Pines de Motores
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  // Inicializar Servos
  // Los servos estándar usan una frecuencia PWM de 50Hz
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

  // Mover servos a posición media inicial
  moveServosMiddle();

  Serial.println("Sistema inicializado correctamente");
  Serial.println("Esperando comandos Bluetooth...");
}

void loop() {
  // ***** Manejar comandos Bluetooth entrantes *****
  while (SerialBT.available()) {
    char c = SerialBT.read();

    // Ignorar retorno de carro
    if (c == '\r')
      continue;

    // Nueva línea indica fin del comando -> procesarlo
    if (c == '\n') {
      executeCommand(incomingBuffer);
      incomingBuffer = ""; // Limpiar buffer
    } else {
      incomingBuffer += c;

      // Límite de seguridad para el tamaño del buffer para evitar problemas de
      // memoria
      if (incomingBuffer.length() > 16) {
        incomingBuffer = incomingBuffer.substring(incomingBuffer.length() - 16);
      }
    }
  }

  delay(5); // Pequeña pausa para estabilidad
}

void executeCommand(String command) {
  command.trim(); // Eliminar espacios en blanco al inicio/final

  if (command.length() == 0)
    return;

  Serial.print("Comando recibido: ");
  Serial.println(command);

  // ***** Ping *****
  if (command.charAt(0) == 'P' || command.charAt(0) == 'p') {
    SerialBT.print("K\n");
    Serial.println("Ping recibido -> enviado 'K'");
    return;
  }

  // ***** Comandos de Movimiento *****
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
    Serial.print("Comando desconocido: ");
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
  // Cerrar pinza lentamente
  for (int angle = currentPosition; angle <= 170; angle++) {
    gripperLeft.write(angle);
    gripperRight.write(
        abs(angle - 180)); // Movimiento espejo para pinza derecha
    delay(5);
  }
}

void releaseObject() {
  Serial.println("Acción: Soltar objeto");
  int currentPosition = gripperLeft.read();
  // Abrir pinza lentamente
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
  Serial.println("Motores: Girar Izquierda");
  analogWrite(IN1, 0);
  analogWrite(IN2, MAX_SPEED * 0.75 * LEFT_MOTOR_MULTIPLIER);
  analogWrite(IN3, MAX_SPEED * 0.75 * RIGHT_MOTOR_MULTIPLIER);
  analogWrite(IN4, 0);
}

void turnRight() {
  Serial.println("Motores: Girar Derecha");
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
