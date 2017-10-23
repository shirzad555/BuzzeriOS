//
//  ViewController.m
//  Angela_X1
//
//  Created by Angela on 9/30/17.
//  Copyright © 2017 Angela. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "Constants.h"
//#import "SettingsViewController.h"
//#import "UIViewController+Settings.h"

@import UserNotifications;

#define TIMER_PAUSE_INTERVAL 10.0
#define TIMER_SCAN_INTERVAL  2.0

#define SENSOR_DATA_INDEX_TEMP_INFRARED 0
#define SENSOR_DATA_INDEX_TEMP_AMBIENT  1
#define SENSOR_DATA_INDEX_HUMIDITY_TEMP 0
#define SENSOR_DATA_INDEX_HUMIDITY      1

// This could be simplified to "SensorTag" and check if it's a substring...
#define SENSOR_TAG_NAME @"CC2650 SensorTag"

NSString * systemIdStr;
NSString * modelNumberStr;
NSString * serialNumberStr;
NSString * firmwareVersionStr;
NSString * hardwareVersionStr;
NSString * softwareVersionStr;
NSString * mfgNameStr;

CBCentralManager *centralManager;

CBPeripheral *sensorTag;
BOOL keepScanning;
static enum LED_STATE current_led_state; //= LED_STATE_OFF;
static enum ALARM_STATE current_alarm_state; //= LED_STATE_OFF;
static enum ALARM_SENSITIVITY current_alarm_sensitivity; //= ALARM_OFF;
static enum MOVEMENT_MSG current_movement_msg; //= LED_STATE_OFF;

CBCharacteristic *ledCharacteristic;
CBCharacteristic *alarmStateCharacteristic;
CBCharacteristic *alarmSenCharacteristic;
CBCharacteristic *alarmMsgCharacteristic;


static bool current_swAlarm_state = false;
static bool current_swBuzzer_state = false;
static bool current_swLed_state = false;
static bool current_swMsg_state = false;



BOOL firstTimeLoading = true;
//static int sensitivityValue;

//NSString   *modelNumber;
NSArray *ledStateArray ;
NSArray *alarmStateArray ;


@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

    // Properties for Background Swapping

//@property (nonatomic, strong) CBCentralManager *centralManager;
//@property (nonatomic, strong) CBPeripheral *sensorTag;
//@property (nonatomic, assign) BOOL keepScanning;

//@property (nonatomic, assign) char current_led_state; //= LED_STATE_OFF;
//@property (nonatomic, assign) char current_alarm_sensitivity; //= ALARM_OFF;

//@property (nonatomic, strong) NSString * modelNumberStr;

// Instance methods to grab device Manufacturer Name, Body Location
- (void) setSystemID:(CBCharacteristic *)characteristic;
- (void) setModelNumber:(CBCharacteristic *)characteristic;
- (void) setSerialNumber:(CBCharacteristic *)characteristic;
- (void) setFirmwareVersion:(CBCharacteristic *)characteristic;
- (void) setHardwareVersion:(CBCharacteristic *)characteristic;
- (void) setSoftwareVersion:(CBCharacteristic *)characteristic;
- (void) setMfgName:(CBCharacteristic *)characteristic;

- (void) UpdateAlarmState;

@end



