#import "MGLTViewController.h"
#import "MGLMapView.h"

@implementation MGLTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    MGLMapView *mapView = [[MGLMapView alloc] initWithFrame:self.view.bounds];
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:mapView];
}

@end
