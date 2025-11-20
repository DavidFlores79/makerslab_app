/*
 * Proyecto: Control de LED con Arduino UNO y Bluetooth HC-05
 * Descripción: Enciende y apaga un LED usando comandos Bluetooth.
 *
 * Hardware:
 * - Arduino UNO
 * - Módulo Bluetooth HC-05
 * - LED y Resistencia (220Ω)
 * - Botón (Opcional)
 *
 * Conexiones:
 * - LED Ánodo (+) -> Pin 13 Arduino
 * - LED Cátodo (-) -> GND Arduino
 * - HC-05 VCC -> 5V Arduino
 * - HC-05 GND -> GND Arduino
 * - HC-05 TXD -> Pin 10 Arduino (RX Software)
 * - HC-05 RXD -> Pin 11 Arduino (TX Software)
 * - Botón (Opcional) -> Pin 4 Arduino (Otro extremo a GND)
 *
 * Bibliotecas Requeridas:
 * - SoftwareSerial (Incluida en Arduino IDE)
 *
 * Comandos Bluetooth:
 * - 'P' -> Ping (Respuesta: 'K')
 * - '1' -> Encender LED
 * - '0' -> Apagar LED
 */

#include <SoftwareSerial.h>

// Configuración Bluetooth HC-05
#define BT_RX 10 // Pin RX del Arduino conectado a TXD del HC-05
#define BT_TX 11 // Pin TX del Arduino conectado a RXD del HC-05

// Configuración LED
#define LED_PIN 13 // Pin digital conectado al LED

// Configuración botón físico (opcional)
#define BUTTON_PIN 4 // Pin digital conectado al botón

SoftwareSerial SerialBT(BT_RX, BT_TX); // RX, TX

// Estados
int ledState = LOW;          // Estado actual del LED (LOW o HIGH)
int buttonState = LOW;       // Estado debounced del botón
int lastButtonReading = LOW; // Última lectura cruda del botón

// Debounce del botón
unsigned long lastDebounceTime = 0;
const unsigned long debounceDelay = 50; // Milisegundos

// Envío periódico del estado del LED
unsigned long lastSendMillis = 0;
const unsigned long sendInterval = 2000; // Enviar estado cada 2 segundos

String incomingBuffer = ""; // Buffer para comandos entrantes

void setup() {
  Serial.begin(9600);
  Serial.println("Control de LED Arduino UNO + HC-05 Iniciado");

  // Inicializar Bluetooth
  SerialBT.begin(9600); // Velocidad predeterminada del HC-05
  Serial.println("Bluetooth HC-05 listo");

  // Configurar pines
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP); // Botón con resistencia pull-up interna

  // Estado inicial del LED
  digitalWrite(LED_PIN, ledState);

  Serial.println("Sistema listo");
  Serial.println("Comandos: '0' = Apagar LED, '1' = Encender LED");
}

void loop() {
  // ***** Manejo de comandos entrantes de Bluetooth (no bloqueante) *****
  while (SerialBT.available()) {
    char c = SerialBT.read();

    // Ignorar retorno de carro
    if (c == '\r')
      continue;

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

  // ***** Debounce del botón físico (opcional) *****
  int reading = digitalRead(BUTTON_PIN);

  if (reading != lastButtonReading) {
    lastDebounceTime = millis();
    lastButtonReading = reading;
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (reading != buttonState) {
      buttonState = reading;

      // Botón activo LOW (con INPUT_PULLUP)
      if (buttonState == LOW) {
        // Alternar LED al presionar
        ledState = !ledState;
        digitalWrite(LED_PIN, ledState);

        Serial.print("Botón presionado -> LED: ");
        Serial.println(ledState ? "ENCENDIDO" : "APAGADO");

        // Enviar estado inmediato por Bluetooth
        sendLedState();
      }
    }
  }

  // ***** Envío periódico del estado del LED por Bluetooth *****
  if (millis() - lastSendMillis >= sendInterval) {
    lastSendMillis = millis();
    sendLedState();
  }

  delay(10); // Pequeña pausa para estabilidad
}

void processCommand(String cmd) {
  cmd.trim(); // Eliminar espacios en blanco

  if (cmd.length() == 0)
    return;

  Serial.print("Comando recibido: ");
  Serial.println(cmd);

  // ***** Ping simple: 'P' -> responder 'K' *****
  if (cmd.charAt(0) == 'P' || cmd.charAt(0) == 'p') {
    SerialBT.print("K\n");
    Serial.println("Ping -> enviado 'K'");
    return;
  }

  // ***** Control del LED: '0' = OFF, '1' = ON *****
  if (cmd == "0") {
    if (ledState != LOW) {
      ledState = LOW;
      digitalWrite(LED_PIN, ledState);
      Serial.println("LED apagado por comando BT");
    }
    sendLedState(); // Confirmar estado
  } else if (cmd == "1") {
    if (ledState != HIGH) {
      ledState = HIGH;
      digitalWrite(LED_PIN, ledState);
      Serial.println("LED encendido por comando BT");
    }
    sendLedState(); // Confirmar estado
  } else {
    Serial.print("Comando no reconocido: ");
    Serial.println(cmd);
    SerialBT.print("ERROR\n");
  }
}

void sendLedState() {
  // Enviar estado actual del LED: "0\n" o "1\n"
  SerialBT.print(ledState);
  SerialBT.print("\n");

  Serial.print("Estado LED enviado: ");
  Serial.println(ledState ? "ENCENDIDO (1)" : "APAGADO (0)");
}
