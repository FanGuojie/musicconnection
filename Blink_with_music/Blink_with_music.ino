#include <Microduino_ColorLED.h> //引用彩灯库

#define PIN            D6         //彩灯引脚
#define NUMPIXELS      3         //级联彩灯数量

#define mic_pin A0
int micValue;


ColorLED strip = ColorLED(NUMPIXELS, PIN); //将ColorLED类命名为strip，并定义彩灯数量和彩灯引脚号

void setup() {
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
}

