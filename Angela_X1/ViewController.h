//
//  ViewController.h
//  Angela_X1
//
//  Created by Angela on 9/30/17.
//  Copyright © 2017 Angela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"


enum UI_MAIN_STATE{
    SW_ALARM_STATE      = 1,
    SW_BUZZER_STATE     = 2,
    SW_LED_STATE        = 3,
    SW_MSG_STATE        = 4
};


enum BLE_Char{
    CHAR_LED_STATE      = 1,
    CHAR_ALARM_STATE    = 2,
    CHAR_ALARM_SEN      = 3,
    CHAR_MOVEMENT_MSG   = 4
};

enum LED_STATE {
    LED_STATE_OFF 	    = 0x00,
    LED_STATE_ON 		= 0x01,
    LED_STATE_FLASH_1   = 0x02,
    LED_STATE_FLASH_2   = 0x03,
    LED_STATE_FLASH_3   = 0x04,
    LED_STATE_ERROR     = 0xFF
};

enum ALARM_SENSITIVITY {
    ALARM_SENS_LOWEST       = 0x00,
    ALARM_SENS_LOW          = 0x01,
    ALARM_SENS_MID          = 0x02,
    ALARM_SENS_HIGH         = 0x03,
    ALARM_SENS_HIGHEST      = 0x04,
    ALARM_SENS_ERROR        = 0xFF
} ;

enum ALARM_STATE {
    ALARM_STATE_OFF         = 0x00,
    ALARM_STATE_BUZ         = 0x01,
    ALARM_STATE_LED         = 0x02,
    ALARM_STATE_MSG         = 0x03,
    ALARM_STATE_BUZ_LED     = 0x04,
    ALARM_STATE_BUZ_MSG     = 0x05,
    ALARM_STATE_LED_MSG     = 0x06,
    ALARM_STATE_BUZ_LED_MSG = 0x07,
    ALARM_STATE_ERROR       = 0xFF
} ;

enum MOVEMENT_MSG {
    MOVEMENT_MSG_NONE       = 0x00,
    MOVEMENT_MSG_LOW        = 0x01,
    MOVEMENT_MSG_HIGH       = 0x02,
    MOVEMENT_MSG_ERROR      = 0xFF
} ;





@interface ViewController : UIViewController <SettingsDelegate>
{
    __weak IBOutlet UIActivityIndicatorView *connectionIndicator;
}

@property (weak, nonatomic) IBOutlet UITextView *uiTextConnectUSB;
@property (weak, nonatomic) IBOutlet UILabel *labelAlarm;
- (IBAction)switchAlarm:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *switchAlarmOutlet;
@property (weak, nonatomic) IBOutlet UILabel *labelSearching;
@property (weak, nonatomic) IBOutlet UIButton *buttonSettingOutlet;
- (IBAction)buttonSettings:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *switchBuzzer;
@property (weak, nonatomic) IBOutlet UISwitch *switchLight;
@property (weak, nonatomic) IBOutlet UISwitch *switchMessage;


@end

