#include <SPI.h>
#include <WiFiNINA.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <ArduinoJson.h>
#include <math.h>

// Data wire is plugged into pin 2 on the Arduino
#define ONE_WIRE_BUS 2

#define MAX_TEMT_READINGS 40

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);
// Pass our oneWire reference to Dallas Temperature.
DallasTemperature sensors(&oneWire);

#include "arduino_secrets.h"
///////please enter your sensitive data in the Secret tab/arduino_secrets.h
char ssid[] = SECRET_SSID;        // your network SSID (name)
char pass[] = SECRET_PASS;    // your network password (use for WPA, or use as key for WEP)
int keyIndex = 0;                 // your network key Index number (needed only for WEP)

int status = WL_IDLE_STATUS;

int DHpin = 8; // input/output pin
byte dat[5];

int temt6000Readings[MAX_TEMT_READINGS];

WiFiServer server(80);

void setup() {
  //Initialize serial and wait for port to open:
  Serial.begin(9600);

  sensors.begin();

  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }

  Serial.begin(9600);
  pinMode(DHpin, OUTPUT);
  // check for the WiFi module:
  if (WiFi.status() == WL_NO_MODULE) {
    Serial.println("Communication with WiFi module failed!");
    // don't continue
    while (true);
  }

  String fv = WiFi.firmwareVersion();
  if (fv < WIFI_FIRMWARE_LATEST_VERSION) {
    Serial.println("Please upgrade the firmware");
  }

  // attempt to connect to Wifi network:
  while (status != WL_CONNECTED) {
    Serial.print("Attempting to connect to SSID: ");
    Serial.println(ssid);
    // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
    status = WiFi.begin(ssid, pass);

    // wait 10 seconds for connection:
    delay(10000);
  }
  server.begin();
  // you're connected now, so print out the status:
  printWifiStatus();
}



void returnResponse(WiFiClient client) {
  sensors.requestTemperatures(); // Send the command to get temperatures

  int lightSensorReading = analogRead(0);
  int temperature = sensors.getTempFByIndex(0);

  int totalOfReadings = 0;
  for (int i = 0; i < MAX_TEMT_READINGS; i++) {
    totalOfReadings += temt6000Readings[i];
  }


  int averageLightReading = round(totalOfReadings / MAX_TEMT_READINGS);
  
  StaticJsonDocument<300> doc;
  doc["light"] = averageLightReading;
  doc["temp"] = temperature;

  client.println("HTTP/1.0 200 OK");
  client.println("Content-Type: application/json");
  client.println();
  serializeJsonPretty(doc, client);

  client.stop();
}

int temtIterator = 0;
int sensorReadingIterator = 0;

void loop() {
  if (temtIterator > MAX_TEMT_READINGS) {
    temtIterator = 0;
  }

  if (sensorReadingIterator == 300) {
    //    Serial.println("READING");
    //    Serial.println(temtIterator);
    int temt6000Reading = analogRead(0);
    temt6000Readings[temtIterator] = temt6000Reading;
    temtIterator++;
    sensorReadingIterator = 0;
  } else {
    sensorReadingIterator++;
  }

  // listen for incoming clients
  WiFiClient client = server.available();
  if (client) {
    Serial.println("new client");
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        Serial.write(c);
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          // send a standard http response header
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: application/json");
          client.println("Connection: close");  // the connection will be closed after completion of the response


          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        } else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    returnResponse(client);

    // give the web browser time to receive the data
    delay(1);

    // close the connection:
    client.stop();
    Serial.println("client disconnected");
  }
}


void printWifiStatus() {
  // print the SSID of the network you're attached to:
  Serial.print("SSID: ");
  Serial.println(WiFi.SSID());

  // print your board's IP address:
  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);

  // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print("signal strength (RSSI):");
  Serial.print(rssi);
  Serial.println(" dBm");
}
