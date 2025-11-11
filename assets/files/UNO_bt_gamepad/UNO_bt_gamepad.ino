#include <SoftwareSerial.h>
#include <L298N.h>
#include <Servo.h>

// Pin definition
const unsigned int IN1 = 4;
const unsigned int IN2 = 5;
const unsigned int IN3 = 6;
const unsigned int IN4 = 7;

const int MAX_SPEED = 180;  // Velocidad máxima

int servoPinR = 2;
int servoPinL = 8;
int pinGripLeft = 9;
int pinGripRight = 12;
int pinLift = 13;

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
    line.trim(); // limpia \r o espacios

    if (line.length() == 0) continue;

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

  // eco serial opcional
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
    releaseObject();
    moveServosDown();
    pickUpObject();
    stopMotors();
  } else if (command == "B00") {
    pickUpObject();
    stopMotors();
  } else if (command == "X00") {
    releaseObject();
    stopMotors();
  } else if (command == "A00") {
    moveServosUp();
    stopMotors();
  } else if (command == "L02") {
    // moveServosMiddle();
    // returnContainerBack();
  } else if (command == "R02") {
    // moveServosMiddle();
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

void moveServosUp() {
  int currentPosition = servoLeft.read();
  for (int angle = currentPosition; angle >= 10; angle--) {
    servoLeft.write(angle);
    servoRight.write(abs(angle - 180));
    // Serial.print("Down Servo Left Angle");
    // Serial.println(angle);
    delay(5);
  }
}

void moveServosDown() {
  int currentPosition = servoLeft.read();
  for (int angle = currentPosition; angle <= 60; angle++) {
    servoLeft.write(angle);
    servoRight.write(abs(angle - 180));
    // Serial.print("Up Servo Left Angle");
    // Serial.println(angle);
    delay(5);
  }
}

void moveServosMiddle() {
  int currentPosition = servoLeft.read();
  for (int angle = currentPosition; angle >= 70; angle--) {
    servoLeft.write(angle);
    servoRight.write(abs(angle - 180));
    delay(5);
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

void moveBackward() {
  analogWrite(IN1, MAX_SPEED);
  analogWrite(IN2, 0);
  analogWrite(IN3, MAX_SPEED);
  analogWrite(IN4, 0);
}

void moveForward() {
  analogWrite(IN1, 0);
  analogWrite(IN2, MAX_SPEED);
  analogWrite(IN3, 0);
  analogWrite(IN4, MAX_SPEED);
}

void turnRight() {
  analogWrite(IN1, MAX_SPEED * 0.75);
  analogWrite(IN2, 0);
  analogWrite(IN3, 0);
  analogWrite(IN4, MAX_SPEED * 0.75);
}

void turnLeft() {
  analogWrite(IN1, 0);
  analogWrite(IN2, MAX_SPEED * 0.75);
  analogWrite(IN3, MAX_SPEED * 0.75);
  analogWrite(IN4, 0);
}