@implementation ViewController
{
 
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    ledStateArray = [NSArray arrayWithObjects:   @"OFF",   @"ON",   @"FLASH_1",  @"FLASH_2", @"FLASH_3", @"ERROR", nil];
    alarmStateArray = [NSArray arrayWithObjects:   @"OFF",   @"BUZZER",   @"LED",  @"MSG", @"BUZ/LED", @"BUZ/MSG", @"LED/MSG", @"BUZ/LED/MSG", @"ERROR", nil];
    if(firstTimeLoading)
    {
        //[connectionIndicator startAnimating];
//        connectionIndicator.hidesWhenStopped = true;
        [self ConnectionState:false];
    
        // Create the CBCentralManager.
        // NOTE: Creating the CBCentralManager with initWithDelegate will immediately call centralManagerDidUpdateState.
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
        //    self.modelNumberStr = @"viewLoad";
        
        firstTimeLoading = false;
    
    }
    else{
        [self ConnectionState:true];
    }
    connectionIndicator.hidesWhenStopped = true;
    
    
    bool tempBool;
    
    [self GetUiState:SW_ALARM_STATE char_value:&tempBool];
    [self.switchAlarmOutlet setOn:tempBool];
    
    [self GetUiState:SW_BUZZER_STATE char_value:&tempBool];
    [self.switchBuzzer setOn:tempBool];
    [self GetUiState:SW_LED_STATE char_value:&tempBool];
    [self.switchLight setOn:tempBool];
    [self GetUiState:SW_MSG_STATE char_value:&tempBool];
    [self.switchMessage setOn:tempBool];

    self.switchBuzzer.enabled = !self.switchAlarmOutlet.isOn;
    self.switchLight.enabled = !self.switchAlarmOutlet.isOn;
    self.switchMessage.enabled = !self.switchAlarmOutlet.isOn;
    
}

- (void)pauseScan {
    // Scanning uses up battery on phone, so pause the scan process for the designated interval.
    NSLog(@"*** PAUSING SCAN...");
    [NSTimer scheduledTimerWithTimeInterval:TIMER_PAUSE_INTERVAL target:self selector:@selector(resumeScan) userInfo:nil repeats:NO];
    [centralManager stopScan];
}

- (void)resumeScan {
    if (keepScanning) {
        // Start scanning again...
        NSLog(@"*** RESUMING SCAN!");
        [NSTimer scheduledTimerWithTimeInterval:TIMER_SCAN_INTERVAL target:self selector:@selector(pauseScan) userInfo:nil repeats:NO];
        [centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

- (IBAction)switchAlarm:(UISwitch *)sender {

    char  alarmState;
    
    self.switchBuzzer.enabled = !self.switchAlarmOutlet.isOn;
    self.switchLight.enabled = !self.switchAlarmOutlet.isOn;
    self.switchMessage.enabled = !self.switchAlarmOutlet.isOn;
    
    [self UpdateAlarmState]; // Read alarm setting switches and update alarm state
    
    // Read the latest status for LED to be up to date //
//    [sensorTag readValueForCharacteristic:alarmStateCharacteristic]; // readValue(for characteristic: CBCharacteristic)
    
    //[self SetParameter:CHAR_ALARM_STATE length:1 char_value:&alarmState];
    [self GetParameter:CHAR_ALARM_STATE char_value:&alarmState];
    NSData *enableBytes = [NSData dataWithBytes:&alarmState length:sizeof(char)];
    [sensorTag writeValue:enableBytes forCharacteristic:alarmStateCharacteristic type:CBCharacteristicWriteWithResponse]; //  // 
    
 
    
    /******************* Notifications **********************************/
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
    
    [center requestAuthorizationWithOptions:options
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              if (!granted) {
                                  NSLog(@"Something went wrong");
                              }
                          }];
    
    //Creating A Notification Request
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = @"Don't forget";
    content.body = @"Buy some milk";
    content.sound = [UNNotificationSound defaultSound];
    
    //Schedule a notification for a number of seconds later
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5 repeats:NO];
    
    // With both the content and trigger ready we create a new notification request and add it to the notification center.
    NSString *identifier = @"UYLLocalNotification";
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier  content:content trigger:trigger];
    
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Something went wrong: %@",error);
        }
    }];
    /**********************************************************************/
}

