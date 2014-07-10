#import "MapViewTests.h"
#import <KIF/KIFTestStepValidation.h>
#import <KIF/UIWindow-KIFAdditions.h>
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

- (void)testDirectionSet {
    tester.mapView.direction = 270;
    __KIFAssertEqual(tester.mapView.direction, 270);

    [tester waitForTimeInterval:1];

    __KIFAssertEqual(tester.compass.alpha, 1);
    __KIFAssertEqualObjects([NSValue valueWithCGAffineTransform:tester.compass.transform],
                            [NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(M_PI * 1.5)]);
}

- (void)testDirectionSetAnimated {
    [tester.mapView setDirection:90 animated:YES];
    __KIFAssertEqual(tester.mapView.direction, 90);

    [tester waitForTimeInterval:1];

    __KIFAssertEqual(tester.compass.alpha, 1);
    __KIFAssertEqualObjects([NSValue valueWithCGAffineTransform:tester.compass.transform],
                            [NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(M_PI * 0.5)]);
}

- (void)testCompassTap {
    tester.mapView.direction = 180;
    __KIFAssertEqual(tester.mapView.direction, 180);

    [tester waitForTimeInterval:1];

    [tester.compass tap];

    [tester waitForTimeInterval:1];

    __KIFAssertEqual(tester.mapView.direction, 0);
    __KIFAssertEqual(tester.compass.alpha, 0);
    __KIFAssertEqualObjects([NSValue valueWithCGAffineTransform:tester.compass.transform],
                            [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity]);
}

- (void)testDirectionReset {
    tester.mapView.direction = 100;
    __KIFAssertEqual(tester.mapView.direction, 100);

    [tester.mapView resetNorth];

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

- (void)testCenterSet {
    CLLocationCoordinate2D newCenterCoordinate = CLLocationCoordinate2DMake(45.23237263, -122.23287129);
    XCTAssertNotEqual(tester.mapView.centerCoordinate.latitude, newCenterCoordinate.latitude);
    XCTAssertNotEqual(tester.mapView.centerCoordinate.longitude, newCenterCoordinate.longitude);

    [tester.mapView setCenterCoordinate:newCenterCoordinate];

    XCTAssertTrue(tester.mapView.centerCoordinate.latitude > 45.2323);
    XCTAssertTrue(tester.mapView.centerCoordinate.latitude < 45.2324);
    XCTAssertTrue(tester.mapView.centerCoordinate.longitude > -122.2329);
    XCTAssertTrue(tester.mapView.centerCoordinate.longitude < -122.2328);
}

//- (void)testCenterSetAnimated {
//    CLLocationCoordinate2D oldCenterCoordinate = tester.mapView.centerCoordinate;
//    CLLocationCoordinate2D newCenterCoordinate = CLLocationCoordinate2DMake(45.23237263, -122.23287129);
//    XCTAssertNotEqual(oldCenterCoordinate.latitude, newCenterCoordinate.latitude);
//    XCTAssertNotEqual(oldCenterCoordinate.longitude, newCenterCoordinate.longitude);
//
//    [tester.mapView setCenterCoordinate:newCenterCoordinate animated:YES];
//
//    [tester waitForTimeInterval:0.1];
//
//    CLLocationDegrees midLatitude = tester.mapView.centerCoordinate.latitude;
//    CLLocationDegrees midLongitude = tester.mapView.centerCoordinate.longitude;
//    XCTAssertTrue(midLatitude > oldCenterCoordinate.latitude);
//    XCTAssertTrue(midLatitude < newCenterCoordinate.latitude);
//    XCTAssertTrue(midLongitude < oldCenterCoordinate.longitude);
//    XCTAssertTrue(midLongitude > newCenterCoordinate.longitude);
//
//    [tester waitForTimeInterval:1];
//
//    XCTAssertTrue(tester.mapView.centerCoordinate.latitude > midLatitude);
//    XCTAssertTrue(tester.mapView.centerCoordinate.latitude < 45.2324);
//    XCTAssertTrue(tester.mapView.centerCoordinate.latitude > 45.2323);
//    XCTAssertTrue(tester.mapView.centerCoordinate.longitude < midLongitude);
//    XCTAssertTrue(tester.mapView.centerCoordinate.longitude < -122.2328);
//    XCTAssertTrue(tester.mapView.centerCoordinate.longitude > -122.2329);
//}

- (void)testZoomSet {
    double newZoom = 11.65;
    XCTAssertNotEqual(tester.mapView.zoomLevel, newZoom);

    tester.mapView.zoomLevel = newZoom;

    __KIFAssertEqual(tester.mapView.zoomLevel, newZoom);
}

- (void)testZoomSetAnimated {
    double newZoom = 8.47;
    double oldZoom = tester.mapView.zoomLevel;
    XCTAssertNotEqual(oldZoom, newZoom);

    [tester.mapView setZoomLevel:newZoom animated:YES];

    [tester waitForTimeInterval:0.1];

    XCTAssertTrue(tester.mapView.zoomLevel < oldZoom);

    [tester waitForTimeInterval:1];

    __KIFAssertEqual(tester.mapView.zoomLevel, newZoom);
}

//- (void)testTopLayoutGuideStatusBar {
//    CGRect statusBarFrame = [tester.viewController.view convertRect:[[UIApplication sharedApplication] statusBarFrame]
//                                                             toView:tester.viewController.view];
//
//    __KIFAssertEqualObjects(tester.mapView.viewControllerForLayoutGuides, tester.viewController);
//
//    CGRect currentCompassFrame = [tester.viewController.view convertRect:tester.compass.frame
//                                                                  toView:tester.viewController.view];
//
//    XCTAssertFalse(CGRectIntersectsRect(currentCompassFrame, statusBarFrame));
//
//}

@end
