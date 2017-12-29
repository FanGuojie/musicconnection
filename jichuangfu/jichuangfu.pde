/*整合版本
Particles text effects

Uses particles with a seek behavior to make up a word.
The word is loaded into memory so that each particle can figure out their own position they need to seek.
Inspired by Daniel Shiffman's arrival explantion from The Nature of Code. (natureofcode.com)

Controls:
    - Left-click for a new word.
    - Drag & right-click over particles to interact with them.
    - Press any key to toggle draw styles.

Author:
  Jason Labbe

Site:
  jasonlabbe3d.com
*/


import processing.serial.*;

// Global variables
////
import ddf.minim.*;
import ddf.minim.analysis.*;
Minim minim;
AudioPlayer EDM;
BeatDetect beat;

float a, b;



int WIDTH = 800;
int HEIGHT = 400;
float ZOOM = 2.0;
int N = 150*(int)ZOOM;
float RADIUS = HEIGHT/10;
float SPEED = 0.0003;
float FOCAL_LENGTH = 0.5;
float BLUR_AMOUNT = 70;
int MIN_BLUR_LEVELS = 2;
int BLUR_LEVEL_COUNT = 4;
float ZSTEP = 0.008;
//back ground color:
int t = 10;
int y = 128;
int u = 144;
int intensy = 10;
color BACKGROUND = color(t, y, u);
float xoffs = 0;
float yoffs = 0;
Serial myPort;


ArrayList<Particle> particles = new ArrayList<Particle>();
int pixelSteps = 6; // Amount of pixels to skip
boolean drawAsPoints = false;
ArrayList<String> words = new ArrayList<String>();
int wordIndex = 0;
color bgColor = color(255, 100);
String fontName = "黑体";


class ZObject {
  float x, y, z, xsize, ysize;
  color bubble_color;
  color shaded_color;
  float vx, vy, vz;
 
  ZObject(float ix, float iy, float iz, color icolor) {
    x = ix;
    y = iy;
    z = iz;
    xsize = RADIUS;
    ysize = RADIUS;
    bubble_color = icolor;
    setColor();
    vx = random(-1.0, 1.0);
    vy = random(-1.0, 1.0);
    vz = random(-1.0, 1.0);
    float magnitude = sqrt(vx*vx + vy*vy + vz*vz);
    vx = SPEED * vx / magnitude;
    vy = SPEED * vy / magnitude;
    vz = SPEED * vz / magnitude;
    
  }
   void Resetsize(float x, float y){
    xsize = x;
    ysize = y;
    }
  void setColor() {
    float shade = z;
    float shadeinv = 1.0-shade;
    shaded_color = color( (red(bubble_color)*shade)+(red(BACKGROUND)*shadeinv),
                    (green(bubble_color)*shade)+(green(BACKGROUND)*shadeinv),
                    (blue(bubble_color)*shade)+(blue(BACKGROUND)*shadeinv));
  }
  
  void zoomIn(float step) {
    z += step;
    if (z > 1.0) {
      z = 0.0 + (z-1.0);
    }
  }
  
  void zoomOut(float step) {
    z -= step;
    if (z < 0.0) {
      z = 1.0 - (0.0-z);
    }
  }
 
  void update(boolean doZoomIn, boolean doZoomOut) {
    if (doZoomIn) {
      zoomIn(ZSTEP);
    }
    if (doZoomOut) {
      zoomOut(ZSTEP);
    }
    if (x <= 0) {
        vx = abs(vx);
        x = 0.0f;
    }
    if (x >= 1.0) {
        vx = -1.0 * abs(vx);
        x = 1.0;
    }
    if (y <= 0) {
        vy = abs(vy);
        y = 0.0f;
    }
    if (y >= 1.0) {
        vy = -1.0 * abs(vy);
        y = 1.0;
    }
    if (z < 0 || z > 1.0) {
        z = z % 1.0;
    }
    // float n = (noise(x, y) - 0.5) * 0.00001;
    // vx += n;
    // vy += n;
    x += vx;
    y += vy;
    //z += vz;
    setColor();
  }
 