- (void)cleanup {
    [centralManager cancelPeripheralConnection:sensorTag];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (char)SetParameter:(char)param length:(char) len char_value: (char*) value  {
    char errorLog = 0;
    switch(param)
    {
        case CHAR_LED_STATE:
            if(len == 1)
            {
                current_led_state = *(char*)value;
            }
            break;
        case CHAR_ALARM_SEN:
            if(len == 1)
            {
                current_alarm_sensitivity = *(char*)value;
            }
            break;
        case CHAR_ALARM_STATE:
            if(len == 1)
            {
                current_alarm_state = *(char*)value;
            }
            break;
        case CHAR_MOVEMENT_MSG:
            if(len == 1)
            {
                current_movement_msg = *(char*)value;
            }
            break;
        default:
            break;
    }
    return errorLog;
}

- (char)GetParameter:(char)param  char_value: (char*) value  {
    char errorLog = 0;
    switch(param)
    {
        case CHAR_LED_STATE:
            *(char*)value = current_led_state;
            break;
        case CHAR_ALARM_SEN:
            *(char*)value = current_alarm_sensitivity;
            break;
        case CHAR_ALARM_STATE:
            *(char*)value = current_alarm_state;
            break;
        case CHAR_MOVEMENT_MSG:
            *(char*)value = current_movement_msg;
            break;
        default:
            break;
    }
    return errorLog;
}

- (char)SetUiState:(enum UI_MAIN_STATE)param length:(char) len char_value: (bool*) state  {
    char errorLog = 0;
    switch(param)
    {
        case SW_ALARM_STATE:
            if(len == 1)
            {
                current_swAlarm_state = *(bool*)state;
            }
            break;
        case SW_BUZZER_STATE:
            if(len == 1)
            {
                current_swBuzzer_state = *(bool*)state;
            }
            break;
        case SW_LED_STATE:
            if(len == 1)
            {
                current_swLed_state = *(bool*)state;
            }
            break;
        case SW_MSG_STATE:
            if(len == 1)
            {
                current_swMsg_state = *(bool*)state;
            }
            break;
        default:
            break;
    }
    return errorLog;
}


- (char)GetUiState:(enum UI_MAIN_STATE)param  char_value: (bool*) state  {
    char errorLog = 0;
    switch(param)
    {
        case SW_ALARM_STATE:
            *(bool*)state = current_swAlarm_state;
            break;
        case SW_BUZZER_STATE:
            *(bool*)state = current_swBuzzer_state;
            break;
        case SW_LED_STATE:
            *(bool*)state = current_swLed_state;
            break;
        case SW_MSG_STATE:
            *(bool*)state = current_swMsg_state;
            break;
        default:
            break;
    }
    return errorLog;
}

- (void)ConnectionState:(BOOL)state  {
    if (state == true) // when connection is good
    {
        [connectionIndicator stopAnimating];
        self.labelSearching.text = @"Connected";
        self.switchBuzzer.enabled = !self.switchAlarmOutlet.isOn;
        self.switchLight.enabled = !self.switchAlarmOutlet.isOn;
        self.switchMessage.enabled = !self.switchAlarmOutlet.isOn;
    }
    else // when connection is lost
    {
        [connectionIndicator startAnimating];
        self.labelSearching.text = @"Searching";
    }
    //self.labelSearching.hidden = state;
    self.uiTextConnectUSB.hidden = state;
    self.labelAlarm.hidden = !state;
    self.switchAlarmOutlet.hidden = !state;
    self.buttonSettingOutlet.hidden = !state;
    
    self.switchBuzzer.hidden = !state;
    self.switchLight.hidden = !state;
    self.switchMessage.hidden = !state;
    
}

#pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBManager *)central { //CBCentralManager
    BOOL showAlert = YES;
    NSString *state = @"";
    switch ([central state])
    {
        case CBManagerStateUnsupported: // CBCentralManagerStateUnsupported:
            state = @"This device does not support Bluetooth Low Energy.";
            break;
        case CBManagerStateUnauthorized: //CBCentralManagerStateUnauthorized
            state = @"This app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBManagerStatePoweredOff: // CBCentralManagerStatePoweredOff
            state = @"Bluetooth on this device is currently powered off.";
            break;
        case CBManagerStateResetting: //CBCentralManagerStateResetting
            state = @"The BLE Manager is resetting; a state update is pending.";
            break;
        case CBManagerStatePoweredOn: // CBCentralManagerStatePoweredOn
            showAlert = NO;
            state = @"Bluetooth LE is turned on and ready for communication.";
            NSLog(@"%@", state);
            keepScanning = YES;
            [NSTimer scheduledTimerWithTimeInterval:TIMER_SCAN_INTERVAL target:self selector:@selector(pauseScan) userInfo:nil repeats:NO];
            [centralManager scanForPeripheralsWithServices:nil options:nil];
            break;
        case CBManagerStateUnknown: // CBCentralManagerStateUnknown
            state = @"The state of the BLE Manager is unknown.";
            break;
        default:
            state = @"The state of the BLE Manager is unknown.";
    }
    
    if (showAlert) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Central Manager State" message:state preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [ac addAction:okAction];
        [self presentViewController:ac animated:YES completion:nil];
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
    NSString *peripheralName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    NSLog(@"NEXT PERIPHERAL: %@ (%@)", peripheralName, peripheral.identifier.UUIDString);
    if (peripheralName) {
        if ([peripheralName isEqualToString:SENSOR_TAG_NAME]) {
            keepScanning = NO;
            
            // save a reference to the sensor tag
            sensorTag = peripheral;
            sensorTag.delegate = self;
            
            // Request a connection to the peripheral
            [centralManager connectPeripheral:sensorTag options:nil];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!");
//    self.temperatureLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:56];
//    self.temperatureLabel.text = @"Connected";

    [self ConnectionState:true];
    
    // Now that we've successfully connected to the SensorTag, let's discover the services.
    // - NOTE:  we pass nil here to request ALL services be discovered.
    //          If there was a subset of services we were interested in, we could pass the UUIDs here.
    //          Doing so saves battery life and saves time.
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"**** CONNECTION FAILED!!!");
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"**** DISCONNECTED FROM SENSOR TAG!!!");
    [self ConnectionState:false];
    [self centralManagerDidUpdateState: centralManager];
}

