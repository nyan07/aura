import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
Kinect kinect;

PImage threshold;
float minThresh = 0.5;
float maxThresh = 0.8;

int cols = 7;
int rows = 5;
int side = 92;
int top, left;

int radius = 10;

LED[][] matrix = new LED[cols][rows];

void setup() {
  size(1280, 480);
  
  kinect = new Kinect(this);
  kinect.initDepth();
  kinect.initVideo();
  
  arduino = new Arduino(this, Arduino.list()[3], 57600);
  for (int i=0; i < 14; i++){
    arduino.pinMode(i, Arduino.OUTPUT);
  }
  
  top = ((kinect.height - (side * rows)) / 2) + (side / 2);
  left =  ((kinect.width - (side * cols)) / 2) + (side / 2);
  
  threshold = createImage(kinect.width, kinect.height, RGB);
  
  int port = 0;
  
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      int x = left + side * i;
      int y = top + side * j;
      
      matrix[i][j] = new LED(x, y, radius, port);
      port++;
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
  
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      
      int x = (int) matrix[i][j].position.x - radius;
      int y = (int) matrix[i][j].position.y - radius;
      
      PImage newImg = threshold.get(x, y, radius*2, radius*2);
      LED led = matrix[i][j];
      
      //image(newImg, x, y);
   
      if (isAverageBlack(newImg)) {
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

// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}

boolean isAverageBlack(final PImage img) {
  img.loadPixels();
  color b = 0, w = 0;
 
  for (final color c : img.pixels) {
    if (c == color(255)) {
      w++;
    } else {
      b++;
    }
  }
 
  b /= img.pixels.length;
  w /= img.pixels.length;
 
  return b > w;
}
