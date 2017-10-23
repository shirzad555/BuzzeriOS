//
//  SettingsViewController.m
//  Angela_X1
//
//  Created by Angela on 10/7/17.
//  Copyright © 2017 Angela. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsViewController.h"
#import "ViewController.h"
//#import "ViewController.h"

/*
@interface SettingsViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;

@end
*/

@implementation SettingsViewController

@synthesize systemIdValueStr, modelNumberValueStr, serialNumberValueStr, firmwareVersionValueStr, hardwareVersionValueStr, softwareVersionValueStr, mfgNameValueStr, ledStateValueStr, alarmStateValueStr, sliderSensitivityValue;

- (void)viewDidLoad {
    
    _labelDeviceID.text = systemIdValueStr;
    _labelModelNumber.text = modelNumberValueStr;
    _labelSerialNumber.text = serialNumberValueStr;
    _labelFirmwareVersion.text = firmwareVersionValueStr;
    _labelHardwareVersion.text = hardwareVersionValueStr;
    _labelSoftwareVersion.text = softwareVersionValueStr;
    _labelManufacturer.text = mfgNameValueStr;
    _labelLedState.text = ledStateValueStr;
    _labelAlarmState.text = alarmStateValueStr;
    
    _sliderSensitivityProp.value = sliderSensitivityValue;
    
    //ViewController *viewController = [[ViewController alloc] init];
    //ViewController.
    
}


- (IBAction)sliderSensitivity:(id)sender {
    
    //int sliderValue;
    sliderSensitivityValue = (int)lroundf(_sliderSensitivityProp.value);
    [_sliderSensitivityProp setValue:sliderSensitivityValue animated:YES];
}
- (IBAction)buttonBackToMain:(id)sender {
    //[_delegateSettings recieveValueFromSettings:@"holaani"]; // you pass the value here
   // NSString * textField;
   // textField = @"foolish";
    [self.delegate sendDataToMainController:(char)lroundf(_sliderSensitivityProp.value)];
    
 //   [_delegate sendDataToPreviousController:textField];
}

- (IBAction)buttonLedBlink:(id)sender {
    [self.delegate sendDataToLed:LED_STATE_FLASH_1];
}




/*
#pragma mark – Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
– (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
