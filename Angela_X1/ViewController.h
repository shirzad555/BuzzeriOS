//
//  ViewController.h
//  Angela_X1
//
//  Created by Angela on 9/30/17.
//  Copyright © 2017 Angela. All rights reserved.
//

#import <UIKit/UIKit.h>

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

@end

