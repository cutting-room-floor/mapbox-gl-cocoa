#import "KIFTestActor+MapboxGL.h"
#import <KIF/UIAccessibilityElement-KIFAdditions.h>
#import "MGLMapView.h"

@implementation KIFTestActor (MapboxGL)

- (MGLMapView *)mapView {
    return (MGLMapView *)[tester waitForViewWithAccessibilityLabel:@"Map"];
}

- (UIView *)compass {
    return [tester waitForViewWithAccessibilityLabel:@"Compass"];
}

- (UIViewController *)viewController {
    return (UIViewController *)[[tester.mapView nextResponder] nextResponder];
}

@end
