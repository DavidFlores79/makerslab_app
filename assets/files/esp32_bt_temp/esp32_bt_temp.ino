/*
 * Proyecto: Monitor de Temperatura y Humedad ESP32 Bluetooth
 * Descripción: Lee datos de un sensor DHT11 y los envía por Bluetooth.
 *
 * Hardware:
 * - Placa de desarrollo ESP32
 * - Sensor DHT11 (o DHT22)
 *
 * Conexiones:
 * - DHT11 VCC -> 3.3V o 5V (Depende del sensor)
 * - DHT11 GND -> GND
 * - DHT11 DATA -> GPIO 4
 *
 * Bibliotecas Requeridas:
 * - BluetoothSerial (Integrada en el núcleo Arduino ESP32)
 * - DHT sensor library (Adafruit)
 * - Adafruit Unified Sensor
 *
 * Comandos Bluetooth:
 * - 'P' -> Ping (Respuesta: 'K')
 * - Datos enviados periódicamente: "t25.5h60.2\n" (Temp 25.5, Hum 60.2)
 */

#include "BluetoothSerial.h"
#include "DHT.h"

#define DHTPIN 4      // Pin digital conectado al sensor DHT
#define DHTTYPE DHT11 // Tipo de sensor: DHT11

BluetoothSerial SerialBT;
DHT dht(DHTPIN, DHTTYPE);

unsigned long previousMillis = 0;
const long interval = 2000; // Intervalo de lectura: 2 segundos

void setup() {
  Serial.begin(115200);
  dht.begin();
  SerialBT.begin("ESP32_BT"); // Nombre del dispositivo Bluetooth
  Serial.println("Dispositivo iniciado. Empareja por Bluetooth!");
}

void loop() {
  unsigned long currentMillis = millis();

  // ***** Manejo de comandos/heartbeats entrantes de Bluetooth *****
  while (SerialBT.available()) {
    char incomingChar = SerialBT.read();

    // Ping simple: si recibimos 'P' -> responder 'K' (ACK)
    if (incomingChar == 'P') {
      SerialBT.print("K\n"); // Enviar ACK
      Serial.println("Ping recibido, enviando ACK 'K'");

      // Consumir el resto de la línea si hay (ej. '\n')
      while (SerialBT.available() && SerialBT.peek() != '\n') {
        SerialBT.read();
      }
      if (SerialBT.peek() == '\n')
        SerialBT.read(); // Consumir '\n'
    }
  }

  // ***** Lecturas periódicas *****
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    float h = dht.readHumidity();
    float t = dht.readTemperature();

    // Verificar si la lectura falló
    if (isnan(h) || isnan(t)) {
      Serial.println("¡Fallo al leer el sensor DHT!");
      return;
    }

    // Formato de datos: "t25.5h60.2\n"
    String data = "t" + String(t, 1) + "h" + String(h, 1) + "\n";
    Serial.print("Enviando: ");
    Serial.print(data);
    SerialBT.print(data);
    SerialBT.flush();
  }
  delay(15); // Pequeña pausa para estabilidad
}