#pragma mark - CBPeripheralDelegate methods

// When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
    for (CBService *service in peripheral.services) {
        //NSLog(@"Discovered service: %@", service);
        //NSLog(@"Service UUID: %@ \n\r", service.UUID);
        //NSLog(@"Expected UUID: %@ \n\r", [CBUUID UUIDWithString:UUID_MOVEDETECTOR_SERVICE]);
        //self.temperatureLabel.text = [NSString stringWithFormat:@"UUID %@", service.UUID];
        if (([service.UUID isEqual:[CBUUID UUIDWithString:UUID_MOVEDETECTOR_SERVICE]]) /*||
                                                                                        ([service.UUID isEqual:[CBUUID UUIDWithString:UUID_HUMIDITY_SERVICE]])*/)
        {
            [peripheral discoverCharacteristics:nil forService:service];
            //NSLog(@"UUID_MOVEDETECTOR_SERVICE!!!! \n\r");
        }
        if (([service.UUID isEqual:[CBUUID UUIDWithString:UUID_DEVICE_INFO_SERVICE]]) /*||
                                                                                        ([service.UUID isEqual:[CBUUID UUIDWithString:UUID_HUMIDITY_SERVICE]])*/)
        {
            [peripheral discoverCharacteristics:nil forService:service];
            //NSLog(@"Deivce Information detected!!!! \n\r");
        }
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *characteristic in service.characteristics) {
        //uint8_t enableValue = 2; //1;
        //NSData *lvalue = [NSData 1];
        //NSData *enableBytes = [NSData dataWithBytes:&enableValue length:sizeof(uint8_t)];
        //connectingPeripheral = peripheral;
        
        NSLog(@"characteristic UUID: %@ \n\r", characteristic.UUID); // Shirzad
        //self.temperatureLabel.text = [NSString stringWithFormat:@"UUID %@", characteristic.UUID]; // Shirzad
        
        // Model Number
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_MODEL_NUM]]) {
            //NSLog(@"UUID_MODEL_NUM: %@ \n\r", characteristic.UUID); // Shirzad
            //modelNumberStr = characteristic.description;
            //modelNumberStr = [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding]; //characteristic.value;
            //NSLog(@"+++++++=======+++++++: %@ \n\r", [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding]);
            //NSLog(@"*********************: %@ \n\r", characteristic.value);
            [sensorTag readValueForCharacteristic:characteristic];
            //NSLog(@"Found a device manufacturer name characteristic");
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_SYSTEM_ID]]) {
            [sensorTag readValueForCharacteristic:characteristic];
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_SERIAL_NUM]]) {
            [sensorTag readValueForCharacteristic:characteristic];
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_FIRMWARE_REV]]) {
            [sensorTag readValueForCharacteristic:characteristic];
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_HARDWARE_REV]]) {
            [sensorTag readValueForCharacteristic:characteristic];
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_SOFTWARE_REV]]) {
            [sensorTag readValueForCharacteristic:characteristic];
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_MFG_NAME]]) {
            [sensorTag readValueForCharacteristic:characteristic];
        }

        // Alarm State
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ALARM_STATE]]) {
            // Enable Temperature Sensor notification
            //[self.sensorTag setNotifyValue:YES forCharacteristic:characteristic];
            //NSLog(@"UUID_ALARM_STATE: %@ \n\r", characteristic.UUID); // Shirzad
            alarmStateCharacteristic = characteristic;
            [sensorTag readValueForCharacteristic:characteristic];
        }
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_LED_STATUS]]) {
            // Enable Temperature Sensor
            //NSLog(@"UUID_LED_STATUS: %@ \n\r", characteristic.UUID); // Shirzad
            ledCharacteristic = characteristic;
            [sensorTag readValueForCharacteristic:characteristic];
            //[self.sensorTag writeValue:enableBytes forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ALARM_SEN]]) {
            // Enable Temperature Sensor notification
            //NSLog(@"UUID_ALRAM_SEN: %@ \n\r", characteristic.UUID); // Shirzad
            alarmSenCharacteristic = characteristic;
            [sensorTag readValueForCharacteristic:characteristic];
            //self.temperatureLabel.text = [NSString stringWithFormat:@"HOLA!!"]; // Shirzad
            //let value: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]
            //let data = NSData(bytes: value, length: 7)
            //uint8_t data = 0x05;
            //[self.sensorTag writeValue:enableBytes forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_MVMNT_MSG]]) {
            //NSLog(@"UUID_MVMNT_MSG: %@ \n\r", characteristic.UUID); // Shirzad
            alarmMsgCharacteristic = characteristic;
            [sensorTag readValueForCharacteristic:characteristic];
        }
        
        /*        // Humidity
         if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_HUMIDITY_DATA]]) {
         // Enable Humidity Sensor notification
         [self.sensorTag setNotifyValue:YES forCharacteristic:characteristic];
         }
         
         if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_HUMIDITY_CONFIG]]) {
         // Enable Humidity Sensor
         //[self.sensorTag writeValue:enableBytes forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
         }*/
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
    } else {
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        NSData *dataBytes = characteristic.value;
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_LED_STATUS]]) {
            //[self displayTemperature:dataBytes];
            
            char dataArray[dataBytes.length]; // uint16_t dataArray[dataLength];
            /*            for (int i = 0; i < dataBytes.length; i++) {
             dataArray[i] = 0;
             }
             */
            // extract the data from the dataBytes object
            [dataBytes getBytes:&dataArray length:dataBytes.length * sizeof(uint8_t)]; // [dataBytes getBytes:&dataArray length:dataLength * sizeof(uint16_t)];
            // char rawAmbientTemp = dataArray[0];
            // NSLog(@"characteristic VALUE ======  %@ \n\r", characteristic.value); // Shirzad
            //NSLog(@"LED State Length ======  %lu \n\r", (unsigned long)dataBytes.length); // Shirzad
            NSLog(@"LED State VALUE = %u \n\r", (unsigned int)dataArray[0]); // Shirzad
            [self SetParameter:CHAR_LED_STATE length:dataBytes.length char_value:dataArray];
            //self.temperatureLabel.text = [NSString stringWithFormat:@"LED = %u", (unsigned int)dataArray[0]];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ALARM_SEN]]) {
            char dataArray[dataBytes.length];
            [dataBytes getBytes:&dataArray length:dataBytes.length * sizeof(uint8_t)];
            NSLog(@"Alarm Setting VALUE = %u \n\r", (unsigned int)dataArray[0]);
            [self SetParameter:CHAR_ALARM_SEN length:dataBytes.length char_value:dataArray];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ALARM_STATE]]) {
            char dataArray[dataBytes.length];
            [dataBytes getBytes:&dataArray length:dataBytes.length * sizeof(uint8_t)];
            NSLog(@"Alarm VALUE = %u \n\r", (unsigned int)dataArray[0]);
            [self SetParameter:CHAR_ALARM_SEN length:dataBytes.length char_value:dataArray];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_MVMNT_MSG]]) {
            char dataArray[dataBytes.length];
            [dataBytes getBytes:&dataArray length:dataBytes.length * sizeof(uint8_t)];
            NSLog(@"Movement VALUE = %u \n\r", (unsigned int)dataArray[0]);
            [self SetParameter:CHAR_MOVEMENT_MSG length:dataBytes.length char_value:dataArray];
        }        
        //////////// Retrieve the characteristic value for Device Info received /////////////////////////
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_SYSTEM_ID]]) {  // 2
            [self setSystemID:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_MODEL_NUM]]) {  // 2
            [self setModelNumber:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_SERIAL_NUM]]) {  // 2
            [self setSerialNumber:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_FIRMWARE_REV]]) {  // 2
            [self setFirmwareVersion:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_HARDWARE_REV]]) {  // 2
            [self setHardwareVersion:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_SOFTWARE_REV]]) {  // 2
            [self setSoftwareVersion:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_MFG_NAME]]) {  // 2
            [self setMfgName:characteristic];
        }
    }
}

