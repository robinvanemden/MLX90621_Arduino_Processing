/*
 * MLX90621.h
 *
 *  Created on: 08.07.2014
 *      Author: Max Ritter
 */

#ifndef MLX90621_H_
#define MLX90621_H_
//lalala
#ifdef __cplusplus

//Libraries to be included
#include <Arduino.h>
#include <i2c_t3.h>

//Begin registers
#define CAL_ACOMMON_L 0xD0
#define CAL_ACOMMON_H 0xD1
#define CAL_ACP_L 0xD3
#define CAL_ACP_H 0xD4
#define CAL_BCP 0xD5
#define CAL_alphaCP_L 0xD6
#define CAL_alphaCP_H 0xD7
#define CAL_TGC 0xD8
#define CAL_AI_SCALE 0xD9
#define CAL_BI_SCALE 0xD9

#define VTH_L 0xDA
#define VTH_H 0xDB
#define KT1_L 0xDC
#define KT1_H 0xDD
#define KT2_L 0xDE
#define KT2_H 0xDF
#define KT_SCALE 0xD2

//Common sensitivity coefficients
#define CAL_A0_L 0xE0
#define CAL_A0_H 0xE1
#define CAL_A0_SCALE 0xE2
#define CAL_DELTA_A_SCALE 0xE3
#define CAL_EMIS_L 0xE4
#define CAL_EMIS_H 0xE5

//Config register = 0xF5-F6
#define OSC_TRIM_VALUE 0xF7

//Bits within configuration register 0x92
#define POR_TEST 10

class MLX90621 {
private:
	/* Variables */
	byte refreshRate; //Set this value to your desired refresh frequency
	int16_t irData[64]; //Contains the raw IR data from the sensor
	float temperatures[64]; //Contains the calculated temperatures of each pixel in the array
	float Tambient; //Tracks the changing ambient temperature of the sensor
	byte eepromData[256]; //Contains the full EEPROM reading from the MLX90621
	int16_t a_common, a_i_scale, b_i_scale, k_t1_scale, k_t2_scale, resolution, cpix, ptat;
	float k_t1, k_t2, emissivity, tgc, alpha_cp, a_cp, b_cp, v_th;
	float a_ij[64], b_ij[64], alpha_ij[64];
	byte loopCount = 0; //Used in main loop

	/* Methods */
	void readEEPROM();
	void setConfiguration();
	void writeTrimmingValue();
	void calculateTA();
	void readPTAT();
	void calculateTO();
	void readIR();
	void readCPIX();
	uint16_t readConfig();
	boolean checkConfig();

public:
	void initialise(int);
	void measure();
	float getTemperature(int num);
	float getAmbient();
};

#endif
#endif

