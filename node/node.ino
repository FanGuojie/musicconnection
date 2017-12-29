#include <Microduino_ColorLED.h> //引用彩灯库

#define PIN            D6         //彩灯引脚
#define NUMPIXELS      3         //级联彩灯数量

#define mic_pin A0
int micValue;

// Arduino Wire library is required if I2Cdev I2CDEV_ARDUINO_WIRE implementation
// is used in I2Cdev.h
#include "Wire.h"

// I2Cdev and MPU6050 must be installed as libraries, or else the .cpp/.h files
// for both classes must be in the include path of your project
#include "I2Cdev.h"
#include "MPU6050.h"

// class default I2C address is 0x68
// specific I2C addresses may be passed as a parameter here
// AD0 low = 0x68 (default for InvenSense evaluation board)
// AD0 high = 0x69
MPU6050 accelgyro;

int ax=1, ay=1, az;
int gx, gy, gz;
int ax1=0, ay1=0, az1=0;
int gx1=0, gy1=0, gz1=0;
int motion_speed;
int rotation_speed;



#include “Adafruit_NeoPixel.h”
Adafruit_NeoPixel strip = Adafruit_NeoPixel(1, 4, NEO_GRB + NEO_KHZ800);


#define NUM 4    //节点序号

// rf == == == == == == == == == == == == == == == == == == == =
#include <RF24Network.h>
#include <RF24.h>
#include <SPI.h>

// nRF24L01(+) radio attached using Getting Started board
RF24 radio(9, 10);
RF24Network network(radio);

const uint16_t id_host = 0;  //设置本机ID???????????????????????????????

boolean switch_key;
boolean switch_result;

struct send_a  //发送
{
  int rf_sensor_sta0;
};

struct receive_a  //接收
{
  int rf_sensor_result;   //结果
};

void setup() {
  // put your setup code here, to run once:
  Wire.begin();
  Serial.begin(9600);
  strip.begin();
  Serial.println("Hello Microduino");
  SPI.begin();    //初始化SPI总线
  radio.begin();
  network.begin(110, NUM);
      accelgyro.initialize();
	  strip.begin();                 //彩灯初始化
  strip.setBrightness(60);       //设置彩灯亮度
  strip.show();
  pinMode(mic_pin, INPUT);
}

void loop() {
	micValue = analogRead (mic_pin);
  Serial.println(micValue);

  if (micValue > 150)
  {
    strip.setAllLED(255, 255, 255);
    strip.show();
  }
  else
  {
    if (micValue > 100)
    {
      strip.setAllLED(255, 255, 0);
      strip.show();
    }
    else
    {
      strip.setAllLED(micValue * 2, 0, micValue * 2);
      strip.show();
    }
  }
  
    
  // put your main code here, to run repeatedly:
  network.update();
  // Is there anything ready for us?
  while ( network.available() )
  {
    // If so, grab it and print it out
    RF24NetworkHeader header;
    receive_a rec;
    network.read(header, &rec, sizeof(rec));

    switch_result = rec.rf_sensor_result;      //接收主机
    int i,a_=0,aa=0;
       accelgyro.getAcceleration(&ax, &ay, &az);
  for(i=0;i<20;i++)
  {
      int ax1=ax/1000,ay1=ay/1000,az1=az/1000;
      delay(5);
      accelgyro.getAcceleration(&ax, &ay, &az);
      aa+=(ax/1000-ax1)*(ax/1000-ax1)+(ay/1000-ay1)*(ay/1000-ay1)+(az/1000-az1)*(az/1000-az1);//加加速度
  }
  


  Serial.print(aa);
    {
      Serial.print("...Sending..NUM:");
       
      Serial.print(NUM);
      send_a sen = {
        aa
      };  //把这些数据发送出去，对应前面的发送数组

      RF24NetworkHeader header(id_host);
      
      boolean ok = network.write(header, &sen, sizeof(sen));
      if (ok)
        Serial.println("...ok.");
      else
        Serial.println("failed.");
    }
  }
//delay(150);
}
