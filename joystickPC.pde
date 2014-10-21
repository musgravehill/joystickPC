import controlP5.*;
import processing.serial.*;

//serial
DropdownList dropdownSerialPorts;              
Serial mySerialPort;                    
int selectedSerialPortNumber;                         
String[] listSerialPorts;               
boolean isSerialPortSet;               
boolean isSerialPortSelect = false;  

//common
ControlP5 controlP5;
String stringToArduino;
int displayWidth = 400;
int displayHeight = 200;
final static String CONST_ICON  = "icon.png";
final static String CONST_TITLE = "Joystick Bob";

//timers
long prevTime50 = 0;

//rover control
float pult_rover_renderWidth=200; //px
float pult_rover_renderHeight=200; //px
float pult_rover_maxJoystickAmplitude=pult_rover_renderWidth/2;     //Maximum pultstick range === pult_rover_renderWidth/2 
float pult_rover_curJoystickAngle;     //Current pultstick angle RADIAN -PI..+PI
float pult_rover_curJoystickAmplitude;     //Current pultstick range
float pult_rover_renderCenterX=100;  //Joystick displayed Center X
float pult_rover_renderCenterY=100;  //Joystick displayed Center Y
boolean isMouseTracking=false;
float pult_rover_throttleRaw, pult_rover_yawRaw;
int pult_rover_throttle, pult_rover_yaw;

//camera control
int pult_cam_panRaw, pult_cam_tiltRaw;
int pult_cam_pan, pult_cam_tilt;
PImage camImg;

/*
//arm
 int pult_arm_shoulder_elevation, pult_arm_wrist_pitch, pult_arm_wrist_roll, pult_arm_jaw;
 int pult_arm_shoulder_elevation, pult_arm_wrist_pitch, pult_arm_wrist_roll, pult_arm_jaw;
 PImage armImg;
 */

