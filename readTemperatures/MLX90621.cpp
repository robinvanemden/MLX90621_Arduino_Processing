/*
 * MLX90621.cpp
 *
 *  Created on: 18.11.2013
 *      Author: Max
 */
#include "MLX90621.h"

void MLX90621::initialise(int refrate) {
	refreshRate = refrate;
	Wire.begin(I2C_MASTER, 0, I2C_PINS_18_19, I2C_PULLUP_INT, I2C_RATE_100);
	delay(5);
	readEEPROM();
	writeTrimmingValue();
	setConfiguration();
}

void MLX90621::measure() {
	if (checkConfig()) {
		readEEPROM();
		writeTrimmingValue();
		setConfiguration();
	}
	readPTAT();
	readIR();
	calculateTA();
	readCPIX();
	calculateTO();
}

float MLX90621::getTemperature(int num) {
	if ((num >= 0) && (num < 64)) {
		return temperatures[num];
	} else {
		return 0;
	}
}

float MLX90621::getAmbient() {
	return Tambient;
}

void MLX90621::setConfiguration() {
	byte Hz_LSB;
	switch (refreshRate) {
	case 0:
		Hz_LSB = 0b00111111;
		break;
	case 1:
		Hz_LSB = 0b00111110;
		break;
	case 2:
		Hz_LSB = 0b00111101;
		break;
	case 4:
		Hz_LSB = 0b00111100;
		break;
	case 8:
		Hz_LSB = 0b00111011;
		break;
	case 16:
		Hz_LSB = 0b00111010;
		break;
	case 32:
		Hz_LSB = 0b00111001;
		break;
	default:
		Hz_LSB = 0b00111110;
	}
	byte defaultConfig_H = 0b01000110;  //kmoto: See data sheet p.11 and 25
	Wire.beginTransmission(0x60);
	Wire.send(0x03);
	Wire.send((byte) Hz_LSB - 0x55);
	Wire.send(Hz_LSB);
	Wire.send(defaultConfig_H - 0x55);
	Wire.send(defaultConfig_H);
	Wire.endTransmission();

	//Read the resolution from the config register
	resolution = (readConfig() & 0x30) >> 4;
}

void MLX90621::readEEPROM() {
	Wire.beginTransmission(0x50);
	Wire.send(0x00);
	Wire.requestFrom(0x50, 256);
	for (int i = 0; i <= 255; i++) {
		eepromData[i] = Wire.read();
	}
	Wire.endTransmission();
}

void MLX90621::writeTrimmingValue() {
	Wire.beginTransmission(0x60);
	Wire.send(0x04);
	Wire.send((byte) eepromData[OSC_TRIM_VALUE] - 0xAA);
	Wire.send(eepromData[OSC_TRIM_VALUE]);
	Wire.send(0x56);
	Wire.send(0x00);
	Wire.endTransmission();
}

void MLX90621::calculateTA(void) {
	//Calculate variables from EEPROM
	k_t1_scale = (int16_t) (eepromData[KT_SCALE] & 0xF0) >> 4;
	k_t2_scale = (int16_t) (eepromData[KT_SCALE] & 0x0F) + 10;
	v_th = (float) 256 * eepromData[VTH_H] + eepromData[VTH_L];
	if (v_th >= 32768.0)
		v_th -= 65536.0;
	v_th = v_th / pow(2, (3 - resolution));
	k_t1 = (float) 256 * eepromData[KT1_H] + eepromData[KT1_L];
	if (k_t1 >= 32768.0)
		k_t1 -= 65536.0;
	k_t1 /= (pow(2, k_t1_scale) * pow(2, (3 - resolution)));
	k_t2 = (float) 256 * eepromData[KT2_H] + eepromData[KT2_L];
	if (k_t2 >= 32768.0)
		k_t2 -= 65536.0;
	k_t2 /= (pow(2, k_t2_scale) * pow(2, (3 - resolution)));
	Tambient = ((-k_t1 + sqrt(sq(k_t1) - (4 * k_t2 * (v_th - (float) ptat))))
			/ (2 * k_t2)) + 25.0;
}