  void draw(float xoffs, float yoffs) {
    float posX = (ZOOM*x*WIDTH*(1+z*z)) - ZOOM*xoffs*WIDTH*z*z;
    float posY = (ZOOM*y*HEIGHT*(1+z*z)) - ZOOM*yoffs*HEIGHT*z*z;
    float radius = z*xsize;
    if (posX> -xsize*2 && posX < WIDTH+xsize*2 && posY > -xsize*2 && posY < HEIGHT+xsize*2) {
        blurred_circle(posX, posY, radius, abs(z-FOCAL_LENGTH), shaded_color, MIN_BLUR_LEVELS + (z*BLUR_LEVEL_COUNT));
    }
  }
}
// This function will draw a blurred circle, according to the "blur" parameter. Need to find a good radial gradient algorithm.
void blurred_circle(float x, float y, float rad, float blur, color col, float levels) {
    float level_distance = BLUR_AMOUNT*(blur)/levels;
    for (float i=0.0; i<levels*2; i++) {
      fill(col, 255*(levels*2-i)/(levels*2));
      ellipse(x, y, rad+(i-levels)*level_distance, rad+(i-levels)*level_distance);
    }
}
ArrayList objects;
void sortBubbles() {
   
    // Sort them (this ensures that they are drawn in the right order)
    float last = 0;
    ArrayList temp = new ArrayList();
    for (int i=0; i<N; i++) {
        int index = 0;
        float lowest = 100.0;
        for (int j=0; j<N; j++) {
            ZObject current = (ZObject)objects.get(j);
            if (current.z < lowest && current.z > last) {
                index = j;
                lowest = current.z;
            }
        }
        temp.add(objects.get(index));
        last = ((ZObject)objects.get(index)).z;
    }
    objects = temp;
}
 
 
 



class Particle {
  PVector pos = new PVector(0, 0);
  PVector vel = new PVector(0, 0);
  PVector acc = new PVector(0, 0);
  PVector target = new PVector(0, 0);

  float closeEnoughTarget = 50;
  float maxSpeed = 4.0;
  float maxForce = 0.1;
  float particleSize = 5;
  boolean isKilled = false;

  color startColor = color(0);
  color targetColor = color(0);
  float colorWeight = 0;
  float colorBlendRate = 0.025;

  void move() {
    // Check if particle is close enough to its target to slow down
    float proximityMult = 1.0;
    float distance = dist(this.pos.x, this.pos.y, this.target.x, this.target.y);
    if (distance < this.closeEnoughTarget) {
      proximityMult = distance/this.closeEnoughTarget;
    }

    // Add force towards target
    PVector towardsTarget = new PVector(this.target.x, this.target.y);
    towardsTarget.sub(this.pos);
    towardsTarget.normalize();
    towardsTarget.mult(this.maxSpeed*proximityMult);

    PVector steer = new PVector(towardsTarget.x, towardsTarget.y);
    steer.sub(this.vel);
    steer.normalize();
    steer.mult(this.maxForce);
    this.acc.add(steer);

    // Move particle
    this.vel.add(this.acc);
    this.pos.add(this.vel);
    this.acc.mult(0);
  }

  void draw() {
    // Draw particle
    color currentColor = lerpColor(this.startColor, this.targetColor, this.colorWeight);
    if (drawAsPoints) {
      stroke(currentColor);
      point(this.pos.x, this.pos.y);
    } else {
      noStroke();
      fill(currentColor);
      //粒子的振动幅度（-0.1*intensy,+0.1*intensy）
      ellipse(this.pos.x+random(-0.1,0.1)*intensy, this.pos.y+random(-0.1,0.1)*intensy, this.particleSize, this.particleSize);
    }
    
    // Blend towards its target color
    if (this.colorWeight < 1.0) {
      this.colorWeight = min(this.colorWeight+this.colorBlendRate, 1.0);
    }
  }

