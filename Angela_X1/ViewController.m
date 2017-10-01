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

@import UserNotifications;

#define TIMER_PAUSE_INTERVAL 10.0
#define TIMER_SCAN_INTERVAL  2.0

#define SENSOR_DATA_INDEX_TEMP_INFRARED 0
#define SENSOR_DATA_INDEX_TEMP_AMBIENT  1
#define SENSOR_DATA_INDEX_HUMIDITY_TEMP 0
#define SENSOR_DATA_INDEX_HUMIDITY      1

// This could be simplified to "SensorTag" and check if it's a substring...
#define SENSOR_TAG_NAME @"CC2650 SensorTag"

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

// Properties for Background Swapping

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *sensorTag;
@property (nonatomic, assign) BOOL keepScanning;

@property (nonatomic, assign) char current_led_state; //= LED_STATE_OFF;
@property (nonatomic, assign) char current_alarm_setting; //= ALARM_OFF;

@end

CBCharacteristic *ledCharacteristic;

@implementation ViewController
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [connectionIndicator startAnimating];
    connectionIndicator.hidesWhenStopped = true;
    
    // Create the CBCentralManager.
    // NOTE: Creating the CBCentralManager with initWithDelegate will immediately call centralManagerDidUpdateState.
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
}

- (void)pauseScan {
    // Scanning uses up battery on phone, so pause the scan process for the designated interval.
    NSLog(@"*** PAUSING SCAN...");
    [NSTimer scheduledTimerWithTimeInterval:TIMER_PAUSE_INTERVAL target:self selector:@selector(resumeScan) userInfo:nil repeats:NO];
    [self.centralManager stopScan];
}