/*
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"GoToSettingsSegue"]){
        SettingsViewController *settingView = (SettingsViewController *)segue.destinationViewController;
        
        settingView.systemIdValueStr = systemIdStr;
        settingView.modelNumberValueStr = modelNumberStr;
        settingView.serialNumberValueStr = serialNumberStr;
        settingView.firmwareVersionValueStr = firmwareVersionStr;
        settingView.hardwareVersionValueStr = hardwareVersionStr;
        settingView.softwareVersionValueStr = softwareVersionStr;
        settingView.mfgNameValueStr = mfgNameStr;
        if ( current_led_state >= sizeof(ledStateArray))
        {
            settingView.ledStateValueStr = @"ERROR";////[NSString stringWithFormat:@"%d",current_led_state]; // [names objectAtIndex:0];
        }
        else{
            settingView.ledStateValueStr = [ledStateArray  objectAtIndex:current_led_state];
        }
        if ( current_alarm_state >= sizeof(ledStateArray))
        {
            settingView.alarmStateValueStr = @"ERROR";
        }
        else{
            settingView.alarmStateValueStr = [alarmStateArray  objectAtIndex:current_alarm_state];
        }
        settingView.sliderSensitivityValue = current_alarm_sensitivity;
    }
}
*/
 
 
- (IBAction)buttonSettings:(id)sender {
//    NSLog(@"button  -- frame:");
//    SettingsViewController *secondController = [[SettingsViewController alloc] init];
//    secondController.dataPass = @"hola hola";
    
    //[self performSegueWithIdentifier:@"WeekView" sender:self];
    
    
    // SettingsViewController *settingView = [[SettingsViewController alloc] initWithNibName:@"SettingViewController" bundle:nil];
 //   SettingsViewController *secondController = [[SettingsViewController alloc] initWithiNibName:@"GoBackSegue"];

  //  SettingsViewController *secondController=[[SettingsViewController alloc] initWithNibName:@"GoBackSegue" bundle:nil];
  //  SettingsViewController *secondController = [[SettingsViewController alloc] init];

    bool tempBool;
    
    tempBool = self.switchAlarmOutlet.isOn;
    [self SetUiState:SW_ALARM_STATE length:1 char_value:&tempBool];
    tempBool = self.switchBuzzer.isOn;
    [self SetUiState:SW_BUZZER_STATE length:1 char_value:&tempBool];
    tempBool = self.switchLight.isOn;
    [self SetUiState:SW_LED_STATE length:1 char_value:&tempBool];
    tempBool = self.switchMessage.isOn;
    [self SetUiState:SW_MSG_STATE length:1 char_value:&tempBool];
    
    
    char temp;
    
    SettingsViewController *secondController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];

    secondController.systemIdValueStr = systemIdStr;
    secondController.modelNumberValueStr = modelNumberStr;
    secondController.serialNumberValueStr = serialNumberStr;
    secondController.firmwareVersionValueStr = firmwareVersionStr;
    secondController.hardwareVersionValueStr = hardwareVersionStr;
    secondController.softwareVersionValueStr = softwareVersionStr;
    secondController.mfgNameValueStr = mfgNameStr;
    
    [self GetParameter:CHAR_LED_STATE char_value:&temp];
    if ( temp >= sizeof(ledStateArray))
    {
        secondController.ledStateValueStr = @"ERROR";////[NSString stringWithFormat:@"%d",current_led_state]; // [names objectAtIndex:0];
    }
    else{
        secondController.ledStateValueStr = [ledStateArray  objectAtIndex:temp];
    }
    
    [self GetParameter:CHAR_ALARM_STATE char_value:&temp];
    if ( temp >= sizeof(ledStateArray))
    {
        secondController.alarmStateValueStr = @"ERROR";
    }
    else{
        
        secondController.alarmStateValueStr = [alarmStateArray  objectAtIndex:temp];
    }
    
    [self GetParameter:CHAR_ALARM_SEN char_value:&temp];
    secondController.sliderSensitivityValue = temp;
    
    [secondController setDelegate:self];
    [self presentViewController:secondController animated:YES completion:nil];
    //secondController.delegate = self; // protocol listener
    //[self.navigationController pushViewController:secondController animated:YES];

    // [self performSegueWithIdentifier:@"GoToSettingsSegue" sender:self];

}

