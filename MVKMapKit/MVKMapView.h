#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface MVKMapView : UIView

@property (nonatomic) CLLocationCoordinate2D centerCoordinate;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

@end