- (void)resumeScan {
    if (self.keepScanning) {
        // Start scanning again...
        NSLog(@"*** RESUMING SCAN!");
        [NSTimer scheduledTimerWithTimeInterval:TIMER_SCAN_INTERVAL target:self selector:@selector(pauseScan) userInfo:nil repeats:NO];
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

- (IBAction)switchAlarm:(UISwitch *)sender {

    char  ledState = LED_STATE_FLASH_1;
    NSData *enableBytes = [NSData dataWithBytes:&ledState length:sizeof(char)];
    
    // Read the latest status for LED to be up to date //
    [self.sensorTag readValueForCharacteristic:ledCharacteristic]; // readValue(for characteristic: CBCharacteristic)
    
    [self SetParameter:CHAR_LED_STATE length:1 char_value:&ledState];
    [self GetParameter:CHAR_LED_STATE char_value:&ledState];
    [self.sensorTag writeValue:enableBytes forCharacteristic:ledCharacteristic type:CBCharacteristicWriteWithResponse];
    
    
    
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
    
}

- (void)cleanup {
    [_centralManager cancelPeripheralConnection:self.sensorTag];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (char)SetParameter:(char)param length:(char) len char_value: (char*) value  {
    char fahrenheit = 1;
    switch(param)
    {
        case CHAR_LED_STATE:
            if(len == 1)
            {
                self.current_led_state = *(char*)value;
            }
            break;
        case CHAR_ALARM_SETTING:
            if(len == 1)
            {
                self.current_alarm_setting = *(char*)value;
            }
            break;
        case CHAR_ALARM_RECEIVED:
            break;
        default:
            break;
    }
    return fahrenheit;
}

- (char)GetParameter:(char)param  char_value: (char*) value  {
    char fahrenheit = 1;
    switch(param)
    {
        case CHAR_LED_STATE:
            *(char*)value = self.current_led_state;
            break;
        case CHAR_ALARM_SETTING:
            *(char*)value = self.current_alarm_setting;
            break;
        case CHAR_ALARM_RECEIVED:
            //self.current_led_state = LED_STATE_OFF;
            break;
        default:
            break;
    }
    return fahrenheit;
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
            self.keepScanning = YES;
            [NSTimer scheduledTimerWithTimeInterval:TIMER_SCAN_INTERVAL target:self selector:@selector(pauseScan) userInfo:nil repeats:NO];
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
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
            self.keepScanning = NO;
            
            // save a reference to the sensor tag
            self.sensorTag = peripheral;
            self.sensorTag.delegate = self;
            
            // Request a connection to the peripheral
            [self.centralManager connectPeripheral:self.sensorTag options:nil];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!");
//    self.temperatureLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:56];
//    self.temperatureLabel.text = @"Connected";
    [connectionIndicator stopAnimating];
    self.labelSearching.hidden = true;
    self.uiTextConnectUSB.hidden = true;
    self.labelAlarm.hidden = false;
    self.switchAlarmOutlet.hidden = false;
    self.buttonSettingOutlet.hidden = false;
    
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
}

#pragma mark - CBPeripheralDelegate methods

// When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service);
        NSLog(@"Service UUID: %@ \n\r", service.UUID);
        NSLog(@"Expected UUID: %@ \n\r", [CBUUID UUIDWithString:UUID_MOVEDETECTOR_SERVICE]);
        //self.temperatureLabel.text = [NSString stringWithFormat:@"UUID %@", service.UUID];
        if (([service.UUID isEqual:[CBUUID UUIDWithString:UUID_MOVEDETECTOR_SERVICE]]) /*||
                                                                                        ([service.UUID isEqual:[CBUUID UUIDWithString:UUID_HUMIDITY_SERVICE]])*/) {
                                                                                            [peripheral discoverCharacteristics:nil forService:service];
                                                                                            NSLog(@"UUID_MOVEDETECTOR_SERVICE!!!! \n\r");
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
        
        // Temperature
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ALARM_VALUE]]) {
            // Enable Temperature Sensor notification
            [self.sensorTag setNotifyValue:YES forCharacteristic:characteristic];
            
        }
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_LED_STATUS]]) {
            // Enable Temperature Sensor
            NSLog(@"UUID_LED_STATUS: %@ \n\r", characteristic.UUID); // Shirzad
            ledCharacteristic = characteristic;
            //[self.sensorTag writeValue:enableBytes forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ALRAM_SETTING]]) {
            // Enable Temperature Sensor notification
            NSLog(@"UUID_ALRAM_SETTING: %@ \n\r", characteristic.UUID); // Shirzad
            //self.temperatureLabel.text = [NSString stringWithFormat:@"HOLA!!"]; // Shirzad
            //let value: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]
            //let data = NSData(bytes: value, length: 7)
            //uint8_t data = 0x05;
            //[self.sensorTag writeValue:enableBytes forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
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
            NSLog(@"LED State Length ======  %lu \n\r", (unsigned long)dataBytes.length); // Shirzad
            NSLog(@"LED State VALUE ======  %u \n\r", (unsigned int)dataArray[0]); // Shirzad
            [self SetParameter:CHAR_LED_STATE length:dataBytes.length char_value:dataArray];
            //self.temperatureLabel.text = [NSString stringWithFormat:@"LED = %u", (unsigned int)dataArray[0]];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ALRAM_SETTING]]) {
            //[self displayTemperature:dataBytes];
            
            char dataArray[dataBytes.length]; // uint16_t dataArray[dataLength];
            [dataBytes getBytes:&dataArray length:dataBytes.length * sizeof(uint8_t)]; // [dataBytes getBytes:&dataArray length:dataLength * sizeof(uint16_t)];
            NSLog(@"Alarm Setting VALUE ======  %u \n\r", (unsigned int)dataArray[0]); // Shirzad
            [self SetParameter:CHAR_ALARM_SETTING length:dataBytes.length char_value:dataArray];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ALARM_VALUE]]) {
            //[self displayHumidity:dataBytes];
            char dataArray[dataBytes.length]; // uint16_t dataArray[dataLength];
            [dataBytes getBytes:&dataArray length:dataBytes.length * sizeof(uint8_t)]; // [dataBytes getBytes:&dataArray length:dataLength * sizeof(uint16_t)];
            NSLog(@"********* Alarm VALUE ======  %u \n\r", (unsigned int)dataArray[0]); // Shirzad
            [self SetParameter:CHAR_ALARM_SETTING length:dataBytes.length char_value:dataArray];
        }
    }
}

@end
