Stupid Beacon Tricks
====================

Some demo projects that I've put together for my demo of things you can do with can with iBeacons and iOS 7.

BeaconMonitor
-------------

Quick sample showing setup of basic beacon configuration and location monitoring. Should look very familiar to anybody who's worked with geofecning code in Core Location.

BeaconWander
------------

Demo application of ranging beacons and leveraging the proximity property of beacons.

BeaconRange
-----------

Demonstration of ranging multiple beacons in a single region. Somewhat bastardizes 2D trilateration to calculate a the relative position of the device based on the known position of three beacons.

Not the recommended way of figuring out location based on iBeacons (and the math may well be wrong). Apple seems to recommend relying on the `CLProximity` values over the raw `accuracy` values.

BeaconInfect
------------

Demonstration of turning an iOS 7 devices into an iBeacon.

