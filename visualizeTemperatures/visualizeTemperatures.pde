/*
 *  VisualizeTemperatures.pde
 *
 *  A simple Processing Sketch which listens to a  
 *  Teensy 3.1+ Arduino board connected to a Melexis MLX90621
 *  and visualizes the temperature values measured by its 
 *  4x16 matrix as a color matrix 
 *
 *  WARNING!
 *  Per 11.10.2015 this script was adapted through quick and dirty copy and paste programming.
 *  This enabled me to demonstrate, and make use of, some alternative visualisations during measurement.
 *  The resulting code needs to be cleaned up and refactored.
 *
 *  Created on: 9.7.2015
 *      Author: Robin van Emden
 */

import org.jnativehook.GlobalScreen;
import org.jnativehook.NativeHookException;
import org.jnativehook.keyboard.NativeKeyEvent;
import org.jnativehook.keyboard.NativeKeyListener;
import java.util.logging.ConsoleHandler;
import java.util.logging.Formatter;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.logging.Logger;

import processing.serial.*;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Arrays; 
import java.text.SimpleDateFormat;
import java.util.Date;

public static final boolean  WRITE_TO_FILE = true;

PrintWriter output;
Serial serialConnection;
String sensorReading;
String[] serialString;  
String serialCheck;  
String portName = "eensy"; 
int portNumber;  
int serialIndex;  
Double temperatureToString;
double[][] drawTemperatures2D;
double[][] temperatures2D;
double H, S, B;
boolean waitFirstNewline;
SMA[][] sma2D = new SMA[4][16];
SMA[][] sma2Dlong = new SMA[4][16];
SimpleDateFormat sdf;
double[] tempValues1D[];
PImage img;
double[][] quadrant = new double[4][16];
double[][] quadrantLong = new double[4][16];
boolean spaceCheck = false;
String pressedSpace = "";

void setup() {
   
  // log global keypress
  try {
    // Get the logger for "org.jnativehook" and set the level to warning.
    Logger logger = Logger.getLogger(GlobalScreen.class.getPackage().getName());
    logger.setLevel(Level.WARNING);
    GlobalScreen.registerNativeHook();
    GlobalScreen.addNativeKeyListener(new GlobalKeyListenerExample());
  }
  catch (NativeHookException ex) {
    System.err.println("There was a problem registering the native hook.");
    System.err.println(ex.getMessage());
  }


  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 16; j++) {  
      sma2D[i][j]= new SMA(6);
      sma2Dlong[i][j]= new SMA(40);
    }
  }  
  img = createImage(16, 4, RGB);
  img.loadPixels(); 
  if (WRITE_TO_FILE) {
    sdf = new SimpleDateFormat("yyyy_MM_dd_HH_mm_ss_SSS");  
    output = createWriter(sdf.format(new Date())+"_output.txt");
  }
  size(900, 600);

  waitFirstNewline = false;
  sensorReading="";

  findSerialPort(); 
  try {
    serialConnection = new Serial(this, Serial.list()[portNumber], 19200);  
    serialConnection.bufferUntil('\n');
  } 
  catch (RuntimeException e) {
    noLoop();
    System.out.println("Connection to serial failed");
  }
}


public class GlobalKeyListenerExample implements NativeKeyListener {
  public void nativeKeyPressed(NativeKeyEvent e) {
    System.out.println("Key Pressed: " + NativeKeyEvent.getKeyText(e.getKeyCode()));
    if (NativeKeyEvent.getKeyText(e.getKeyCode()) == "Space") {
      spaceCheck = true;
    }
  }
  public void nativeKeyReleased(NativeKeyEvent e) {
    //System.out.println("Key Released: " + NativeKeyEvent.getKeyText(e.getKeyCode()));
  }
  public void nativeKeyTyped(NativeKeyEvent e) {
    //System.out.println("Key Typed: " + NativeKeyEvent  .getKeyText(e.getKeyCode()));
  }
}


void serialEvent (Serial serialConnection) {
  sensorReading = serialConnection.readStringUntil('\n');
  if (sensorReading != null) {
    if (waitFirstNewline) {
      sensorReading=trim(sensorReading);
    } else {
      serialConnection.clear();
      waitFirstNewline = true;
    }
  }
}

