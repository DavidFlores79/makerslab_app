// Arduino UNO + HC-05 Bluetooth + DHT11 Temperature & Humidity Sensor
//
// Conexiones:
// - DHT11 VCC -> 5V Arduino
// - DHT11 GND -> GND Arduino
// - DHT11 DATA -> Pin 4 Arduino
// - HC-05 VCC -> 5V Arduino (o 3.3V si tu módulo lo requiere)
// - HC-05 GND -> GND Arduino
// - HC-05 TXD -> Pin 10 Arduino (RX software)
// - HC-05 RXD -> Pin 11 Arduino (TX software) + divisor de voltaje 5V->3.3V
//
// Bibliotecas necesarias:
// - DHT sensor library by Adafruit
// - Adafruit Unified Sensor
//
// Instalar desde: Sketch -> Include Library -> Manage Libraries -> buscar "DHT sensor library"

#include <SoftwareSerial.h>
#include <DHT.h>

// Configuración DHT11
#define DHTPIN 4       // Pin digital conectado al sensor DHT
#define DHTTYPE DHT11  // Tipo de sensor: DHT11

// Configuración Bluetooth HC-05
#define BT_RX 10       // Pin RX del Arduino conectado a TXD del HC-05
#define BT_TX 11       // Pin TX del Arduino conectado a RXD del HC-05 (con divisor de voltaje)

SoftwareSerial SerialBT(BT_RX, BT_TX); // RX, TX
DHT dht(DHTPIN, DHTTYPE);

unsigned long previousMillis = 0;
const long interval = 2000; // Intervalo de lectura: 2 segundos

void setup() {
  Serial.begin(9600);
  Serial.println("Arduino UNO + HC-05 + DHT11 iniciado");

  // Inicializar Bluetooth
  SerialBT.begin(9600); // Velocidad predeterminada del HC-05
  Serial.println("Bluetooth HC-05 listo");

  // Inicializar sensor DHT11
  dht.begin();
  Serial.println("Sensor DHT11 iniciado");
  Serial.println("Esperando conexión Bluetooth...");
}

void loop() {
  unsigned long currentMillis = millis();

  // ***** Manejo de comandos/heartbeats entrantes de Bluetooth *****
  while (SerialBT.available()) {
    char incomingChar = SerialBT.read();

    // Ping simple: si recibimos 'P' -> responder 'K' (ACK)
    if (incomingChar == 'P') {
      SerialBT.print("K\n"); // Enviar ACK
      Serial.println("Ping recibido -> enviado 'K'");

      // Consumir el resto de la línea si hay (ej. '\n')
      while (SerialBT.available() && SerialBT.peek() != '\n') {
        SerialBT.read();
      }
      if (SerialBT.available() && SerialBT.peek() == '\n') {
        SerialBT.read(); // Consumir '\n'
      }
    }
    // Puedes añadir más comandos aquí si los necesitas
  }

  // ***** Lecturas periódicas del sensor *****
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    // Leer humedad y temperatura
    float h = dht.readHumidity();
    float t = dht.readTemperature();

    // Verificar si la lectura falló
    if (isnan(h) || isnan(t)) {
      Serial.println("Error: Fallo al leer el sensor DHT11");
      SerialBT.print("ERROR\n");
      return;
    }

    // Mostrar en monitor serial
    Serial.print("Humedad: ");
    Serial.print(h);
    Serial.print(" %  Temperatura: ");
    Serial.print(t);
    Serial.println(" °C");

    // Enviar datos por Bluetooth en formato: "T:25.5|H:60.2\n"
    SerialBT.print("T:");
    SerialBT.print(t, 1); // 1 decimal
    SerialBT.print("|H:");
    SerialBT.print(h, 1); // 1 decimal
    SerialBT.print("\n");
  }

  delay(10); // Pequeña pausa para estabilidad
}