void setup() {    
  //timers
  prevTime50 = millis();

  //common
  size(displayWidth, displayHeight);      
  smooth();  
  changeAppIcon(loadImage(CONST_ICON));
  frame.setTitle(CONST_TITLE);   
  strokeWeight(10.0);   
  controlP5 = new ControlP5(this); 

  //serial  
  dropdownSerialPorts = controlP5.addDropdownList("dropdownSerialPorts", 240, 20, 100, 84); //left,top, w,h
  dropdownSerialPorts.setBackgroundColor(color(200));   
  dropdownSerialPorts.captionLabel().set("Select COM port");  
  dropdownSerialPorts.captionLabel().style().marginTop = 3;  
  dropdownSerialPorts.captionLabel().style().marginLeft = 3;  
  dropdownSerialPorts.valueLabel().style().marginTop = 3;
  dropdownSerialPorts.setColorBackground(color(60));  
  dropdownSerialPorts.setColorActive(color(0, 200, 0));
  dropdownSerialPorts.enableCollapse();
  dropdownSerialPorts.setItemHeight(20);
  //dropdownSerialPorts.actAsPulldownMenu(true);
  dropdownSerialPorts.setBarHeight(15); 
  listSerialPorts = Serial.list();   
  for (int i = 0; i < listSerialPorts.length; i++) {       
    dropdownSerialPorts.addItem(listSerialPorts[i], i);
  }

  //cam control
  Slider pult_cam_panRawSlider = controlP5.addSlider("pult_cam_panRaw")
    .setPosition(220, 170)
      .setSize(150, 20)
        .setRange(0, 1000)
          .setValue(500)     
            .setSliderMode(Slider.FLEXIBLE)   
              .setColorActive(color(0, 0, 0))
                .setColorForeground(color(80, 90, 80))
                  .setColorBackground(color(121, 175, 108))      
                    ;
  pult_cam_panRawSlider.valueLabel().setVisible(false);  
  pult_cam_panRawSlider.captionLabel().setVisible(false);   

  Slider pult_cam_tiltRawSlider = controlP5.addSlider("pult_cam_tiltRaw")
    .setPosition(350, 10)
      .setSize(20, 150)
        .setRange(0, 1000)
          .setValue(500)     
            .setSliderMode(Slider.FLEXIBLE)
              .setColorActive(color(0, 0, 0))
                .setColorForeground(color(80, 90, 80))
                  .setColorBackground(color(121, 175, 108))
                    ;
  pult_cam_tiltRawSlider.valueLabel().setVisible(false); 
  pult_cam_tiltRawSlider.captionLabel().setVisible(false); 

  camImg = loadImage("camImg.png");

  /*
  //arm control    
   Slider pult_arm_shoulder_elevationSlider = controlP5.addSlider("pult_arm_shoulder_elevation")
   .setPosition(525, 125)
   .setSize(80, 10)
   .setRange(0, 1000)
   .setValue(1000)     
   .setSliderMode(Slider.FLEXIBLE)
   .setColorActive(color(0, 0, 0))
   .setColorForeground(color(80, 90, 80))
   .setColorBackground(color(121, 175, 108))
   ;
   pult_arm_shoulder_elevationSlider.valueLabel().setVisible(false); 
   pult_arm_shoulder_elevationSlider.captionLabel().setVisible(false);
   
   Slider pult_arm_wrist_pitchSlider = controlP5.addSlider("pult_arm_wrist_pitch")
   .setPosition(480, 20)
   .setSize(80, 10)
   .setRange(0, 1000)
   .setValue(500)     
   .setSliderMode(Slider.FLEXIBLE)
   .setColorActive(color(0, 0, 0))
   .setColorForeground(color(80, 90, 80))
   .setColorBackground(color(121, 175, 108))
   ;
   pult_arm_wrist_pitchSlider.valueLabel().setVisible(false); 
   pult_arm_wrist_pitchSlider.captionLabel().setVisible(false);
   
   Slider pult_arm_wrist_rollSlider = controlP5.addSlider("pult_arm_wrist_roll")
   .setPosition(420, 80)
   .setSize(80, 10)
   .setRange(0, 1000)
   .setValue(0)     
   .setSliderMode(Slider.FLEXIBLE)
   .setColorActive(color(0, 0, 0))
   .setColorForeground(color(80, 90, 80))
   .setColorBackground(color(121, 175, 108))
   ;
   pult_arm_wrist_rollSlider.valueLabel().setVisible(false); 
   pult_arm_wrist_rollSlider.captionLabel().setVisible(false);
   
   Slider pult_arm_jawSlider = controlP5.addSlider("pult_arm_jaw")
   .setPosition(400, 130)
   .setSize(80, 10)
   .setRange(0, 1000)
   .setValue(0)     
   .setSliderMode(Slider.FLEXIBLE)
   .setColorActive(color(0, 0, 0))
   .setColorForeground(color(80, 90, 80))
   .setColorBackground(color(121, 175, 108))
   ;
   pult_arm_jawSlider.valueLabel().setVisible(false); 
   pult_arm_jawSlider.captionLabel().setVisible(false); 
   
   armImg = loadImage("armImg.png");
   */
}

