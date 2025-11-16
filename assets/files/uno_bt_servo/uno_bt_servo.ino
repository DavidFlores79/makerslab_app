// Arduino UNO + HC-05 Bluetooth + Servo Motor Control
//
// Conexiones:
// - Servo VCC -> 5V Arduino (o fuente externa para servos grandes)
// - Servo GND -> GND Arduino
// - Servo Signal -> Pin 9 Arduino
// - HC-05 VCC -> 5V Arduino (o 3.3V si tu módulo lo requiere)
// - HC-05 GND -> GND Arduino
// - HC-05 TXD -> Pin 10 Arduino (RX software)
// - HC-05 RXD -> Pin 11 Arduino (TX software) + divisor de voltaje 5V->3.3V
//
// IMPORTANTE: Si tu servo consume mucha corriente, usa una fuente externa
// y conecta GND de la fuente externa con GND del Arduino

#include <SoftwareSerial.h>
#include <Servo.h>

// Configuración Bluetooth HC-05
#define BT_RX 10       // Pin RX del Arduino conectado a TXD del HC-05
#define BT_TX 11       // Pin TX del Arduino conectado a RXD del HC-05 (con divisor de voltaje)

// Configuración Servo
#define SERVO_PIN 9    // Pin digital conectado al servo

SoftwareSerial SerialBT(BT_RX, BT_TX); // RX, TX
Servo myServo;

int currentAngle = 90;      // Ángulo actual (posición inicial: 90°)
const int MIN_ANGLE = 0;    // Ángulo mínimo permitido
const int MAX_ANGLE = 180;  // Ángulo máximo permitido

// Para movimiento suave (interpolación)
const int STEP_DELAY_MS = 15; // Milisegundos entre pasos (menor = más rápido)

String incomingBuffer = ""; // Buffer para comandos entrantes

void setup() {
  Serial.begin(9600);
  Serial.println("Arduino UNO + HC-05 + Servo iniciado");

  // Inicializar Bluetooth
  SerialBT.begin(9600); // Velocidad predeterminada del HC-05
  Serial.println("Bluetooth HC-05 listo");

  // Inicializar servo
  myServo.attach(SERVO_PIN);
  myServo.write(currentAngle); // Posición inicial
  delay(300); // Esperar a que el servo alcance la posición

  Serial.println("Servo inicializado en 90°");
  Serial.println("Esperando comandos Bluetooth...");
  Serial.println("Formato: Enviar número (0-180) o 'S90' terminado en \\n");
}

void loop() {
  // ***** Manejo de comandos/heartbeats entrantes de Bluetooth *****
  while (SerialBT.available()) {
    char c = SerialBT.read();

    // Ignorar retorno de carro
    if (c == '\r') continue;

    // Fin de línea -> procesar comando
    if (c == '\n') {
      processCommand(incomingBuffer);
      incomingBuffer = ""; // Limpiar buffer
    } else {
      incomingBuffer += c;

      // Límite de seguridad para el buffer
      if (incomingBuffer.length() > 16) {
        incomingBuffer = incomingBuffer.substring(incomingBuffer.length() - 16);
      }
    }
  }

  delay(10); // Pequeña pausa para estabilidad
}

void processCommand(String cmd) {
  cmd.trim(); // Eliminar espacios en blanco

  if (cmd.length() == 0) return;

  Serial.print("Comando recibido: ");
  Serial.println(cmd);

  // ***** Ping simple: 'P' -> responder 'K' *****
  if (cmd.charAt(0) == 'P' || cmd.charAt(0) == 'p') {
    SerialBT.print("K\n");
    Serial.println("Ping -> enviado 'K'");
    return;
  }

  // ***** Comando de posición: 'S90' o simplemente '90' *****
  int targetAngle = -1;

  // Si comienza con 'S' o 's', extraer el número
  if (cmd.charAt(0) == 'S' || cmd.charAt(0) == 's') {
    String numberPart = cmd.substring(1);
    numberPart.trim();
    targetAngle = numberPart.toInt();
  } else {
    // Si es solo un número
    targetAngle = cmd.toInt();
  }

  // Validar que es un número válido
  if (targetAngle >= MIN_ANGLE && targetAngle <= MAX_ANGLE) {
    moveServoTo(targetAngle);
  } else {
    Serial.println("Comando no válido (debe ser 0-180)");
    SerialBT.print("ERROR\n");
  }
}

void moveServoTo(int targetAngle) {
  // Constrain para seguridad
  targetAngle = constrain(targetAngle, MIN_ANGLE, MAX_ANGLE);

  // Si ya estamos en la posición objetivo
  if (targetAngle == currentAngle) {
    Serial.print("Ya en posición: ");
    Serial.println(currentAngle);

    // Confirmar por Bluetooth
    SerialBT.print("S");
    SerialBT.print(currentAngle);
    SerialBT.print("\n");
    return;
  }

  Serial.print("Moviendo servo de ");
  Serial.print(currentAngle);
  Serial.print("° a ");
  Serial.print(targetAngle);
  Serial.println("°");

  // Movimiento suave (interpolación)
  if (targetAngle > currentAngle) {
    // Mover hacia adelante
    for (int angle = currentAngle + 1; angle <= targetAngle; angle++) {
      myServo.write(angle);
      delay(STEP_DELAY_MS);
    }
  } else {
    // Mover hacia atrás
    for (int angle = currentAngle - 1; angle >= targetAngle; angle--) {
      myServo.write(angle);
      delay(STEP_DELAY_MS);
    }
  }

  currentAngle = targetAngle;
  Serial.print("Posición final: ");
  Serial.print(currentAngle);
  Serial.println("°");

  // Enviar confirmación por Bluetooth: "S90\n"
  SerialBT.print("S");
  SerialBT.print(currentAngle);
  SerialBT.print("\n");
}