//////////////////// GET Device Info //////////////////////////////////////////////////////////////////////////////
- (void) setSystemID:(CBCharacteristic *)characteristic
{
    NSString *temp = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];  // 1
    systemIdStr = [NSString stringWithFormat:@"%@", temp];    // 2
    return;
}
- (void) setModelNumber:(CBCharacteristic *)characteristic
{
    NSString *temp = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];  // 1
    modelNumberStr = [NSString stringWithFormat:@"%@", temp];    // 2
    //NSLog(@"Model Number = %@:", modelNumberStr);
    return;
}
- (void) setSerialNumber:(CBCharacteristic *)characteristic
{
    NSString *temp = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];  // 1
    serialNumberStr = [NSString stringWithFormat:@"%@", temp];    // 2
    return;
}
- (void) setFirmwareVersion:(CBCharacteristic *)characteristic
{
    NSString *temp = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];  // 1
    firmwareVersionStr = [NSString stringWithFormat:@"%@", temp];    // 2
    return;
}
- (void) setHardwareVersion:(CBCharacteristic *)characteristic
{
    NSString *temp = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];  // 1
    hardwareVersionStr = [NSString stringWithFormat:@"%@", temp];    // 2
    return;
}
- (void) setSoftwareVersion:(CBCharacteristic *)characteristic
{
    NSString *temp = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];  // 1
    softwareVersionStr = [NSString stringWithFormat:@"%@", temp];    // 2
    return;
}
- (void) setMfgName:(CBCharacteristic *)characteristic
{
    NSString *temp = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];  // 1
    mfgNameStr = [NSString stringWithFormat:@"%@", temp];    // 2
    return;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
 Name:          UpdateAlarmState
 Description:   Updates "current_alarm_state" based on latest state of alarm setting switches
 */