void draw()
{    
  //common  
  background(240);  
  noStroke();

  //timers
  int currTime = millis();
  if (prevTime50 + 50 <= currTime) {
    prevTime50 = currTime;
    timer50();
  }

  //camera control
  image(camImg, 240, 40, 100, 100);

  /*
  //arm control
   image(armImg, 400, 0, 200, 200);
   */

  //rover control
  fill(121, 175, 108);
  ellipse(pult_rover_renderCenterX, pult_rover_renderCenterY, pult_rover_renderHeight, pult_rover_renderWidth);
  stroke(0, 0, 0);  
  ellipse(pult_rover_renderCenterX, pult_rover_renderCenterY, 20, 20);
  float dx = mouseX - pult_rover_renderCenterX;
  float dy = mouseY - pult_rover_renderCenterY;
  if ( mousePressed && (mouseButton == LEFT) && (mouseX <= pult_rover_renderWidth) && (mouseY <= pult_rover_renderHeight) ) {
    isMouseTracking = true;
  }
  if ( !mousePressed ) {  //if ( mousePressed && (mouseButton == RIGHT) )
    isMouseTracking = false;
  }
  if (isMouseTracking) {
    pult_rover_curJoystickAngle = atan2(dy, dx);
    pult_rover_curJoystickAmplitude = dist(mouseX, mouseY, pult_rover_renderCenterX, pult_rover_renderCenterY);
    if (pult_rover_curJoystickAmplitude > pult_rover_maxJoystickAmplitude) {
      pult_rover_curJoystickAmplitude = pult_rover_maxJoystickAmplitude;
    }
  } else {
    pult_rover_curJoystickAmplitude = 0;
  }
  renderPultStick(pult_rover_renderCenterX, pult_rover_renderCenterY, pult_rover_curJoystickAngle);

  pult_rover_yawRaw = round(pult_rover_curJoystickAngle * 1000); 
  if ( (pult_rover_curJoystickAngle > 0)  & (pult_rover_curJoystickAngle < 3143)    ) {    
    pult_rover_throttleRaw = - 5 * pult_rover_curJoystickAmplitude; //normalize coeff
    pult_rover_yawRaw = 500 - pult_rover_yawRaw * 1000/3142; //normalize coeff
  } else {    
    pult_rover_throttleRaw = 5 * pult_rover_curJoystickAmplitude; //normalize coeff
    pult_rover_yawRaw = 500 + pult_rover_yawRaw * 1000/3142; //normalize coeff
  }     
  //center
  if(abs(pult_rover_throttleRaw) < 5){  
     pult_rover_yawRaw = 0;
  }

  pult_rover_throttle = round(pult_rover_throttleRaw);
  pult_rover_yaw = round(pult_rover_yawRaw);
  pult_cam_pan = -500 + pult_cam_panRaw;
  pult_cam_tilt = -500 + pult_cam_tiltRaw;
}

void timer50() {
  sendDataToController();
}

void renderPultStick(float x, float y, float a)
{
  pushMatrix();
  translate(x, y);
  rotate(a);  
  line(0, 0, pult_rover_curJoystickAmplitude, 0);
  popMatrix();
}

void changeAppIcon(PImage img) {
  final PGraphics pg = createGraphics(16, 16, JAVA2D);
  pg.beginDraw();
  pg.image(img, 0, 0, 16, 16);
  pg.endDraw();
  frame.setIconImage(pg.image);
}

void sendDataToController() {
  stringToArduino = "[" + pult_rover_throttle;
  stringToArduino += "," + pult_rover_yaw;
  stringToArduino += "," + pult_cam_pan;
  stringToArduino += "," + pult_cam_tilt;
  stringToArduino += "]";

  if (isSerialPortSet == true) { 
    mySerialPort.write(stringToArduino);
  }
  debugOutSerial(); //DEBUG
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isGroup()) 
  {
    //Store the value of which box was selected, we will use this to acces a string (char array).
    float S = theEvent.group().value();
    //Since the list returns a float, we need to convert it to an int. For that we us the int() function.
    selectedSerialPortNumber = int(S);
    //With this code, its a one time setup, so we state that the selection of port has been done. You could modify the code to stop the serial connection and establish a new one.

    if (isSerialPortSet == true) { 
      mySerialPort.stop();
    }
    isSerialPortSelect = true;
    isSerialPortSet = false;

    if (isSerialPortSelect == true && isSerialPortSet == false) {      
      startSerial();
    }
  }
}

void startSerial() {   
  mySerialPort = new Serial(this, listSerialPorts[selectedSerialPortNumber], 115200);
  isSerialPortSet = true;
}

void debugOutSerial() {
  println("out="+stringToArduino);
  /*
   print("thr=");
   print(pult_rover_throttle);
   print(" yaw=");
   print(pult_rover_yaw);
   print(" pan=");
   print(pult_cam_pan);
   print(" tilt=");
   print(pult_cam_tilt);
   println(" ");
   */
}

void debugInSerial() {
  if (isSerialPortSet == true) { 
    while (mySerialPort.available () > 0) {
      String inBuffer = mySerialPort.readString();   
      if (inBuffer != null) {
        println("in="+inBuffer);
      }
    }
  }
}

