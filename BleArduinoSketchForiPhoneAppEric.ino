#include<Adafruit_Sensor.h>
#include<DHT.h>
#include<DHT_U.h>
#include<SPI.h>
#include<Wire.h>

#include <SoftwareSerial.h>
SoftwareSerial mySerial(10,11);// where ble module plugged in

#define DHTPIN 13  // where thermometer is


#define DHTTYPE DHT11  //DHT SENSOR
DHT_Unified dht(DHTPIN, DHTTYPE, 30);


unsigned long old = 0;// for 2 minute timer between readings
const long interval = 120000;//1200000


int inF;// current temperature
int settemp;// number i sent from app to arduino

int lengthofarray; // used to get the two digits from app
char datastring[2];// array in which the two numbers for temperature are stored in

void setup() {
  mySerial.begin(9600);// begin sending data
Serial.begin(9600);// begin printing output to console
 pinMode(9, OUTPUT); // this is the pin for 5v relay that trips big relay
 while (mySerial.available())// while I can read data. Read data
 {
  Serial.write(mySerial.read());// print data from the ble module to the console
 }
 dht.begin();// start temperature sensor
 inF = readdegree();// take an initial reading of the temperature to send to the app
 lengthofarray = 0;// set the length of the array to zero so we do not lose any numbers in the array
 
 }

int readdegree(){// function to read the degree from temp sensor and then set it in an int
  delay(1000); //for stable measurement wait 1 second
  sensors_event_t event;// create event
  dht.temperature().getEvent(&event);// take temp

  if (isnan(event.temperature))
  {// if error trigger this
      Serial.println("Error Getting Temp");
      delay(3000);
  }
  int inF = (event.temperature *1.8)+32; //read degree convert it to celcuis
  return inF;// send back the temp int
}
void clearData(){// clears the character array sent from app
  while(lengthofarray !=0){
    datastring[lengthofarray--] = 0;  // clears the array
  }
  return;
}

void loop() {
     unsigned long current = millis(); // used so we only check temp and run relay every two mins

if(mySerial.available())// if connected and we can recive data start running
   {     
     char data = mySerial.read();// characters sent from app go to this character 
      if (data == 'd'){// a is sent from app to trigger a manual force on from app
        digitalWrite(9, HIGH);// turns relay on
        mySerial.write("ON");
      }
      if (data == 'a'){// d is the character send to manualy turn air off
        digitalWrite(9, LOW);// turn relay off
        mySerial.write("OFF");// send back to app the OFF keyword
      }
      else{// if their is no manual trigger it must be a number
        lengthofarray = lengthofarray + 1;// a number was enetered so the length of the array is now at least 1
        datastring[lengthofarray-1]=data;// enter the number sent from app in the first index of the array
       }
   //   for(int i = 0; i < lengthofarray; i++){   // CAN BE USED TO DEBUG WHAT IS IN THE ARRAY      NOT NEEDED HERE SO I DID NOT USE IT
     //   Serial.print(datastring[i]);
   //   }
      if (lengthofarray == 2){// if the array has two numbers in it
        settemp = atoi(datastring);// take those two numbers from the array and make them into an int to compare against the temperature in I already have
        clearData();// Clear the data that is in the array so we can start the process over again
      
      }
      Serial.println(data);
   }// end of reading from ble module
   inF = readdegree();// read the temp every time
   mySerial.println(inF);// serial . print sends varuiables over ble  Serial . write is only strings

  Serial.println(current);// print to console current time so that we know how much time is left before the air turns on
// I NEED TO SET TO 2 MINUTES BECAUSE THE TEMPERATURE SOMETIMES GETS STUCK ON THE SAME NUMBER SO WITHOUT THIS IT WOULD JUST GET STUCK IN A LOOP OF TURNING ITSELF ON AND OF MULTIPLE TIMES BECAUSE IT IS RIGHT ON THE NUMBER
  // TWO MINUTES IS ENOUGH TIME FOR THE TEMPERATURE OF THE ROOM TO CHANGE
  if(current - old>=interval)// all part of the 2 minute check
  {
    Serial.println(settemp);
    old = current;// set to current so the two minute check can start over
  if(inF <= settemp){// check if TEMP is sent it greater then current temp, TURN AIR OFF
    Serial.println("Turning Air OFF");
    digitalWrite(9, HIGH);

                    }
  if(inF > settemp){// IF TEMP IN FROM OVER TEH SET TEMP TURN IT OFF,, IT IS UNNESSACARY TO MAKE ROOM COLDER IF IT IS COLD ENOUGH
    Serial.println("Turning Air ON");
    digitalWrite(9, LOW);

                  }
  }

}

