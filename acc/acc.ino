//working with accelerometer MMA8452 KISS

#include <Wire.h>
#include "registers.h"

const byte scale = 2; //the scale on which we are working
const byte dataRate = 0;

#define SA0 1
#if SA0
  #define MMA8452_ADDRESS 0x1D  // SA0 is high, 0x1C if low
#else
  #define MMA8452_ADDRESS 0x1C
#endif

int int1Pin = 2;
int int2Pin = 3;

int accelerationCount[3];
float accelerationG[3];

byte readRegister(uint8_t address)
{
  byte data;
  //we send the address
  Wire.beginTransmission(MMA8452_ADDRESS);
  
  Wire.write(address);
  Wire.endTransmission(false); // do not end the transmision!

  Wire.requestFrom(MMA8452_ADDRESS, 1);
  data = Wire.read(); //get result
  Wire.endTransmission();

  return data;
}

void writeRegister(unsigned char address, unsigned char data)
{
  Wire.beginTransmission(MMA8452_ADDRESS);
  Wire.write(address);
  Wire.write(data);
  Wire.endTransmission();
}

void readRegisters(byte address, int i, byte * dest)
{
 Wire.beginTransmission(MMA8452_ADDRESS);//open communication with device
 Wire.write(address); //write the address
 Wire.endTransmission(false); // do not end the transmision!
 Wire.requestFrom(MMA8452_ADDRESS, i); 
 int j = 0;
 while(Wire.available())//slave may have sent less than requested
 {
    dest[j] = Wire.read();//read byte
    j++;//increment j
 }
 Wire.endTransmission(); //end the transmission
}

void MMA8452standby()
//consult the sheet for additional information
//we need this register to make the sensor to be in standby mode to modify it's contents
{
  byte c = readRegister(CTRL_REG1);
  writeRegister(CTRL_REG1, c & ~ (0x2A));
}

void MMA8452Active()
{
  byte c = readRegister(CTRL_REG1);
  writeRegister(CTRL_REG1 , c | 0x01);
}


void initMMA8452(byte fsr, byte dataRate)
{
  //we set the scaling bits
  if((fsr == 2)||(fsr == 4)||(fsr == 8))
    writeRegister(XYZ_DATA_CFG, fsr >> 2);
  else
    writeRegister(XYZ_DATA_CFG, 0);
  //we set the data rate
  writeRegister(CTRL_REG1, readRegister(CTRL_REG1) & ~ (0x38)); //default rate 1.56Hz
  if(dataRate <= 7)
    writeRegister(CTRL_REG1, readRegister(CTRL_REG1) | (dataRate << 3));
  //Let's set up Portrait/Landscape Functions

  writeRegister(PL_CFG, 0x40); //enable portrait
  writeRegister(PL_BF_ZCOMP, 0x44); //29 deg z lock(the angle at which the sensor can't detect the change in orientation)
  writeRegister(P_L_THS_REG, 0x84); //45 deg threeshold for portrait/landscape orientation
  writeRegister(PL_COUNT, 0x50); //debounce counter at 100ms(800Hz)

  //enable single or double tapping

  writeRegister(PULSE_CFG, 0x7F);//enable tapping on all axes
  writeRegister(PULSE_THSX, 0x20);// x thresh at 2g, multiply the value by 0.0625g/LSB to get the threshold
  writeRegister(PULSE_THSY, 0x20);// y thresh at 2g, multiply the value by 0.0625g/LSB to get the threshold
  writeRegister(PULSE_THSZ, 0x08);// z thresh at .5g, multiply the value by 0.0625g/LSB to get the threshold
  writeRegister(PULSE_TMLT, 0x30);// 30 ms threeshold for a sampling of 800Hz
  writeRegister(PULSE_TMLT, 0xA0);// 200 ms between taps minimum
  writeRegister(PULSE_WIND, 0xFF);// 318ms max value between taps

  //enable interrupts
  writeRegister(CTRL_REG3, 0x02);//active high, push-pull interrupts
  writeRegister(CTRL_REG4, 0x19);//data ready and portrait/landscape interrupt
  writeRegister(CTRL_REG5, 0x01);//data ready interrupt on INT1, Portrait/Landscape interrupt on INT2

  MMA8452Active();
}