  void kill() {
    if (! this.isKilled) {
      // Set its target outside the scene
      PVector randomPos = generateRandomPos(width/2, height/2, (width+height)/2);
      this.target.x = randomPos.x;
      this.target.y = randomPos.y;

      // Begin blending its color to black
      this.startColor = lerpColor(this.startColor, this.targetColor, this.colorWeight);
      this.targetColor = color(0);
      this.colorWeight = 0;

      this.isKilled = true;
    }
  }
}


// Picks a random position from a point's radius
PVector generateRandomPos(int x, int y, float mag) {
  PVector randomDir = new PVector(random(0, width), random(0, height));
  
  PVector pos = new PVector(x, y);
  pos.sub(randomDir);
  pos.normalize();
  pos.mult(mag);
  pos.add(x, y);
  
  return pos;
}


// Makes all particles draw the next word
void nextWord(String word) {
  // Draw word in memory
  PGraphics pg = createGraphics(width, height);
  pg.beginDraw();
  pg.fill(0);
  pg.textSize(100);
  pg.textAlign(CENTER);
  PFont font = createFont(fontName, 100);
  pg.textFont(font);
  pg.text(word, width/2, height/2);
  //pg.text(word, mouseX, mouseY);
  pg.endDraw();
  pg.loadPixels();

  // Next color for all pixels to change to
  color newColor = color(random(0.0, 255.0), random(0.0, 255.0), random(0.0, 255.0));

  int particleCount = particles.size();
  int particleIndex = 0;

  // Collect coordinates as indexes into an array
  // This is so we can randomly pick them to get a more fluid motion
  ArrayList<Integer> coordsIndexes = new ArrayList<Integer>();
  for (int i = 0; i < (width*height)-1; i+= pixelSteps) {
    coordsIndexes.add(i);
  }

  for (int i = 0; i < coordsIndexes.size (); i++) {
    // Pick a random coordinate
    int randomIndex = (int)random(0, coordsIndexes.size());
    int coordIndex = coordsIndexes.get(randomIndex);
    coordsIndexes.remove(randomIndex);
    
    // Only continue if the pixel is not blank
    if (pg.pixels[coordIndex] != 0) {
      // Convert index to its coordinates
      int x = coordIndex % width;
      int y = coordIndex / width;

      Particle newParticle;

      if (particleIndex < particleCount) {
        // Use a particle that's already on the screen 
        newParticle = particles.get(particleIndex);
        newParticle.isKilled = false;
        particleIndex += 1;
      } else {
        // Create a new particle
        newParticle = new Particle();
        
        PVector randomPos = generateRandomPos(width/2, height/2, (width+height)/2);
        newParticle.pos.x = randomPos.x;
        newParticle.pos.y = randomPos.y;
        
        newParticle.maxSpeed = random(2.0, 5.0);
        newParticle.maxForce = newParticle.maxSpeed*0.025;
        newParticle.particleSize = random(3, 6);
        newParticle.colorBlendRate = random(0.0025, 0.03);
        
        particles.add(newParticle);
      }
      
      // Blend it from its current color
      newParticle.startColor = lerpColor(newParticle.startColor, newParticle.targetColor, newParticle.colorWeight);
      newParticle.targetColor = newColor;
      newParticle.colorWeight = 0;
      
      // Assign the particle's new target to seek
      newParticle.target.x = x;
      newParticle.target.y = y;
    }
  }

  // Kill off any left over particles
  if (particleIndex < particleCount) {
    for (int i = particleIndex; i < particleCount; i++) {
      Particle particle = particles.get(i);
      particle.kill();
    }
  }
}


void setup() {
  myPort = new Serial(this,"COM4", 9600);  
  myPort.bufferUntil('\n'); 
  size(900, 500);
   smooth();
    noStroke();
    
      minim = new Minim(this);
  EDM = minim.loadFile("Showtek - Believer.mp3", 2048);
  EDM.loop();
  //fft = new FFT( EDM.bufferSize(), EDM.sampleRate() );
  beat = new BeatDetect(EDM.bufferSize(), EDM.sampleRate());
  
  
    
    objects = new ArrayList();
    // Randomly generate the bubbles
    for (int i=0; i<N; i++) {
        objects.add(new ZObject(random(1.0f), random(1.0f), random(1.0f), color(random(250, 255.0), random(250.0, 290.0), random(250.0, 290.0))));
    }

    sortBubbles();
    
    
  background(255);
  words.add("技创辅\n 智能打call");
  words.add("MusiConnection");
  words.add("Motion and Beat");
  nextWord(words.get(wordIndex));
}

