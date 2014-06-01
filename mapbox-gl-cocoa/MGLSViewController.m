#import "MGLSViewController.h"

#import "MGLMapView.h"

@implementation MGLSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor orangeColor];

    MGLMapView *mapView = [[MGLMapView alloc] initWithFrame:CGRectInset(self.view.bounds, 50, 50)];
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:mapView];

    mapView.viewControllerForLayoutGuides = self;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void)
    {
        [mapView setCenterCoordinate:CLLocationCoordinate2DMake(45, -122) zoomLevel:6 animated:YES];
    });
}

@end
