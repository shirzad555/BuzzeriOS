//
//  SettingsViewController.h
//  Angela_X1
//
//  Created by Angela on 10/7/17.
//  Copyright © 2017 Angela. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController


@property (nonatomic, strong) NSString *systemIdValueStr;
@property (nonatomic, strong) NSString *modelNumberValueStr;
@property (nonatomic, strong) NSString *serialNumberValueStr;
@property (nonatomic, strong) NSString *firmwareVersionValueStr;
@property (nonatomic, strong) NSString *hardwareVersionValueStr;
@property (nonatomic, strong) NSString *softwareVersionValueStr;
@property (nonatomic, strong) NSString *mfgNameValueStr;


@property (weak, nonatomic) IBOutlet UILabel *labelDeviceID;
@property (weak, nonatomic) IBOutlet UILabel *labelModelNumber;
@property (weak, nonatomic) IBOutlet UILabel *labelSerialNumber;
@property (weak, nonatomic) IBOutlet UILabel *labelFirmwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *labelHardwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *labelSoftwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *labelManufacturer;

@end
