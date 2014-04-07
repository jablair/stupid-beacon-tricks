//
//  R45ViewController.m
//  BeaconWander
//
//  Created by Eric Blair on 3/18/14.
//  Copyright (c) 2014 Room 45. All rights reserved.
//

#import "R45ViewController.h"
@import CoreLocation;
@import AVFoundation;

@interface R45ViewController () <CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *proximityLabel;
@property (weak, nonatomic) IBOutlet UIView *beaconIndicator1;
@property (weak, nonatomic) IBOutlet UIView *beaconIndicator2;
@property (weak, nonatomic) IBOutlet UIView *beaconIndicator3;
@property (weak, nonatomic) IBOutlet UIView *beaconIndicator4;
@property (strong) CLLocationManager *locationManager;
@property (strong) NSTimer *beaconTimer;
@property (copy) NSArray *beaconRegionArray;
@property (copy) NSArray *beaconIndicators;
@property (assign) NSUInteger currentBeaconIndex;
@property (strong) AVSpeechSynthesizer *synthesizer;
@property (assign) CLProximity lastProximity;
@end

@implementation R45ViewController

static NSString * const R45BeaconRegionStation1 = @"Station 1";
static NSString * const R45BeaconRegionStation2 = @"Station 2";
static NSString * const R45BeaconRegionStation3 = @"Station 3";
static NSString * const R45BeaconRegionStation4 = @"Station 4";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUUID *startBeaconUUID = [[NSUUID alloc] initWithUUIDString:@"2F234454-CF6D-4A0F-ADF2-F4911BA9FFA9"];
    
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    
    self.beaconRegionArray = @[[[CLBeaconRegion alloc] initWithProximityUUID:startBeaconUUID major:214 minor:1 identifier:R45BeaconRegionStation1],
                               [[CLBeaconRegion alloc] initWithProximityUUID:startBeaconUUID major:214 minor:13 identifier:R45BeaconRegionStation2],
                               [[CLBeaconRegion alloc] initWithProximityUUID:startBeaconUUID major:214 minor:77 identifier:R45BeaconRegionStation3],
                               [[CLBeaconRegion alloc] initWithProximityUUID:startBeaconUUID major:214 minor:99 identifier:R45BeaconRegionStation4]];

    self.beaconIndicators = @[self.beaconIndicator1, self.beaconIndicator2, self.beaconIndicator3, self.beaconIndicator4];

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

        [self.locationManager startRangingBeaconsInRegion:self.beaconRegionArray[self.currentBeaconIndex]];
    }
    else {
        NSLog(@"No monitoring available");
    }
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)foundBeacon:(NSTimer *)timer
{
    NSLog(@"Beacon located");
    
    self.beaconTimer = nil;
    
    [self.locationManager stopRangingBeaconsInRegion:[timer userInfo]];
    
    [(UIView *)self.beaconIndicators[self.currentBeaconIndex] setBackgroundColor:[UIColor greenColor]];
    
    self.currentBeaconIndex++;
    
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[NSString stringWithFormat:@"Beacon %lu located!", self.currentBeaconIndex]];
    utterance.rate = .4;
    [self.synthesizer speakUtterance:utterance];
    
    if (self.currentBeaconIndex < [self.beaconRegionArray count]) {
        CLBeaconRegion *nextRegion = self.beaconRegionArray[self.currentBeaconIndex];
        [self.locationManager startRangingBeaconsInRegion:nextRegion];
        
        [(UIView *)self.beaconIndicators[self.currentBeaconIndex] setBackgroundColor:[UIColor yellowColor]];
        
        self.proximityLabel.text = @"";
    }
    else {
        utterance = [[AVSpeechUtterance alloc] initWithString:@"Game Over!"];
        utterance.rate = .4;
        [self.synthesizer speakUtterance:utterance];
        
        self.proximityLabel.text = @"Game Over!";
    }
}

#pragma mark - CLLocationManagerDelegate Methods
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    CLBeacon *rangedBeacon = [beacons firstObject];
//    NSLog(@"%@ %@", [region identifier], rangedBeacon);
    
    if ([[region identifier] isEqualToString:[self.beaconRegionArray[self.currentBeaconIndex] identifier]] == NO) {
        NSLog(@"Non-current region ranged - %@", [region identifier]);
        return;
    }
    
    if ([rangedBeacon proximity] == CLProximityImmediate) {
        if (self.beaconTimer == nil) {
            self.beaconTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(foundBeacon:) userInfo:region repeats:NO];
        }
    }
    else if (self.beaconTimer) {
        [self.beaconTimer invalidate];
        self.beaconTimer = nil;
    }
    
    CGFloat redComponent, blueComponent;
    NSString *proximityString;
    switch ([rangedBeacon proximity]) {
        case CLProximityUnknown:
            redComponent = 0.0;
            blueComponent = 1.0;
            proximityString = @"Unknown";
            break;
        case CLProximityFar:
            redComponent = .33;
            blueComponent = .67;
            proximityString = @"Far";
            break;
        case CLProximityNear:
            redComponent = .67;
            blueComponent = .33;
            proximityString = @"Near";
            break;
        case CLProximityImmediate:
            redComponent = 1.0;
            blueComponent = 0.0;
            proximityString = @"Immediate";
            break;
            
        default:
            break;
    }
    
    AVSpeechUtterance *utterance;
    if ([rangedBeacon proximity] < self.lastProximity && [rangedBeacon proximity] != CLProximityUnknown) {
        utterance = [[AVSpeechUtterance alloc] initWithString:@"Warmer"];
    }
    else if ([rangedBeacon proximity] > self.lastProximity) {
        utterance = [[AVSpeechUtterance alloc] initWithString:@"Colder"];
    }
    
    if (utterance) {
        utterance.rate = .4;
        [self.synthesizer speakUtterance:utterance];
    }
    self.lastProximity = [rangedBeacon proximity];
    
    self.proximityLabel.text = proximityString;
    UIColor *backgroundColor = [UIColor colorWithRed:redComponent green:0.0 blue:blueComponent alpha:1.0];
    [UIView animateWithDuration:.3 animations:^{
        self.view.backgroundColor = backgroundColor;
    }];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"%@ %@ %@", NSStringFromSelector(_cmd), region, [error localizedDescription]);
}

@end
