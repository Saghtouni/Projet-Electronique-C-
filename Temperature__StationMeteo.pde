#include <WaspBLE.h>
#include <WaspLoRaWAN.h>
#include <string.h>
#include <math.h>

// Auxiliary variable
uint8_t aux = 0;

// MAC address of BLE device to find and connect.
char MAC[14] = "b0b448c44982";

char attributeData[20] = "att 1.0 written";
uint8_t error;
uint8_t PORT = 3;

// Device parameters for Back-End registration
char DEVICE_EUI[]  = "0102030405060709";			 
char APP_EUI[] = "1112131415161718";
char APP_KEY[] = "01020304050607080910111213141516";

void setup() 
{  
  USB.println(F("BLE_07 Example"));  

  // 0. Turn BLE module ON
  BLE.ON(SOCKET1);
  USB.println(F("LoRaWAN example - Send Unconfirmed packets (no ACK)\n"));


  USB.println(F("------------------------------------"));
  USB.println(F("Module configuration"));
  USB.println(F("------------------------------------\n"));

  //////////////////////////////////////////////
  // 1. Switch on
  //////////////////////////////////////////////

  error = LoRaWAN.ON(SOCKET0);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("1. Switch ON OK"));     
  }
  else 
  {
    USB.print(F("1. Switch ON error = ")); 
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 2. Set Device EUI
  //////////////////////////////////////////////

  error = LoRaWAN.setDeviceEUI(DEVICE_EUI);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("2. Device EUI set OK"));     
  }
  else 
  {
    USB.print(F("2. Device EUI set error = ")); 
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 3. Set Application EUI
  //////////////////////////////////////////////

  error = LoRaWAN.setAppEUI(APP_EUI);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("3. Application EUI set OK"));     
  }
  else 
  {
    USB.print(F("3. Application EUI set error = ")); 
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 4. Set Application Session Key
  //////////////////////////////////////////////

  error = LoRaWAN.setAppKey(APP_KEY);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("4. Application Key set OK"));     
  }
  else 
  {
    USB.print(F("4. Application Key set error = ")); 
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 5. Save configuration
  //////////////////////////////////////////////

  error = LoRaWAN.saveConfig();

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("5. Save configuration OK"));     
  }
  else 
  {
    USB.print(F("5. Save configuration error = ")); 
    USB.println(error, DEC);
  }
  
  USB.println(F("\n------------------------------------"));
  USB.println(F("Module configured"));
  USB.println(F("------------------------------------\n"));

  LoRaWAN.getDeviceEUI();
  USB.print(F("Device EUI: "));
  USB.println(LoRaWAN._devEUI);  

  LoRaWAN.getAppEUI();
  USB.print(F("Application EUI: "));
  USB.println(LoRaWAN._appEUI);  

  USB.println(); 
 
  //////////////////////////////////////////////
  // 6. Join network
  //////////////////////////////////////////////
  error = LoRaWAN.joinOTAA();

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("2. Join network OK"));
  }
  else 
  {
    USB.print(F("2. Join network error = ")); 
    USB.println(error, DEC);
  } 
}

void loop() 
{
  // 0. Turn BLE module ON
  BLE.ON(SOCKET1);
  
  // 1. Look for a specific device
  USB.println(F("First scan for device"));  
  USB.print("Look for device: ");
  USB.println(MAC);
  if (BLE.scanDevice(MAC) == 1)
  {
    //2. now try to connect with the defined parameters.
    USB.println(F("Device found. Connecting... "));
    aux = BLE.connectDirect(MAC);

    if (aux == 1) 
    {
      USB.print("Connected. connection_handle: ");
      USB.println(BLE.connection_handle, DEC);

      // 3. get RSSI of the link
      USB.print("RSSI:");
      USB.println(BLE.getRSSI(BLE.connection_handle), DEC);

      // Ecriture et lecture
      uint8_t activation[1];
      activation[0] = 1;
      BLE.attributeWrite(0,0x2C,activation,1);
      delay(1000);      
      BLE.attributeRead(0,0x29);
      USB.print("Accel value for device 0: ");
      for(uint8_t i = 0; i < BLE.attributeValue[0]; i++)
      {
        USB.printHex(BLE.attributeValue[i+1]);   
        USB.print(" ");   
      }
      USB.println();     
      
      USB.printHex(BLE.attributeValue[4]);
      USB.println();
      USB.printHex(BLE.attributeValue[3]);
      USB.println();
     
      uint16_t Afficher;
      Afficher = BLE.attributeValue[2] << 8 | BLE.attributeValue[1];     

      USB.print( Afficher);
      USB.println();     

      float taux_temperature;    
 
      taux_temperature = (float) (Afficher / 65536.0) *165.0 - 40.0;         
           
      char test[20];  
      char resultat[40];  
      Utils.float2String(taux_temperature, test, 2);
      USB.print(test);
      USB.println(); 
     
      uint16_t j = 0;
      while(test[j] != '\0')
      {
        j++;
      }
     
      USB.print(j);
      USB.println();
     
      Utils.hex2str((uint8_t*)test,resultat,j);     
      USB.print(resultat); 
      USB.println();  
      
      //////////////////////////////////////////////
      // 3. Send unconfirmed packet 
      //////////////////////////////////////////////

      error = LoRaWAN.sendUnconfirmed( PORT, resultat);

      // Error messages:
      /*
       * '6' : Module hasn't joined a network
       * '5' : Sending error
       * '4' : Error with data length	  
       * '2' : Module didn't response
       * '1' : Module communication error   
       */
      // Check status
      if( error == 0 ) 
      {
        USB.println(F("3. Send unconfirmed packet OK"));     
        if (LoRaWAN._dataReceived == true)
        { 
          USB.print(F("   There's data on port number "));
          USB.print(LoRaWAN._port,DEC);
          USB.print(F(".\r\n   Data: "));
          USB.println(LoRaWAN._data);
        }
      }
      else 
      {
        USB.print(F("3. Send unconfirmed packet error = ")); 
        USB.println(error, DEC);
      }    

      // 7. disconnect. Remember that after a disconnection, the slave becomes invisible automatically.
      BLE.disconnect(BLE.connection_handle);
      if (BLE.errorCode != 0) 
      {
        USB.println(F("Disconnect fail"));
      }
      else
      {
        USB.println(F("Disconnected."));
      } 
    }
    else
    {
      USB.println(F("NOT Connected"));  
    }
  }
  else
  {
    USB.println(F("Device not found: "));
  }

  USB.println();
  delay(5000);  
}
