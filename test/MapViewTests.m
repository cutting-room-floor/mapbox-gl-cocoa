#import "MapViewTests.h"
#import <KIF/KIFTestStepValidation.h>
#import "KIFTestActor+MapboxGL.h"
#import "MGLMapView.h"

NSString *const MGLRegionWillChangeAnimatedNotification = @"MGLRegionWillChangeAnimatedNotification";
NSString *const MGLRegionDidChangeAnimatedNotification  = @"MGLRegionDidChangeAnimatedNotification";
NSString *const MGLWillStartLoadingMapNotification      = @"MGLWillStartLoadingMapNotification";
NSString *const MGLDidFinishLoadingMapNotification      = @"MGLDidFinishLoadingMapNotification";
NSString *const MGLDidFailLoadingMapNotification        = @"MGLDidFailLoadingMapNotification";
NSString *const MGLWillStartRenderingMapNotification    = @"MGLWillStartRenderingMapNotification";
NSString *const MGLDidFinishRenderingMapNotification    = @"MGLDidFinishRenderingMapNotification";

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

- (void)afterAll {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)testZoom {
    double zoom = tester.mapView.zoomLevel;

    [tester.mapView zoomAtPoint:CGPointMake(tester.mapView.bounds.size.width / 2,
                                            tester.mapView.bounds.size.height / 2)
                       distance:50
                          steps:10];

    XCTAssertTrue(tester.mapView.zoomLevel > zoom);

    zoom = tester.mapView.zoomLevel;
    [tester.mapView pinchAtPoint:CGPointMake(tester.mapView.bounds.size.width / 2,
                                             tester.mapView.bounds.size.height / 2)
                        distance:50
                           steps:10];

    XCTAssertTrue(tester.mapView.zoomLevel < zoom);
}

- (void)testZoomDisabled {
    tester.mapView.zoomEnabled = NO;
    double zoom = tester.mapView.zoomLevel;

    [tester.mapView zoomAtPoint:CGPointMake(tester.mapView.bounds.size.width / 2,
                                            tester.mapView.bounds.size.height / 2)
                       distance:50
                          steps:10];

    __KIFAssertEqual(tester.mapView.zoomLevel, zoom);

    [tester.mapView pinchAtPoint:CGPointMake(tester.mapView.bounds.size.width / 2,
                                            tester.mapView.bounds.size.height / 2)
                        distance:50
                           steps:10];

    __KIFAssertEqual(tester.mapView.zoomLevel, zoom);
}

- (void)testPan {
    CLLocationCoordinate2D centerCoordinate = tester.mapView.centerCoordinate;

    [tester.mapView dragFromPoint:CGPointMake(10, 10) toPoint:CGPointMake(50, 50)];

    XCTAssertTrue(tester.mapView.centerCoordinate.latitude > centerCoordinate.latitude);
    XCTAssertTrue(tester.mapView.centerCoordinate.longitude < centerCoordinate.longitude);
}

- (void)testPanDisabled {
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

    XCTAssertTrue(tester.mapView.centerCoordinate.latitude == newCenterCoordinate.latitude);
    XCTAssertTrue(tester.mapView.centerCoordinate.longitude == newCenterCoordinate.longitude);
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
    __block NSUInteger unanimatedCount = 0;
    __block NSUInteger animatedCount = 0;
    [[NSNotificationCenter defaultCenter] addObserverForName:MGLRegionWillChangeAnimatedNotification
                                                      object:tester.mapView
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      if ([note.userInfo[@"animated"] boolValue]) {
                                                          animatedCount++;
                                                      } else {
                                                          unanimatedCount++;
                                                      }
                                                  }];

    NSNotification *notification = [system waitForNotificationName:MGLRegionWillChangeAnimatedNotification
                                                            object:tester.mapView
                                               whileExecutingBlock:^{
                                                   tester.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);
                                               }];

    [tester waitForTimeInterval:1];

    XCTAssertNotNil(notification);
    __KIFAssertEqualObjects(notification.userInfo[@"animated"], @NO);
    __KIFAssertEqual(unanimatedCount, 1);
    __KIFAssertEqual(animatedCount, 0);

    unanimatedCount = 0;
    animatedCount = 0;
    notification = [system waitForNotificationName:MGLRegionWillChangeAnimatedNotification
                                            object:tester.mapView
                               whileExecutingBlock:^{
                                   [tester.mapView setCenterCoordinate:CLLocationCoordinate2DMake(45, 100) animated:YES];
                               }];

    [tester waitForTimeInterval:1];

    XCTAssertNotNil(notification);
    __KIFAssertEqualObjects(notification.userInfo[@"animated"], @YES);
    __KIFAssertEqual(unanimatedCount, 0);
    __KIFAssertEqual(animatedCount, 1);
}

