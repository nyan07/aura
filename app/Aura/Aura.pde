import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import org.openkinect.tests.*;

import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
Kinect kinect;

PImage threshold;
float minThresh = 0;
float maxThresh = 1.5;

int cols = 7;
int rows = 5;
int side = 92;
int radius = 5;
int top, left;

LED[][] matrix = new LED[rows][cols];
int[][] ARDUINO_PORTS = {
  {  7,   6,   5,   4,   3,   2,   8 },
  { 14,  15,  16,  17,  18,  19,  20 },
  { 22,  24,  26,  28,  30,  32,  34 },
  { 40,  42,  44,  46,  48,  50,  52 },
  { 31,  33,  35,  37,  39,  41,  43 }
};

void setup() {
  size(1280, 480);
  
  kinect = new Kinect(this);
  kinect.initDepth();
  kinect.initVideo();    
  kinect.enableMirror(true);
  
  threshold = createImage(kinect.width, kinect.height, RGB);
 
  arduino = new Arduino(this, Arduino.list()[3], 57600);
  
  top = ((kinect.height - (side * rows)) / 2) + (side / 2);
  left = ((kinect.width - (side * cols)) / 2) + (side / 2);

  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      int x = left + side * j;
      int y = top + side * i;
      int port = ARDUINO_PORTS[i][j];
      
      matrix[i][j] = new LED(x, y, radius, port);
      arduino.pinMode(port, Arduino.OUTPUT);
    }
  }  
}

void draw() {
  background(0);
  threshold.loadPixels();
  
  int[] depth = kinect.getRawDepth();
 
  for (int x = 0; x < kinect.width; x++) {
    for (int y = 0; y < kinect.height; y++) {
      int offset = x + y * kinect.width;
        
      int d = depth[offset];
      float distanceInmeters = rawDepthToMeters(d);
      
      if (distanceInmeters > minThresh && distanceInmeters < maxThresh) {  
        threshold.pixels[offset] = color(255, 255, 255);        
      } else {
        threshold.pixels[offset] = color(0, 0, 0); 
      }
     }
  }
   
  threshold.updatePixels();
  image(kinect.getVideoImage(), 0, 0);
  image(threshold, 640, 0);
  
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      
      int x = (int) matrix[i][j].position.x - radius;
      int y = (int) matrix[i][j].position.y - radius;
      
      PImage point = threshold.get(x, y, radius*2, radius*2);
      LED led = matrix[i][j];
   
      if (isAverageBlack(point)) {
        led.turnOff();
        arduino.digitalWrite(led.port, Arduino.LOW);
      } else {
        led.turnOn();
        arduino.digitalWrite(led.port, Arduino.HIGH);
      }
    }
  } 
}

class LED {
  PVector position;
  int radius;
  int port;

  LED(int x, int y, int r, int p) {
    position = new PVector(x, y);
    radius = r;
    port = p;
  }
  
  void display(boolean turnOn) {
    stroke(255);
    fill(turnOn ? 255 : 0);
    ellipse(position.x, position.y, radius*2, radius*2);
    
  }
  
  void turnOn() {
    display(true);
  }
  
  void turnOff() {
    display(false);
  }
}

boolean isAverageBlack(final PImage point) {
  point.loadPixels();
  color b = 0, w = 0, white = color(255);
 
  for (final color c : point.pixels) {
    if (c == white) {
      w++;
    } else {
      b++;
    }
  }
 
  b /= point.pixels.length;
  w /= point.pixels.length;
 
  return b > w;
}

// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}