void portraitLandscapeHandler()
{
  byte pl = readRegister(PL_STATUS);
  switch((pl & 0x06) >> 1)
  {
    case 0 :
      Serial.print("Portrait Up");
      break;
    case 1 :
      Serial.print("Portrait Down");
      break;
    case 2 :
      Serial.print("Portrait Right");
      break;
    case 3 :
      Serial.print("Portrait Left");
      break;
  }
  if(pl & 0x01)
    Serial.print("Back orientation");
  else
    Serial.print("Front orientation");
  if(pl & 0x40)
    Serial.print("Z tilt!");
  Serial.println();
}

void readAccelerationData(int * destination)
{
  byte rawData[6];  // x/y/z accel register data stored here
  readRegisters(OUT_X_MSB, 6, &rawData[0]);  // Read the six raw data registers into data array
  
  /* loop to calculate 12-bit ADC and g value for each axis */
  for (int i=0; i<6; i+=2)
  {
    destination[i/2] = ((rawData[i] << 8) | rawData[i+1]) >> 4;  // Turn the MSB and LSB into a 12-bit value
    if (rawData[i] > 0x7F)
    {  // If the number is negative, we have to make it so manually (no 12-bit data type)
      destination[i/2] = ~destination[i/2] + 1;
      destination[i/2] *= -1;  // Transform into negative 2's complement #
    }
  }
}

/* This function will read the status of the tap source register.
   And print if there's been a single or double tap, and on what
   axis. */
void tapHandler()
{
  byte source = readRegister(PULSE_SRC);  // Reads the PULSE_SRC register
  
  if ((source & 0x10)==0x10)  // If AxX bit is set
  {
    if ((source & 0x08)==0x08)  // If DPE (double puls) bit is set
      Serial.print("    Double Tap (2) on X");  // tabbing here for visibility
    else
      Serial.print("Single (1) tap on X");
      
    if ((source & 0x01)==0x01)  // If PoIX is set
      Serial.println(" +");
    else
      Serial.println(" -");
  }
  if ((source & 0x20)==0x20)  // If AxY bit is set
  {
    if ((source & 0x08)==0x08)  // If DPE (double puls) bit is set
      Serial.print("    Double Tap (2) on Y");
    else
      Serial.print("Single (1) tap on Y");
      
    if ((source & 0x02)==0x02)  // If PoIY is set
      Serial.println(" +");
    else
      Serial.println(" -");
  }
  if ((source & 0x40)==0x40)  // If AxZ bit is set
  {
    if ((source & 0x08)==0x08)  // If DPE (double puls) bit is set
      Serial.print("    Double Tap (2) on Z");
    else
      Serial.print("Single (1) tap on Z");
    if ((source & 0x04)==0x04)  // If PoIZ is set
      Serial.println(" +");
    else
      Serial.println(" -");
  }
}

void setup() {
  // put your setup code here, to run once:
  Wire.begin();
  Serial.begin(9600);//start the serial comunication with the pc
  pinMode(int1Pin, INPUT);
  digitalWrite(int1Pin, LOW);
  pinMode(int2Pin, INPUT);
  digitalWrite(int2Pin, LOW);

  //let's read the WHO_AM_I register for a test of communication
  byte c;
  c = readRegister(WHO_AM_I);
  if(c == 0x2A)
  {
    initMMA8452(scale, dataRate);
    Serial.println("Accelerometer MMA8452Q is online");
  }
  else
  {
    Serial.println("Can't connect to accelerometer.");
    Serial.println(c, HEX);
    while(1);//loop forever baby
  }
  
}

void loop() {
  // put your main code here, to run repeatedly:
  //if int 1 is true, new Data baby
  if(digitalRead(int1Pin) == 1)
  {
      /* print out values */
      readAccelerationData(accelerationCount);
      for(int i = 0; i < 3; i++)
      accelerationG[i] = (float) accelerationCount[i]/((1<<12)/ 2 * scale);
      for (int i=0; i<3; i++)
        {
          Serial.print(accelerationG[i], 4);  // Print g values
          Serial.print(" ");  // tabs in between axes
        }
      Serial.println();
  }
  if(digitalRead(int2Pin) == 1)
  {
    static byte source;
    source = readRegister(INT_SOURCE);
    if((source & 0x10) == 0x10)
      portraitLandscapeHandler();
    else if ((source & 0x08) == 0x08)
      tapHandler();
  }
  delay(100); //for visibility
}
