import processing.video.*;
import netP5.*;
import oscP5.*;
Capture cam;
int cellsize = 1;
int cols, rows;
float brightValue; 
float [] brightUnits;
OscP5 osc;
NetAddress supercollider;
void setup() {
  fullScreen(0);
  //size(1080,720);
  osc = new OscP5(this, 12000);
  supercollider = new NetAddress("194.95.203.214", 57120);

  String[] cameras = Capture.list();
  brightUnits = new float[height/10];

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    cam = new Capture(this, width, height, cameras[3]);
    cam.start();
  }
}

void draw() {
  if (cam.available() == true) {
    cam.read();
  }
  image(cam, 0, 0);
  //filter(THRESHOLD);
  cam.loadPixels();
  for (int unit = 0; unit < cam.height/10; unit++) {
    float brightUnit = 0;
    for (int u = 1; u < 10; u++) {
      int lineIndex = (unit * 10 + u);
      int locUnit = lineIndex * cam.width + cam.width/4;
      color colorValue = cam.pixels[locUnit];
      brightUnit += brightness(colorValue); //brightness 0 - 255 * 38 Units = 9290
    }
    brightUnits[unit] = brightUnit;
  }

  // draw red line indicator
  noStroke();
  fill(255, 0, 0);
  rect(width/4, 0, 3, height);
  //println(brightUnits);
  //sending OSC
  OscMessage value = new OscMessage("/drawingScore");
  value.add(brightUnits);
  osc.send(value, supercollider);
}
