#import "KIFTestActor+MapboxGL.h"
#import <KIF/UIAccessibilityElement-KIFAdditions.h>
#import "MGLMapView.h"

@implementation KIFTestActor (MapboxGL)

- (UIWindow *)window {
    return [[UIApplication sharedApplication] windows][0];
}

- (UIViewController *)viewController {
    return (UIViewController *)[[tester.mapView nextResponder] nextResponder];
}

- (MGLMapView *)mapView {
    return (MGLMapView *)[tester waitForViewWithAccessibilityLabel:@"Map"];
}

- (UIView *)compass {
    return [tester waitForViewWithAccessibilityLabel:@"Compass"];
}

@end
