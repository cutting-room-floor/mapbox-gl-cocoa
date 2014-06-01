#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface MGLMapView : UIView

// debug API that will go away
//
@property (nonatomic, getter=isDebugActive) BOOL debugActive;
- (void)resetNorth;
- (void)resetPosition;
- (void)toggleDebug;
- (void)toggleStyle;

// regular API
//
@property (nonatomic, weak) UIViewController *viewControllerForLayoutGuides;

@property(nonatomic, getter=isZoomEnabled) BOOL zoomEnabled;
@property(nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;
@property(nonatomic, getter=isRotateEnabled) BOOL rotateEnabled;

@property (nonatomic) CLLocationCoordinate2D centerCoordinate;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

@property (nonatomic) double zoomLevel;
- (void)setZoomLevel:(double)zoomLevel animated:(BOOL)animated;

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(double)zoomLevel animated:(BOOL)animated;

@property (nonatomic) CLLocationDirection direction;
- (void)setDirection:(CLLocationDirection)direction animated:(BOOL)animated;

// styling API
//
- (NSDictionary *)getRawStyle;
- (void)setRawStyle:(NSDictionary *)style;

- (NSArray *)getStyleOrderedLayerNames;
- (void)setStyleOrderedLayerNames:(NSArray *)orderedLayerNames;

- (NSArray *)getAllStyleClasses;
- (NSArray *)getAppliedStyleClasses;
- (void)setAppliedStyleClasses:(NSArray *)appliedClasses;
- (void)setAppliedStyleClasses:(NSArray *)appliedClasses transitionDuration:(NSTimeInterval)transitionDuration;

- (NSDictionary *)getStyleDescriptionForLayer:(NSString *)layerName inClass:(NSString *)className;
- (void)setStyleDescription:(NSDictionary *)styleDescription forLayer:(NSString *)layerName inClass:(NSString *)className;

@end
