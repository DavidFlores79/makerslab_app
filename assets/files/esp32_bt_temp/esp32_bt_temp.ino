#include "BluetoothSerial.h"
#include "DHT.h"

#define DHTPIN 4       // Pin digital conectado al sensor DHT
#define DHTTYPE DHT11  // DHT11

BluetoothSerial SerialBT;
DHT dht(DHTPIN, DHTTYPE);

unsigned long previousMillis = 0;
const long interval = 2000; // 2 segundos

void setup() {
  Serial.begin(115200);
  dht.begin();
  SerialBT.begin("ESP32_BT");
  Serial.println("Dispositivo iniciado. Empareja por Bluetooth!");
}

void loop() {
  unsigned long currentMillis = millis();

  // ***** Manejo de comandos/heartbeats entrantes de Bluetooth *****
  while (SerialBT.available()) {
    char incomingChar = SerialBT.read();
    // Serial.print("Recibido por BT: "); // Descomentar para depuración
    // Serial.println(incomingChar);      // Descomentar para depuración

    if (incomingChar == 'P') { // Si recibimos un 'P' (parte del ping 'P\n')
      // Podemos enviar un ACK para indicar que estamos vivos y recibiendo
      SerialBT.print("K\n"); // 'K' de 'OK' + nueva línea
      Serial.println("Ping recibido, enviando ACK 'K'"); // Para depuración
      // También es buena idea limpiar el resto de la línea del ping si esperas '\n'
      while (SerialBT.available() && SerialBT.peek() != '\n') {
        SerialBT.read(); // Consume el resto del ping (ej. el '\n')
      }
      if (SerialBT.peek() == '\n') SerialBT.read(); // Consume el '\n'
    }
    // Puedes añadir aquí más lógica para otros comandos si los necesitas
  }

  // Lecturas periódicas
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    float h = dht.readHumidity();
    float t = dht.readTemperature();

    if (isnan(h) || isnan(t)) {
      Serial.println("Fallo al leer el sensor DHT!");
      return;
    }

    String data = "t" + String(t, 1) + "h" + String(h, 1) + "\n";
    Serial.println(data);
    SerialBT.print(data);
    SerialBT.flush();
  }
  delay(15);
}