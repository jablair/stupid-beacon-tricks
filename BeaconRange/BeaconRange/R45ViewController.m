//
//  R45ViewController.m
//  BeaconRange
//
//  Created by Eric Blair on 4/6/14.
//  Copyright (c) 2014 Room 45. All rights reserved.
//

#import "R45ViewController.h"
@import CoreLocation;

@interface R45ViewController () <CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *horizontalConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *horizontalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet UIView *positionIndicator;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic, getter = isReadyForUpdate) BOOL readyForUpdate;
@end

static NSString * const R45BeaconRegionIndetifier = @"R45BeaconRegionIndetifier";

@implementation R45ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.readyForUpdate = YES;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
            NSLog(@"No monitoring allowed");
            return;
        }
        
        if ([CLLocationManager isRangingAvailable] == NO) {
            NSLog(@"No ranging available");
            return;
        }

        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:@"2F234454-CF6D-4A0F-ADF2-F4911BA9FFA9"];
        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID identifier:R45BeaconRegionIndetifier];
        
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
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
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSUInteger topLeftIndex = [beacons indexOfObjectPassingTest:^BOOL(CLBeacon *beacon, NSUInteger idx, BOOL *stop) {
        return [beacon.minor integerValue] == 1;
    }];
    
    NSUInteger topRightIndex = [beacons indexOfObjectPassingTest:^BOOL(CLBeacon *beacon, NSUInteger idx, BOOL *stop) {
        return [beacon.minor integerValue] == 13;
    }];
    
    NSUInteger bottomIndex = [beacons indexOfObjectPassingTest:^BOOL(CLBeacon *beacon, NSUInteger idx, BOOL *stop) {
        return [beacon.minor integerValue] == 77;
    }];
    
    if (topLeftIndex == NSNotFound || topRightIndex == NSNotFound || bottomIndex == NSNotFound) {
        NSLog(@"Failed to locate necessary beacons");
        return;
    }

    if (self.isReadyForUpdate == NO)
        return;
    
    self.readyForUpdate = NO;
    
    CLBeacon *topLeftBeacon = beacons[topLeftIndex];
    CLBeacon *topRightBeacon = beacons[topRightIndex];
    CLBeacon *bottomBeacon = beacons[bottomIndex];
    
    // I'd like to apologize to all of my old math teachers
    CGFloat d = 2.2, i = 1.1, j = 3.5;
    CGFloat x = MAX((pow(topLeftBeacon.accuracy, 2) - pow(topRightBeacon.accuracy,2) + pow(d,2)) / (2*d), 0);
    CGFloat y = MAX((pow(topLeftBeacon.accuracy, 2) - pow(bottomBeacon.accuracy, 2) + pow(i,2) + pow(j,2)) / (2*j) - ((i/j)*x), 0);
    
    self.horizontalConstraint.constant = MIN(x/d , 1) * (self.horizontalSpaceConstraint.constant - CGRectGetWidth([self.positionIndicator bounds]));
    self.verticalConstraint.constant = MIN(y/j, 1) * (self.verticalSpaceConstraint.constant - CGRectGetHeight([self.positionIndicator bounds]));
    
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.readyForUpdate = YES;
    }];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"%@ %@ %@", NSStringFromSelector(_cmd), region, [error localizedDescription]);
}


@end