void draw() {
  background(0);
  translate(35, 35);
  fill(255);
  noStroke();
  drawTemperatures2D = parseInput(sensorReading);

  if (drawTemperatures2D!=null) {
    if (WRITE_TO_FILE) {

      if (spaceCheck) {
          pressedSpace = "1";
          spaceCheck = false;
      } else {
          pressedSpace = "0";
      }
      output.println(pressedSpace+"~"+sdf.format(new Date())+"~"+sensorReading); 
      output.flush();
    }

    for (int i = 15; i >= 0; i--) {  
      pushMatrix();
      for (int j = 0; j < 4; j++) {


        img.pixels[i+j*16]=getColor(((drawTemperatures2D[j][i]-33)/7));
        fill(getColor(((drawTemperatures2D[j][i]-33)/7)));
        rect(0, 0, 30, 30);
        textSize(10);
        fill(0);
        temperatureToString = (double) Math.round(drawTemperatures2D[j][i] * 10) / 10;
        text(temperatureToString.toString(), 4, 20);
        translate(0, 40);
      }
      popMatrix();
      translate(40, 0);
    }
  }




  translate(-640, 185);

  img.filter(BLUR);
  img.updatePixels();



  pushMatrix();
  scale(-1.0, 1.0);
  image(img, -630, 0, 630, 150);
  img.filter(GRAY);
  img.filter(THRESHOLD);

  image(img, -665-150, 0, 150, 150);

  popMatrix();

  translate(0, 185);
  fill(255);
  noStroke();
  if (drawTemperatures2D!=null) {
    int LT = 0, RT = 0, LB = 0, RB = 0;
    for (int i = 15; i >= 0; i--) {  
      pushMatrix();
      for (int j = 0; j < 4; j++) {
        double longValue = sma2Dlong[j][i].compute(drawTemperatures2D[j][i]);
        double shortValue = sma2D[j][i].compute(drawTemperatures2D[j][i]);
        if (j<2 && i<8) {
          quadrant[0][LT]=shortValue; 
          quadrantLong[0][LT]=longValue;
          LT++;
        }
        if (j<2 && i>=8) {
          quadrant[1][RT]=shortValue; 
          quadrantLong[1][RT]=longValue;
          RT++;
        }
        if (j>=2 && i<8) {
          quadrant[2][LB]=shortValue; 
          quadrantLong[2][LB]=longValue;
          LB++;
        }
        if (j>=2 && i>=8) {
          quadrant[3][RB]=shortValue; 
          quadrantLong[3][RB]=longValue;
          RB++;
        }
        double nowValue = longValue - shortValue;
        if (nowValue<-0.4) { 
          fill(#FF0000);
        } else if (nowValue>0.4) { 
          fill(#0000FF);
        } else { 
          fill(#AAAAAA);
        }
        rect(0, 0, 30, 30);
        textSize(10);
        fill(0);
        temperatureToString = -(double) Math.round(nowValue * 10) / 10;
        text(temperatureToString.toString(), 4, 20);
        translate(0, 40);
      }
      popMatrix();
      translate(40, 0);
    }
  }

  translate(105, -370);
  if (drawTemperatures2D!=null) {
    pushMatrix();
    for (int j = 0; j < 4; j++) {
      fill(getColor(((mean(quadrant[j])-33)/7)));
      rect(0, 0, 70, 70);
      textSize(10);
      fill(0);
      temperatureToString = (double) Math.round(mean(quadrant[j]) * 10) / 10;
      text(temperatureToString.toString(), 4, 20);
      if (j==0)translate(-80, 0);
      if (j==1)translate(80, 80);
      if (j==2)translate(-80, 0);
    }
    popMatrix();
  }

  translate(0, 370);
  if (drawTemperatures2D!=null) {
    pushMatrix();
    for (int j = 0; j < 4; j++) {
      double averagedValues = (mean(quadrantLong[j]) - mean(quadrant[j]));
      if (averagedValues<-0.2) { 
        fill(#FF0000);
      } else if (averagedValues>0.2) { 
        fill(#0000FF);
      } else { 
        fill(#AAAAAA);
      }
      rect(0, 0, 70, 70);
      textSize(10);
      fill(0);
      temperatureToString = -(double) Math.round(averagedValues * 10) / 10;
      text(temperatureToString.toString(), 4, 20);
      if (j==0)translate(-80, 0);
      if (j==1)translate(80, 80);
      if (j==2)translate(-80, 0);
    }
    popMatrix();
  }
}

double[][] parseInput(String input) {
  String[] temperatureRows;
  temperatureRows = input.split("~");
  if (temperatureRows.length<4) return null;
  temperatures2D = new double[temperatureRows.length][];
  int i= 0;
  String[] temperatureCols;
  for (String row : temperatureRows) {
    row = row.substring(1, row.length()-1);
    temperatureCols = row.split(",");
    if (temperatureCols.length<16) return null;
    int j = 0;
    temperatures2D[i] = new double[temperatureCols.length];
    for (String col : temperatureCols) {
      try {
        temperatures2D[i][j++] = Double.parseDouble(col);
      }
      catch(NumberFormatException ex) {
        return null;
      }
    }
    i++;
  }
  return temperatures2D;
}

color getColor(double power)
{
  colorMode(HSB, 1.0);
  H = (1-power) * 0.4; 
  S = 0.9; 
  B = 0.9; 

  return color((float)(H), (float)(S), (float)(B));
}

void findSerialPort() {

  serialString = Serial.list();  
  for (int i = serialString.length - 1; i > 0; i--) {  
    serialCheck = serialString[i];  
    serialIndex = serialCheck.indexOf(portName);  
    if (serialIndex > -1) portNumber = i;
  }
}    



public class SMA {
  private final Queue<Double> window = new LinkedList<Double>();
  private final int period;
  private double sum;

  public SMA(int period) {
    this.period = period;
  }

  public double compute(double num) {
    sum += num;
    window.add(num);
    if (window.size() > period) {
      sum -= window.remove();
    }
    if (window.isEmpty()) return 0; 
    return sum / window.size();
  }
}

public static double mean(double[] m) {
  double total = 0;
  for (double element : m) {
    total += element;
  }

  double average = total / m.length;
  return average;
}
