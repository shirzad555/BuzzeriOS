//
//  Constants.h
//  Angela_X1
//
//  Created by Angela on 9/30/17.
//  Copyright © 2017 Angela. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

//------------------------------------------------------------------------
// Information about Texas Instruments SensorTag UUIDs can be found at:
// http://processors.wiki.ti.com/index.php/SensorTag_User_Guide#Sensors
//------------------------------------------------------------------------
// Per the TI documentation:
//  The TI Base 128-bit UUID is: F0000000-0451-4000-B000-000000000000.
//
//  All sensor services use 128-bit UUIDs, but for practical reasons only
//  the 16-bit part is listed in this document.
//
//  It is embedded in the 128-bit UUID as shown by example below.
//
//          Base 128-bit UUID:  F0000000-0451-4000-B000-000000000000
//          "0xAA01" maps as:   F000AA01-0451-4000-B000-000000000000
//                                  ^--^
//------------------------------------------------------------------------

// Temp UUIDs
#define UUID_MOVEDETECTOR_SERVICE @"F000BB00-0451-4000-B000-000000000000"
#define UUID_LED_STATUS          @"F000BB01-0451-4000-B000-000000000000"
#define UUID_ALARM_VALUE        @"F000BB02-0451-4000-B000-000000000000"
#define UUID_ALRAM_SETTING       @"F000BB03-0451-4000-B000-000000000000"

// Humidity
//#define UUID_HUMIDITY_SERVICE @"F000AA20-0451-4000-B000-000000000000" // @"F000AA20-0451-4000-B000-000000000000"
//#define UUID_HUMIDITY_DATA    @"F000AA21-0451-4000-B000-000000000000"
//#define UUID_HUMIDITY_CONFIG  @"F000AA22-0451-4000-B000-000000000000"

#endif /* Constants_h */
