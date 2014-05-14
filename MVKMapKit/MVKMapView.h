#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface MVKMapView : UIView

@property (nonatomic) CLLocationCoordinate2D centerCoordinate;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

@property (nonatomic) double zoomLevel;
- (void)setZoomLevel:(double)zoomLevel animated:(BOOL)animated;

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(double)zoomLevel animated:(BOOL)animated;

@end
