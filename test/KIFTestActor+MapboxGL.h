#import <KIF/KIF.h>

@class MGLMapView;

@interface KIFTestActor (MapboxGL)

@property (nonatomic, readonly) MGLMapView *mapView;
@property (nonatomic, readonly) UIView *compass;

@end
