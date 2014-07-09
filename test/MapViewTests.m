#import "MapViewTests.h"
#import <KIF/KIFTestStepValidation.h>
#import "KIFTestActor+MapboxGL.h"
#import "MGLMapView.h"

@implementation MapViewTests

- (void)beforeEach {
    tester.mapView.centerCoordinate = CLLocationCoordinate2DMake(38.913175, -77.032458);
    tester.mapView.zoomLevel = 14;
    tester.mapView.direction = 0;
    tester.mapView.zoomEnabled = YES;
    tester.mapView.scrollEnabled = YES;
    tester.mapView.rotateEnabled = YES;
}

- (void)testDirectionSetInstant {
    tester.mapView.direction = 270;
    __KIFAssertEqual(tester.mapView.direction, 270);

    // wait for compass fade in
    [tester waitForTimeInterval:1];
    __KIFAssertEqual(tester.compass.alpha, 1);
    __KIFAssertEqualObjects([NSValue valueWithCGAffineTransform:tester.compass.transform],
                            [NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(M_PI * 1.5)]);
}

- (void)testDirectionSetAnimated {
    tester.mapView.direction = 90;
    __KIFAssertEqual(tester.mapView.direction, 90);

    // wait for compass fade in
    [tester waitForTimeInterval:1];
    __KIFAssertEqual(tester.compass.alpha, 1);
    __KIFAssertEqualObjects([NSValue valueWithCGAffineTransform:tester.compass.transform],
                            [NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(M_PI * 0.5)]);
}

- (void)testDirectionReset {
    tester.mapView.direction = 180;
    __KIFAssertEqual(tester.mapView.direction, 180);

    // wait for compass fade in
    [tester waitForTimeInterval:1];
    [tester.compass tap];

    // wait for rotation animation
    [tester waitForTimeInterval:1];
    __KIFAssertEqual(tester.mapView.direction, 0);
    __KIFAssertEqual(tester.compass.alpha, 0);
    __KIFAssertEqualObjects([NSValue valueWithCGAffineTransform:tester.compass.transform],
                            [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity]);
}

- (void)testPanning {
    CLLocationCoordinate2D centerCoordinate = tester.mapView.centerCoordinate;
    [tester.mapView dragFromPoint:CGPointMake(10, 10) toPoint:CGPointMake(50, 50)];
    XCTAssertTrue(tester.mapView.centerCoordinate.latitude > centerCoordinate.latitude);
    XCTAssertTrue(tester.mapView.centerCoordinate.longitude < centerCoordinate.longitude);
}

- (void)testPanningDisabled {
    tester.mapView.scrollEnabled = NO;
    CLLocationCoordinate2D centerCoordinate = tester.mapView.centerCoordinate;
    [tester.mapView dragFromPoint:CGPointMake(10, 10) toPoint:CGPointMake(50, 50)];
    __KIFAssertEqual(centerCoordinate.latitude, tester.mapView.centerCoordinate.latitude);
    __KIFAssertEqual(centerCoordinate.longitude, tester.mapView.centerCoordinate.longitude);
}

@end
