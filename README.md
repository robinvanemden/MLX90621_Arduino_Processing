### MLX90621 Arduino and Processing example code

Arduino and Processing code for the Melexis [MLX90621](http://www.melexis.com/Infrared-Thermometer-Sensors/Infrared-Thermometer-Sensors/Low-noise-high-speed-16x4-Far-Infrared-array-823.aspx) 16x4 thermopile array.

Includes R script to parse data files (which can be exported by Processing visualizer).

The MLX90621 FIRray temperature sensing device from Melexis utilizes the company’s non-contact temperature measurement technology to create a highly cost-effective thermography solution. Covering a -20°C to 300°C temperature range, this 16 x 4 element far infrared (FIR) thermopile sensor array produces a map of heat values for the target area in real time, avoiding the need to scan the area with a single point sensor or use an expensive microbolometer device.

In use in VU and Tilburg University temperature [cry detection project](http://www.pavlov.io/2015/07/01/detecting-crying-eyes/).

Implements MaxBot's MLX90621 [Arduino library](http://forum.arduino.cc/index.php?topic=126244.0) patched with KMoto's [minor change](http://forum.arduino.cc/index.php?topic=126244.msg2307588#msg2307588) in defaultConfig_H.

Also makes use of [nox771's i2c_t3 enhanced Teensy 3 Wire library](https://github.com/nox771/i2c_t3). This library allows a [Teensy 3.1](https://www.pjrc.com/store/teensy31.html) Arduino compatible USB development board to communicate with the MLX90621 over I2C/TWI.

TODO 2015-10-25: Refactor and clean up Processing visualizer.

#####Screenshot

![Alt text](https://raw.githubusercontent.com/robinvanemden/MLX90621_Arduino_Processing/master/screenshot.gif?raw=true "screenshot")
