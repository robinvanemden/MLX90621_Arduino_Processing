/*
 *  VisualizeTemperatures.pde
 *
 *  A simple Processing Sketch which listens to a  
 *  Teensy 3.1+ Arduino board connected to a Melexis MLX90621
 *  and visualizes the temperature values measured by its 
 *  4x16 matrix as a color matrix 
 *
 *  Created on: 9.7.2015
 *      Author: Robin van Emden
 */

import processing.serial.*;

Serial serialConnection;
String sensorReading;
Double temperatureToString;
float[][] drawTemperatures2D;
float[][] temperatures2D;
float H, S, B;
boolean waitFirstNewline;

void setup() {
  size(700, 220);
  waitFirstNewline = false;
  sensorReading="";
  serialConnection = new Serial(this, "COM13", 19200);
  serialConnection.bufferUntil('\n');
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
    for (int i = 15; i >= 0; i--) {  
      pushMatrix();
      for (int j = 0; j < 4; j++) {
        fill(getColor(((drawTemperatures2D[j][i]-29)/7)));
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
}

float[][] parseInput(String input) {
  String[] temperatureRows;
  temperatureRows = input.split("~");
  if (temperatureRows.length<4) return null;
  temperatures2D = new float[temperatureRows.length][];
  int i= 0;
  String[] temperatureCols;
  for (String row : temperatureRows) {
    row = row.substring(1, row.length()-1);
    temperatureCols = row.split(",");
    if (temperatureCols.length<16) return null;
    int j = 0;
    temperatures2D[i] = new float[temperatureCols.length];
    for (String col : temperatureCols) {
      try {
        temperatures2D[i][j++] = Float.parseFloat(col);
      }
      catch(NumberFormatException ex) {
        return null;
      }
    }
    i++;
  }
  return temperatures2D;
}

color getColor(float power)
{
  colorMode(HSB, 1.0);
  H = (1-power) * 0.4; 
  S = 0.9; 
  B = 0.9; 
  
  return color(H, S, B);
}
