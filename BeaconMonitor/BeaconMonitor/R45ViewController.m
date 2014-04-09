//
//  R45ViewController.m
//  BeaconMonitor
//
//  Created by Eric Blair on 3/31/14.
//  Copyright (c) 2014 Room 45. All rights reserved.
//

#import "R45ViewController.h"
@import CoreLocation;

@interface R45ViewController () <CLLocationManagerDelegate>
@property (strong) CLLocationManager *locationManager;
@property (assign) BOOL notificationHandled;
@end

static NSString * const R45BeaconRegionIndetifier = @"R45BeaconRegionIndetifier";

@implementation R45ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
            NSLog(@"No monitoring allowed");
            return;
        }
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;

        NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:@"2F234454-CF6D-4A0F-ADF2-F4911BA9FFA9"];
        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID identifier:R45BeaconRegionIndetifier];
        beaconRegion.notifyEntryStateOnDisplay = YES;
        
        [self.locationManager startMonitoringForRegion:beaconRegion];
    }
    else {
        NSLog(@"No monitoring available");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CLLocationManagerDelegate Methods
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    self.notificationHandled = NO;
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (state != CLRegionStateInside) {
        return;
    }

    if (self.notificationHandled)
        return;

    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Entered monitoring range";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    self.notificationHandled = YES;
}

@end