void serialEvent(Serial p) {
String inString = p.readString();  
//print(inString);  
  if(inString.startsWith("T")){
     
    print(inString);
    String[] list = split(inString, ',');  
     for(int i = 0; i<3;i++){
       print(list[i]);
       //print("split is working");
     }
     print("split finished\n");
     //2号传感器控制背景气泡的靠近和远离
     
     if(list[1].equals("2")){
       print("2 node is coming");
       if(Double.parseDouble(list[2])>0.5) {
         zoomOut = false; 
         zoomIn = true;
          
       }
       if(Double.parseDouble(list[2])<0.5) {
       zoomIn = false; 
         zoomOut = true;
       }
     }
     //3号传感器控制改变字符，当第5个参数大于100时，换到下一个字符
     //3号传感器的第5个参数，用来控制粒子振动的幅度
     else if(list[1].equals("3")){
       print("node 3 is coming");
       if(Double.parseDouble(list[2]) >1) //设为100
       {
         try {
         wordIndex += 1;
    if (wordIndex > words.size()-1) { 
      wordIndex = 0;
    }
    nextWord(words.get(wordIndex));
    //
    //粒子振动的幅度
    intensy = abs((int)Double.parseDouble(list[2]));
         }catch(Exception e){
         print("node 3 is down");
         }
       }
       if(Double.parseDouble(list[2])<1){
       //暂不操作
       } 
     }
     //4号传感器用来控制背景颜色，第5个参数为正时，颜色变深；第5个参数为负时，颜色变浅。
     else if(list[1].equals("4")){
       print("node 4 is coming");
       
       
       t= 100 + 20*(int)Double.parseDouble(list[2]); 
       y=128 + 20*(int)Double.parseDouble(list[2]);
       u=144 + 20*(int)Double.parseDouble(list[2]);
     }
    BACKGROUND = color(t, y, u);
  }
}


boolean zoomIn = false;
boolean zoomOut = false;
int button=0;


void draw() {
  // Background & motion blur


 beat.detect(EDM.mix);
  if ( beat.isHat() ) {
    //isHat/isKick/isSnare/isRange/isOnset
    //a = 200;
    b = random(80,100);
  }
  
   background(BACKGROUND);
  xoffs = xoffs*0.9 + 0.1*mouseX/WIDTH;
  yoffs = yoffs*0.9 + 0.1*mouseY/HEIGHT;
   for (int i=0; i<N; i++) {
    ZObject current = (ZObject)objects.get(i);
    current.update(zoomIn, zoomOut);
  }
  sortBubbles();
  
  for (int i=0; i<N; i++) {
     ((ZObject)objects.get(i)).Resetsize(b,b*1.1);
    ((ZObject)objects.get(i)).draw(xoffs, yoffs);
  }
  
  
  
  
  fill(bgColor);
  noStroke();
  rect(0, 0, width*2, height*2);

  for (int x = particles.size ()-1; x > -1; x--) {
    // Simulate and draw pixels
    Particle particle = particles.get(x);
    particle.move();
    particle.draw();

    // Remove any dead pixels out of bounds
    if (particle.isKilled) {
      if (particle.pos.x < 0 || particle.pos.x > width || particle.pos.y < 0 || particle.pos.y > height) {
        particles.remove(particle);
      }
    }
  }
 fill(0,180,250);
  textSize(10);
   PFont font = createFont(fontName, 50);
textFont(font);
String tipText = "技创辅";
text(tipText, 0, height);
 b *= 0.95;
  //if ( a < 20 ) 
  //  a = 50;
  if ( b < 5 )
    b = 20;
}