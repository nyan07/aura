import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import processing.serial.*;

Kinect kinect;
PImage img;
float minThresh = 0.5;
float maxThresh = 0.8;

void setup() {
  size(640, 480);
  kinect = new Kinect(this);
  kinect.initDepth();
  img = createImage(kinect.width, kinect.height, RGB);
}

void draw() {
  background(0);
  img.loadPixels();
  
  int[] depth = kinect.getRawDepth();
  int skip = 20;

  for (int x = 0; x < kinect.width; x += skip) {
    for (int y = 0; y < kinect.height; y += skip) {
      int offset = x + y * kinect.width;
      int d = depth[offset];
      float distanceInmeters = rawDepthToMeters(d);
      
      if (distanceInmeters > minThresh && distanceInmeters < maxThresh) {  
        img.pixels[offset] = color(255, 255, 255);
      } else {
        img.pixels[offset] = color(0, 0, 0);
      } 
     }
  }
  
  img.updatePixels();
  image(img, 0, 0);
}

// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}
