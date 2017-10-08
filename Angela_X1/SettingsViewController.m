//
//  SettingsViewController.m
//  Angela_X1
//
//  Created by Angela on 10/7/17.
//  Copyright © 2017 Angela. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsViewController.h"

@implementation SettingsViewController

@synthesize systemIdValueStr, modelNumberValueStr, serialNumberValueStr, firmwareVersionValueStr, hardwareVersionValueStr, softwareVersionValueStr, mfgNameValueStr;

- (void)viewDidLoad {
    
    _labelDeviceID.text = systemIdValueStr;
    _labelModelNumber.text = modelNumberValueStr;
    _labelSerialNumber.text = serialNumberValueStr;
    _labelFirmwareVersion.text = firmwareVersionValueStr;
    _labelHardwareVersion.text = hardwareVersionValueStr;
    _labelSoftwareVersion.text = softwareVersionValueStr;
    _labelManufacturer.text = mfgNameValueStr;
    
}


@end
