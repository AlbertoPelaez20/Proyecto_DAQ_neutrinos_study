#include <SoftwareSerial.h>

#define rxPin 10
#define txPin 11

// Configuración del objeto SoftwareSerial
SoftwareSerial mySerial(rxPin, txPin);

void setup() {
    // Definir los modos de pin para TX y RX
    pinMode(rxPin, INPUT);
    pinMode(txPin, OUTPUT);
    
    // Configurar las tasas de baudios para mySerial y Serial
    mySerial.begin(9600);
    Serial.begin(9600); // Abrir el puerto serie a 9600 bps
}

void loop() {
    // Verificar si hay datos disponibles en mySerial
    if (mySerial.available() > 0) {
        // Leer el dato recibido
        int receivedByte = mySerial.read();
        
        // Imprimir el dato recibido en formato hexadecimal en el monitor serial
        Serial.print("Received: 0x");
        Serial.println(receivedByte, HEX);
    }
}
