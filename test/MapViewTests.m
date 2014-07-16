#import "MapViewTests.h"
#import <KIF/KIFTestStepValidation.h>
#import "KIFTestActor+MapboxGL.h"
#import "MGLMapView.h"

@interface MapViewTests () <MGLMapViewDelegate>

@end

@implementation MapViewTests

- (void)beforeEach {
    [system simulateDeviceRotationToOrientation:UIDeviceOrientationPortrait];
    tester.mapView.viewControllerForLayoutGuides = tester.viewController;
    tester.mapView.centerCoordinate = CLLocationCoordinate2DMake(38.913175, -77.032458);
    tester.mapView.zoomLevel = 14;
    tester.mapView.direction = 0;
    tester.mapView.zoomEnabled = YES;
    tester.mapView.scrollEnabled = YES;
    tester.mapView.rotateEnabled = YES;
    tester.viewController.navigationController.navigationBarHidden = YES;
    tester.viewController.navigationController.toolbarHidden = YES;
    tester.mapView.delegate = self;
}

- (void)testDirectionSet {
    tester.mapView.direction = 270;
    __KIFAssertEqual(tester.mapView.direction, 270);

    [tester waitForTimeInterval:1];

    __KIFAssertEqual(tester.compass.alpha, 1);
    __KIFAssertEqualObjects([NSValue valueWithCGAffineTransform:tester.compass.transform],
                            [NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(M_PI * 1.5)]);
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

- (void)testZoomSet {
    double newZoom = 11.65;
    XCTAssertNotEqual(tester.mapView.zoomLevel, newZoom);

    tester.mapView.zoomLevel = newZoom;

    __KIFAssertEqual(tester.mapView.zoomLevel, newZoom);
}

- (void)testTopLayoutGuide {
    CGRect statusBarFrame, navigationBarFrame, compassFrame;
    UINavigationBar *navigationBar = tester.viewController.navigationController.navigationBar;

    compassFrame = [tester.compass.superview convertRect:tester.compass.frame toView:nil];
    statusBarFrame = [tester.window convertRect:[[UIApplication sharedApplication] statusBarFrame] toView:nil];
    XCTAssertFalse(CGRectIntersectsRect(compassFrame, statusBarFrame));

    tester.viewController.navigationController.navigationBarHidden = NO;
    compassFrame = [tester.compass.superview convertRect:tester.compass.frame toView:nil];
    navigationBarFrame = [tester.window convertRect:navigationBar.frame toView:nil];
    XCTAssertFalse(CGRectIntersectsRect(compassFrame, navigationBarFrame));

    [system simulateDeviceRotationToOrientation:UIDeviceOrientationLandscapeLeft];

    compassFrame = [tester.compass.superview convertRect:tester.compass.frame toView:nil];
    navigationBarFrame = [tester.window convertRect:navigationBar.frame toView:nil];
    XCTAssertFalse(CGRectIntersectsRect(compassFrame, navigationBarFrame));

    tester.viewController.navigationController.navigationBarHidden = YES;
    compassFrame = [tester.compass.superview convertRect:tester.compass.frame toView:nil];
    statusBarFrame = [tester.window convertRect:[[UIApplication sharedApplication] statusBarFrame] toView:nil];
    XCTAssertFalse(CGRectIntersectsRect(compassFrame, statusBarFrame));
}

- (void)testBottomLayoutGuide {
    CGRect logoBugFrame, toolbarFrame, attributionButtonFrame;
    UIView *logoBug = (UIView *)[tester waitForViewWithAccessibilityLabel:@"Mapbox logo"];
    UIToolbar *toolbar = tester.viewController.navigationController.toolbar;
    UIView *attributionButton = (UIView *)[tester waitForViewWithAccessibilityLabel:@"Attribution info"];

    tester.viewController.navigationController.toolbarHidden = NO;

    logoBugFrame = [logoBug.superview convertRect:logoBug.frame toView:nil];
    toolbarFrame = [tester.window convertRect:toolbar.frame toView:nil];
    XCTAssertFalse(CGRectIntersectsRect(logoBugFrame, toolbarFrame));

    attributionButtonFrame = [attributionButton.superview convertRect:attributionButton.frame toView:nil];
    XCTAssertFalse(CGRectIntersectsRect(attributionButtonFrame, toolbarFrame));

    [system simulateDeviceRotationToOrientation:UIDeviceOrientationLandscapeRight];

    logoBugFrame = [logoBug.superview convertRect:logoBug.frame toView:nil];
    toolbarFrame = [tester.window convertRect:toolbar.frame toView:nil];
    XCTAssertFalse(CGRectIntersectsRect(logoBugFrame, toolbarFrame));

    attributionButtonFrame = [attributionButton.superview convertRect:attributionButton.frame toView:nil];
    XCTAssertFalse(CGRectIntersectsRect(attributionButtonFrame, toolbarFrame));
}

- (void)testDelegateRegionWillChange {

}

- (void)mapView:(MGLMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"regionWillChangeAnimated"
                                                        object:mapView
                                                      userInfo:@{ @"animated" : @(animated) }];
}

- (void)testDelegateRegionDidChange {
    __block NSUInteger count = 0;
    [[NSNotificationCenter defaultCenter] addObserverForName:@"regionDidChangeAnimated"
                                                      object:tester.mapView
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      if ([note.userInfo[@"animated"] boolValue] == NO) {
                                                          NSLog(@"foo");
                                                      }
                                                      count++;
                                                  }];

    NSNotification *notification = [system waitForNotificationName:@"regionDidChangeAnimated"
                                                            object:tester.mapView
                                               whileExecutingBlock:^{
                                                   tester.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);
                                               }];
    XCTAssertNotNil(notification);
    __KIFAssertEqual([notification.userInfo[@"animated"] boolValue], NO);
    __KIFAssertEqual(count, 1);

    count = 0;
    notification = [system waitForNotificationName:@"regionDidChangeAnimated"
                                            object:tester.mapView
                               whileExecutingBlock:^{
                                   [tester.mapView setCenterCoordinate:CLLocationCoordinate2DMake(45, 100) animated:YES];
                               }];
    XCTAssertNotNil(notification);
    __KIFAssertEqual([notification.userInfo[@"animated"] boolValue], YES);
    __KIFAssertEqual(count, 1);

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"regionDidChangeAnimated"
                                                  object:tester.mapView];
}

- (void)mapView:(MGLMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"regionDidChangeAnimated"
                                                        object:mapView
                                                      userInfo:@{ @"animated" : @(animated) }];
}

@end
