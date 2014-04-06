//
//  R45ViewController.m
//  BeaconInfect
//
//  Created by Eric Blair on 4/1/14.
//  Copyright (c) 2014 Room 45. All rights reserved.
//

#import "R45ViewController.h"
@import CoreLocation;
@import CoreBluetooth;

@interface R45ViewController () <CBPeripheralManagerDelegate, CLLocationManagerDelegate>
@property (assign, getter = isInfected) BOOL infected;
@property (strong) CBPeripheralManager *peripheralManager;
@property (strong) CLLocationManager *locationManager;
@property (strong) NSUUID *beaconUUID;
@end

@implementation R45ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.beaconUUID = [[NSUUID alloc] initWithUUIDString:@"2F234454-CF6D-4A0F-ADF2-F4911BA9FFA9"];
    
    CLBeaconRegion *infectionBeacon = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconUUID identifier:@"InfectionBeacon"];
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
            NSLog(@"No monitoring allowed");
            return;
        }
        
        if ([CLLocationManager isRangingAvailable] == NO) {
            NSLog(@"No ranging available");
        }
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        [self.locationManager startRangingBeaconsInRegion:infectionBeacon];
        
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                         queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (self.isInfected) {
        return;
    }
    
    CLBeacon *rangedBeacon = [beacons firstObject];
    if (rangedBeacon == nil) {
        return;
    }
    
    if ([rangedBeacon proximity] == CLProximityImmediate) {
        if(self.peripheralManager.state < CBPeripheralManagerStatePoweredOn) {
            NSString *title = NSLocalizedString(@"Bluetooth must be enabled", @"");
            NSString *message = NSLocalizedString(@"To configure your device as a beacon", @"");
            NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Cancel button title in configuration Save Changes");
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
            [errorAlert show];
            
            [self.locationManager stopRangingBeaconsInRegion:region];
            
            return;
        }

        // We must construct a CLBeaconRegion that represents the payload we want the device to beacon.
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconUUID major:122 minor:77 identifier:@"InfectingBeacon"];
        NSDictionary *peripheralData = [region peripheralDataWithMeasuredPower:nil];
        
        // The region's peripheral data contains the CoreBluetooth-specific data we need to advertise.
        if(peripheralData)
        {
            [self.peripheralManager startAdvertising:peripheralData];
        }

        [UIView animateWithDuration:.3 animations:^{
            self.view.backgroundColor = [UIColor redColor];
        }];
    }
    else {

    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"%@ %@ %@", NSStringFromSelector(_cmd), region, [error localizedDescription]);
}


#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    
}

@end
