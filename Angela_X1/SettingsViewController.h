//
//  SettingsViewController.h
//  Angela_X1
//
//  Created by Angela on 10/7/17.
//  Copyright © 2017 Angela. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SettingsDelegate <NSObject>
- (void) sendDataToMainController:(char) dataSent;
- (void) sendDataToLed:(char) ledVal;
 @end


@interface SettingsViewController : UIViewController


@property (nonatomic, strong) NSString *systemIdValueStr;
@property (nonatomic, strong) NSString *modelNumberValueStr;
@property (nonatomic, strong) NSString *serialNumberValueStr;
@property (nonatomic, strong) NSString *firmwareVersionValueStr;
@property (nonatomic, strong) NSString *hardwareVersionValueStr;
@property (nonatomic, strong) NSString *softwareVersionValueStr;
@property (nonatomic, strong) NSString *mfgNameValueStr;
@property (nonatomic, strong) NSString *ledStateValueStr;
@property (nonatomic, strong) NSString *alarmStateValueStr;

@property int sliderSensitivityValue;

@property (weak, nonatomic) IBOutlet UILabel *labelDeviceID;
@property (weak, nonatomic) IBOutlet UILabel *labelModelNumber;
@property (weak, nonatomic) IBOutlet UILabel *labelSerialNumber;
@property (weak, nonatomic) IBOutlet UILabel *labelFirmwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *labelHardwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *labelSoftwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *labelManufacturer;
@property (weak, nonatomic) IBOutlet UILabel *labelLedState;
@property (weak, nonatomic) IBOutlet UILabel *labelAlarmState;

@property (weak, nonatomic) IBOutlet UISlider *sliderSensitivityProp;
- (IBAction)sliderSensitivity:(id)sender;


@property (weak, nonatomic) IBOutlet UIButton *buttonBackToMain;
- (IBAction)buttonBackToMain:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *buttonLedBlink;
- (IBAction)buttonLedBlink:(id)sender;

//@property (weak)id <SettingsViewControllerDelegate> delegateSettings;
@property (nonatomic, weak) id<SettingsDelegate> delegate;

@end
/*
@protocol sendDataBack <NSObject >

- (void) sendDataToPreviousController:(NSString *) testArray;

@end
 */
