import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
Kinect kinect;

PImage img;
float minThresh = 0;
float maxThresh = 1.8;

void setup() {
  size(1280, 480);
  
  kinect = new Kinect(this);
  kinect.initDepth();
  kinect.initVideo();
  
  arduino = new Arduino(this, Arduino.list()[3], 57600);
  arduino.pinMode(8, Arduino.OUTPUT);
  arduino.pinMode(9, Arduino.OUTPUT);
  arduino.pinMode(10, Arduino.OUTPUT);
  arduino.pinMode(11, Arduino.OUTPUT);
  arduino.pinMode(12, Arduino.OUTPUT);
  
  img = createImage(kinect.width, kinect.height, RGB);
  
}

void draw() {
  background(0);
  img.loadPixels();
  
  int[] depth = kinect.getRawDepth();
  int skip = 128;

  boolean turnOn = false;

  for (int x = 0; x < kinect.width; x += skip) {
    for (int y = 0; y < kinect.height; y += skip) {
      int offset = x + y * kinect.width;
      int d = depth[offset];
      float distanceInmeters = rawDepthToMeters(d);
      
      if (distanceInmeters > minThresh && distanceInmeters < maxThresh) {  
        img.pixels[offset] = color(255, 255, 255);
        ellipse(offset, offset, 30, 30);
               
        if (y == 128) {
           println(">>>>" + x + " " + y);
          if (x >= 0 && x < 128) {
             arduino.digitalWrite(8, Arduino.HIGH);
          } else if (x >= 128 && x < 256) {
             arduino.digitalWrite(9, Arduino.HIGH);        
          }  else if (x >= 256 && x < 384) {
             arduino.digitalWrite(10, Arduino.HIGH);        
          } else if (x >= 384 && x < 512) {
             arduino.digitalWrite(11, Arduino.HIGH);        
          } else {      
             arduino.digitalWrite(12, Arduino.HIGH);        
          }
        }
        
      } else {
        img.pixels[offset] = color(0, 0, 0);
        
        if (y == 128) {
          if (x >= 0 && x < 128) {
             arduino.digitalWrite(8, Arduino.LOW);
          } else if (x >= 128 && x < 256) {
             arduino.digitalWrite(9, Arduino.LOW);        
          }  else if (x >= 256 && x < 384) {
             arduino.digitalWrite(10, Arduino.LOW);        
          } else if (x >= 384 && x < 480) {
             arduino.digitalWrite(11, Arduino.LOW);        
          } else {
             arduino.digitalWrite(12, Arduino.LOW);        
          }
        } 
        
      } 
     }
  }
  
  arduino.digitalWrite(10, turnOn ? Arduino.HIGH : Arduino.LOW);
  
  img.updatePixels();
  image(kinect.getVideoImage(), 0, 0);
  image(img, 640, 0);
  
  
  turnOn = false;
}

// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}