- (void)mapView:(MGLMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:MGLRegionWillChangeAnimatedNotification
                                                        object:mapView
                                                      userInfo:@{ @"animated" : @(animated) }];
}

- (void)testDelegateRegionDidChange {
    __block NSUInteger unanimatedCount = 0;
    __block NSUInteger animatedCount = 0;
    [[NSNotificationCenter defaultCenter] addObserverForName:MGLRegionDidChangeAnimatedNotification
                                                      object:tester.mapView
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      if ([note.userInfo[@"animated"] boolValue]) {
                                                          animatedCount++;
                                                      } else {
                                                          unanimatedCount++;
                                                      }
                                                  }];

    NSNotification *notification = [system waitForNotificationName:MGLRegionDidChangeAnimatedNotification
                                                            object:tester.mapView
                                               whileExecutingBlock:^{
                                                   tester.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);
                                               }];

    [tester waitForTimeInterval:1];

    XCTAssertNotNil(notification);
    __KIFAssertEqualObjects(notification.userInfo[@"animated"], @NO);
    __KIFAssertEqual(unanimatedCount, 1);

    notification = [system waitForNotificationName:MGLRegionDidChangeAnimatedNotification
                                            object:tester.mapView
                               whileExecutingBlock:^{
                                   [tester.mapView setCenterCoordinate:CLLocationCoordinate2DMake(45, 100) animated:YES];
                               }];

    [tester waitForTimeInterval:1];

    XCTAssertNotNil(notification);
    __KIFAssertEqualObjects(notification.userInfo[@"animated"], @YES);
    __KIFAssertEqual(animatedCount, 1);
}

- (void)mapView:(MGLMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:MGLRegionDidChangeAnimatedNotification
                                                        object:mapView
                                                      userInfo:@{ @"animated" : @(animated) }];
}

- (void)testDelegateWillStartLoading {
    __block BOOL started = NO;
    [[NSNotificationCenter defaultCenter] addObserverForName:MGLWillStartLoadingMapNotification
                                                      object:tester.mapView
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      started = YES;
                                                  }];

    tester.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);

    [tester waitForTimeInterval:0.1];

    __KIFAssertEqual(started, YES);
}

- (void)mapViewWillStartLoadingMap:(MGLMapView *)mapView {
    [[NSNotificationCenter defaultCenter] postNotificationName:MGLWillStartLoadingMapNotification
                                                        object:mapView
                                                      userInfo:nil];
}

- (void)testDelegateDidFinishLoading {
    __block BOOL finished = NO;
    [[NSNotificationCenter defaultCenter] addObserverForName:MGLDidFinishLoadingMapNotification
                                                      object:tester.mapView
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      finished = YES;
                                                  }];

    tester.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);

    [tester waitForTimeInterval:3.0];

    __KIFAssertEqual(finished, YES);
}

- (void)mapViewDidFinishLoadingMap:(MGLMapView *)mapView {
    [[NSNotificationCenter defaultCenter] postNotificationName:MGLDidFinishLoadingMapNotification
                                                        object:mapView
                                                      userInfo:nil];

}

- (void)testDelegateDidFailLoading {
    // TODO: mock network calls & fake an error
}

- (void)mapViewDidFailLoadingMap:(MGLMapView *)mapView withError:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:MGLDidFailLoadingMapNotification
                                                        object:mapView
                                                      userInfo:@{ @"error" : error }];
}

- (void)testDelegateWillStartRendering {
    __block BOOL started = NO;
    [[NSNotificationCenter defaultCenter] addObserverForName:MGLWillStartRenderingMapNotification
                                                      object:tester.mapView
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      started = YES;
                                                  }];

    tester.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);

    [tester waitForTimeInterval:0.1];

    __KIFAssertEqual(started, YES);
}

- (void)mapViewWillStartRenderingMap:(MGLMapView *)mapView {
    [[NSNotificationCenter defaultCenter] postNotificationName:MGLWillStartRenderingMapNotification
                                                        object:mapView
                                                      userInfo:nil];
}

- (void)testDelegateDidFinishRendering {
    __block BOOL finished = NO;
    __block BOOL fullyRendered = NO;
    [[NSNotificationCenter defaultCenter] addObserverForName:MGLDidFinishRenderingMapNotification
                                                      object:tester.mapView
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      finished = YES;
                                                      fullyRendered = [note.userInfo[@"fullyRendered"] boolValue];
                                                  }];

    tester.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);

    [tester waitForTimeInterval:3.0];

    __KIFAssertEqual(finished, YES);
    __KIFAssertEqual(fullyRendered, YES);
}

- (void)mapViewDidFinishRenderingMap:(MGLMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    [[NSNotificationCenter defaultCenter] postNotificationName:MGLDidFinishRenderingMapNotification
                                                        object:mapView
                                                      userInfo:@{ @"fullyRendered" : @(fullyRendered) }];
}

@end
