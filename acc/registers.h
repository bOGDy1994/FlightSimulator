#ifndef REGISTERS_H
#define REGISTERS_H

#define OUT_X_MSB 0x01 //8MSB of 12-bit sample
#define INT_SOURCE 0x0C // Interrupt Status
#define WHO_AM_I 0x0D // Device ID
#define XYZ_DATA_CFG 0x0E //HPF Data Out and Dynamic Range Settings
#define PL_STATUS 0x10 // Landscape/Portrait orientation status
#define PL_CFG 0x11 // Landscape/Portrait configuration
#define PL_COUNT 0x12 // Landscape/Portrait debounce counter
#define PL_BF_ZCOMP 0x13 // Back-Front, Z-Lock Trip threshold
#define P_L_THS_REG 0x14 // Portrait to Landscape Trip Angle is 29°
#define PULSE_CFG 0x21 //  ELE, Double_XYZ or Single_XYZ
#define PULSE_SRC 0x22 // EA, Double_XYZ or Single_XYZ
#define PULSE_THSX 0x23 // X pulse threshold
#define PULSE_THSY 0x24 // Y pulse threshold
#define PULSE_THSZ 0x25 // Z pulse threshold
#define PULSE_TMLT 0x26 // Time limit for pulse
#define PULSE_LTCY 0x27 // Latency time for 2nd pulse
#define PULSE_WIND 0x28 // Window time for 2nd pulse
#define CTRL_REG1 0x2A //  ODR = 800 Hz, STANDBY Mode
#define CTRL_REG3 0x2C // Wake from Sleep, IPOL, PP_OD
#define CTRL_REG4 0x2D // Interrupt enable registe
#define CTRL_REG5 0x2E //  Interrupt pin (INT1/INT2) map 

#endif