void MLX90621::calculateTO() {
	//Calculate variables from EEPROM
	emissivity = (256 * eepromData[CAL_EMIS_H] + eepromData[CAL_EMIS_L])
			/ 32768.0;
      
	a_common = (int16_t) 256 * eepromData[CAL_ACOMMON_H]
			+ eepromData[CAL_ACOMMON_L];
	if (a_common >= 32768)
		a_common -= 65536;
	alpha_cp = (256 * eepromData[CAL_alphaCP_H] + eepromData[CAL_alphaCP_L])
			/ (pow(2, CAL_A0_SCALE) * pow(2, (3 - resolution)));
	a_i_scale = (int16_t) (eepromData[CAL_AI_SCALE] & 0xF0) >> 4;
	b_i_scale = (int16_t) eepromData[CAL_BI_SCALE] & 0x0F;
	a_cp = (float) 256 * eepromData[CAL_ACP_H] + eepromData[CAL_ACP_L];
	if (a_cp >= 32768.0)
		a_cp -= 65536.0;
	a_cp /= pow(2, (3 - resolution));
	b_cp = (float) eepromData[CAL_BCP];
	if (b_cp > 127.0)
		b_cp -= 256.0;
	b_cp /= (pow(2, b_i_scale) * pow(2, (3 - resolution)));
	tgc = (float) eepromData[CAL_TGC];
	if (tgc > 127.0)
		tgc -= 256.0;
	tgc /= 32.0;
	float v_cp_off_comp = (float) cpix - (a_cp + b_cp * (Tambient - 25.0));
	float v_ir_off_comp, v_ir_tgc_comp, v_ir_norm, v_ir_comp;
	for (int i = 0; i < 64; i++) {
		a_ij[i] = ((float) a_common + eepromData[i] * pow(2, a_i_scale))
				/ pow(2, (3 - resolution));
		b_ij[i] = eepromData[0x40 + i];
		if (b_ij[i] > 127)
			b_ij[i] -= 256;
		b_ij[i] = b_ij[i] / (pow(2, b_i_scale) * pow(2, (3 - resolution)));
		v_ir_off_comp = irData[i] - (a_ij[i] + b_ij[i] * (Tambient - 25.0));
		v_ir_tgc_comp = v_ir_off_comp - tgc * v_cp_off_comp;
		alpha_ij[i] = ((256 * eepromData[CAL_A0_H] + eepromData[CAL_A0_L])     
				/ pow(2, eepromData[CAL_A0_SCALE]));                              
		alpha_ij[i] += (eepromData[0x80 + i] / pow(2, eepromData[CAL_DELTA_A_SCALE]));                          
		alpha_ij[i] = alpha_ij[i] / pow(2, 3 - resolution);                                 
		v_ir_norm = v_ir_tgc_comp / (alpha_ij[i] - tgc * alpha_cp);
		v_ir_comp = v_ir_norm / emissivity;
		temperatures[i] = exp((log(   (v_ir_comp + pow((Tambient + 273.15), 4))   )/4.0))  
				- 273.15;
	}
}

void MLX90621::readIR() {
	Wire.beginTransmission(0x60);
	Wire.send(0x02);
	Wire.send(0x00);
	Wire.send(0x01);
	Wire.send(0x40);
	Wire.endTransmission(I2C_NOSTOP);
	Wire.requestFrom(0x60, 128);
	for (int i = 0; i < 64; i++) {
		byte pixelDataLow = Wire.read();
		byte pixelDataHigh = Wire.read();
		irData[i] = (int16_t) (pixelDataHigh << 8) | pixelDataLow;
	}
	Wire.endTransmission();
}

void MLX90621::readPTAT() {
	Wire.beginTransmission(0x60);
	Wire.send(0x02);
	Wire.send(0x40);
	Wire.send(0x00);
	Wire.send(0x01);
	Wire.endTransmission(I2C_NOSTOP);
	Wire.requestFrom(0x60, 2);
	byte ptatLow = Wire.read();
	byte ptatHigh = Wire.read();
	Wire.endTransmission();
	ptat = ((uint16_t) (ptatHigh << 8) | ptatLow);
}

void MLX90621::readCPIX() {
	Wire.beginTransmission(0x60);
	Wire.send(0x02);
	Wire.send(0x41);
	Wire.send(0x00);
	Wire.send(0x01);
	Wire.endTransmission(I2C_NOSTOP);
	Wire.requestFrom(0x60, 2);
	byte cpixLow = Wire.read();
	byte cpixHigh = Wire.read();
	Wire.endTransmission();
	cpix = ((int16_t) (cpixHigh << 8) | cpixLow);
	if (cpix >= 32768)
		cpix -= 65536;
}

uint16_t MLX90621::readConfig() {
	Wire.beginTransmission(0x60);
	Wire.send(0x02);
	Wire.send(0x92);
	Wire.send(0x00);
	Wire.send(0x01);
	Wire.endTransmission(I2C_NOSTOP);
	Wire.requestFrom(0x60, 2);
	byte configLow = Wire.read();
	byte configHigh = Wire.read();
	Wire.endTransmission();
	uint16_t config = ((uint16_t) (configHigh << 8) | configLow);
	return config;
}

//Poll the MLX90621 for its current status
//Returns true if the POR/Brown out bit is set
boolean MLX90621::checkConfig() {
	bool check = !((readConfig() & 0x0400) >> 10);
	return check;
}
