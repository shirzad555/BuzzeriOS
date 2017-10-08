//
//  ViewController.h
//  Angela_X1
//
//  Created by Angela on 9/30/17.
//  Copyright © 2017 Angela. All rights reserved.
//

#import <UIKit/UIKit.h>

enum BLE_Char{
    CHAR_LED_STATE      = 1,
    CHAR_ALARM_STATE    = 2,
    CHAR_ALARM_SEN      = 3
};

enum LED_State {
    LED_STATE_OFF       =   0x00,
    LED_STATE_ON        =   0x01,
    LED_STATE_FLASH_1   =   0x02,
    LED_STATE_FLASH_2   =   0x04,
    LED_STATE_FLASH_3   =   0x08,
    LED_STATE_ERROR     =   0xFF
};

enum ALARM_State {
    LARAM_STATE_OFF       =   0x00,
    ALARMSTATE_ON         =   0x01,
    ALARM_STATE_ERROR     =   0xFF
};

enum Alarm_Cmd {
    ALARM_ON_SEN_1      =   0x01,
    ALARM_ON_SEN_2      =   0x02,
    ALARM_ON_SEN_3      =   0x03,
    ALARM_ON_SEN_4      =   0x04,
    ALARM_ON_SEN_5      =   0x05,
    ALARM_SEN_ERROR     =   0xFF
};

@interface ViewController : UIViewController
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


@end