- (void)UpdateAlarmState {

    char alarm_state;
    
    if ([self.switchAlarmOutlet isOn] == true)
    {
        if ([self.switchBuzzer isOn] == false && [self.switchLight isOn] == false && [self.switchMessage isOn] == false){
            alarm_state = ALARM_STATE_OFF;    }
        else if ([self.switchBuzzer isOn] == true && [self.switchLight isOn] == false && [self.switchMessage isOn] == false){
            alarm_state = ALARM_STATE_BUZ;    }
        else if ([self.switchBuzzer isOn] == false && [self.switchLight isOn] == true && [self.switchMessage isOn] == false){
            alarm_state = ALARM_STATE_LED;    }
        else if ([self.switchBuzzer isOn] == false && [self.switchLight isOn] == false && [self.switchMessage isOn] == true){
            alarm_state = ALARM_STATE_MSG;    }
        else if ([self.switchBuzzer isOn] == true && [self.switchLight isOn] == true && [self.switchMessage isOn] == false){
            alarm_state = ALARM_STATE_BUZ_LED;    }
        else if ([self.switchBuzzer isOn] == true && [self.switchLight isOn] == false && [self.switchMessage isOn] == true){
            alarm_state = ALARM_STATE_BUZ_MSG;    }
        else if ([self.switchBuzzer isOn] == false && [self.switchLight isOn] == true && [self.switchMessage isOn] == true){
            alarm_state = ALARM_STATE_LED_MSG;    }
        else if ([self.switchBuzzer isOn] == true && [self.switchLight isOn] == true && [self.switchMessage isOn] == true)    {
            alarm_state = ALARM_STATE_BUZ_LED_MSG;}
    }
    else
    {
        alarm_state = ALARM_STATE_OFF;
    }
    [self SetParameter:CHAR_ALARM_STATE length:1 char_value:&alarm_state];
    
}



-(void) sendDataToMainController:(char)dataIn
{
    char alarmSen = dataIn;
    
    [self SetParameter:CHAR_ALARM_SEN length:sizeof(char) char_value:&alarmSen];
    [self GetParameter:CHAR_ALARM_SEN char_value:&alarmSen];
    NSData *enableBytes = [NSData dataWithBytes:&alarmSen length:sizeof(char)];
    
    [sensorTag writeValue:enableBytes forCharacteristic:alarmSenCharacteristic type:CBCharacteristicWriteWithResponse];
}

-(void) sendDataToLed:(char)ledVal
{
    char alarmSen = ledVal;
    
   // [self SetParameter:CHAR_ALARM_SEN length:sizeof(char) char_value:&ledVal];
   // [self GetParameter:CHAR_ALARM_SEN char_value:&alarmSen];
    NSData *enableBytes = [NSData dataWithBytes:&alarmSen length:sizeof(char)];
    
    [sensorTag writeValue:enableBytes forCharacteristic:ledCharacteristic type:CBCharacteristicWriteWithResponse];
}

@end
