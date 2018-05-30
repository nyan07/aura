import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
Kinect kinect;

PImage img;
float minThresh = 0.5;
float maxThresh = 0.8;

void setup() {
  size(640, 480);
  
  kinect = new Kinect(this);
  kinect.initDepth();
  
  arduino = new Arduino(this, Arduino.list()[3], 57600);
  arduino.pinMode(10, Arduino.OUTPUT);
  
  img = createImage(kinect.width, kinect.height, RGB);
}

void draw() {
  background(0);
  img.loadPixels();
  
  int[] depth = kinect.getRawDepth();
  int skip = 20;

  boolean turnOn = false;

  for (int x = 0; x < kinect.width; x += skip) {
    for (int y = 0; y < kinect.height; y += skip) {
      int offset = x + y * kinect.width;
      int d = depth[offset];
      float distanceInmeters = rawDepthToMeters(d);
      
      if (distanceInmeters > minThresh && distanceInmeters < maxThresh) {  
        img.pixels[offset] = color(255, 255, 255);
        turnOn = true;
      } else {
        img.pixels[offset] = color(0, 0, 0);
      } 
     }
  }
  
  arduino.digitalWrite(10, turnOn ? Arduino.HIGH : Arduino.LOW);
  
  img.updatePixels();
  image(img, 0, 0);
  
  turnOn = false;
}

// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}
