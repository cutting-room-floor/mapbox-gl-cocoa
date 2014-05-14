#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface MVKMapView : UIView

// debug API that will go away
//
@property (nonatomic, getter=isDebugActive) BOOL debugActive;
- (void)resetNorth;
- (void)resetPosition;
- (void)toggleDebug;
- (void)toggleRaster;

// regular API
//
@property (nonatomic) CLLocationCoordinate2D centerCoordinate;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

@property (nonatomic) double zoomLevel;
- (void)setZoomLevel:(double)zoomLevel animated:(BOOL)animated;

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(double)zoomLevel animated:(BOOL)animated;

@property (nonatomic) CLLocationDirection direction;
- (void)setDirection:(CLLocationDirection)direction animated:(BOOL)animated;

@end
