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

- (void)cleanup {
    [_centralManager cancelPeripheralConnection:self.sensorTag];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


- (IBAction)switchAlarm:(UISwitch *)sender {
}

@end
