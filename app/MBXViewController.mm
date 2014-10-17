#import "MBXViewController.h"

#import "MGLMapView.h"

#import "settings_nsuserdefaults.hpp"

#import <CoreLocation/CoreLocation.h>

@interface MBXViewController () <CLLocationManagerDelegate>

@property (nonatomic) MGLMapView *mapView;
@property (nonatomic) BOOL debug;
@property (nonatomic) UIView *palette;
@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation MBXViewController

mbgl::Settings_NSUserDefaults *settings = nullptr;

#pragma mark - Setup

- (id)init
{
    self = [super init];

    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveState:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreState:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *accessToken = [[NSProcessInfo processInfo] environment][@"MAPBOX_ACCESS_TOKEN"];
    if (accessToken) {
        // Store to preferences so that we can launch the app later on without having to specify
        // token.
        [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"access_token"];
    } else {
        // Try to retrieve from preferences, maybe we've stored them there previously and can reuse
        // the token.
        accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"access_token"];
    }

    if ( ! accessToken) NSLog(@"No access token set. Mapbox vector tiles won't work.");

    self.mapView = [[MGLMapView alloc] initWithFrame:self.view.bounds accessToken:accessToken];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.mapView.viewControllerForLayoutGuides = self;

    settings = new mbgl::Settings_NSUserDefaults();
    [self restoreState:nil];

    [self setupDebugUI];

    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

- (void)saveState:(NSNotification *)notification
{
    if (self.mapView && settings)
    {
        settings->longitude = self.mapView.centerCoordinate.longitude;
        settings->latitude = self.mapView.centerCoordinate.latitude;
        settings->zoom = self.mapView.zoomLevel;
        settings->bearing = self.mapView.direction;
        settings->debug = self.mapView.isDebugActive;
        settings->save();
    }
}

- (void)restoreState:(NSNotification *)notification
{
    if (self.mapView && settings) {
        settings->load();
        [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(settings->latitude, settings->longitude) zoomLevel:settings->zoom animated:NO];
        self.mapView.direction = settings->bearing;
        [self.mapView setDebugActive:settings->debug];
    }
}

#pragma clang diagnostic pop

- (void)setupDebugUI
{
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
    singleTap.numberOfTapsRequired = 1;
    [self.mapView addGestureRecognizer:singleTap];

    NSArray *selectorNames = @[ @"unrotate", @"resetPosition", @"toggleDebug", @"locateUser" ];
    CGFloat buttonSize  = 20;
    CGFloat bufferSize  = 10;
    CGFloat alpha       = 0.75;
    CGFloat paletteWidth  = buttonSize + (2 * bufferSize);
    CGFloat paletteHeight = [selectorNames count] * (buttonSize + bufferSize) + bufferSize;
    self.palette = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - paletteWidth,
                                                            (self.view.bounds.size.height - paletteHeight) / 2,
                                                            paletteWidth,
                                                            paletteHeight)];
    self.palette.backgroundColor = [UIColor colorWithWhite:0 alpha:alpha];
    self.palette.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.palette.layer.cornerRadius = bufferSize;
    [self.view addSubview:self.palette];
    for (NSString *selectorName in selectorNames)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(bufferSize,
                                  ([selectorNames indexOfObject:selectorName] * (buttonSize + bufferSize)) + bufferSize,
                                  buttonSize,
                                  buttonSize);
        [button setImage:[UIImage imageNamed:[selectorName stringByAppendingString:@".png"]] forState:UIControlStateNormal];
        [button addTarget:self action:NSSelectorFromString(selectorName) forControlEvents:UIControlEventTouchUpInside];
        [self.palette addSubview:button];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Debugging UI

- (void)handleSingleTapGesture:(UITapGestureRecognizer *)singleTap
{
    if (singleTap.state == UIGestureRecognizerStateEnded)
    {
        [self togglePalette];
    }
}

- (void)togglePalette
{
    if (self.palette.alpha < 1)
    {
        self.palette.userInteractionEnabled = YES;

        [UIView animateWithDuration:0.25 animations:^(void)
        {
            self.palette.alpha = 1;
        }];
    }
    else
    {
        self.palette.userInteractionEnabled = NO;

        [UIView animateWithDuration:0.25 animations:^(void)
        {
            self.palette.alpha = 0;
        }];
    }
}

- (void)unrotate
{
    [self.mapView resetNorth];
}

- (void)resetPosition
{
    [self.mapView resetPosition];
}

- (void)toggleDebug
{
    [self.mapView toggleDebug];

    self.debug = ! self.debug;
}

- (void)locateUser
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
    {
        [[[UIAlertView alloc] initWithTitle:@"Authorization Denied"
                                    message:@"Please enable location services for this app in Privacy settings."
                                   delegate:nil
                          cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
    else
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([CLLocationManager instancesRespondToSelector:@selector(requestWhenInUseAuthorization)])
        {
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)
            {
                [self.locationManager startUpdatingLocation];
            }
            else
            {
                [_locationManager requestWhenInUseAuthorization];
            }
        }
        else
        {
            [self.locationManager startUpdatingLocation];
        }
#else
        [self.locationManager startUpdatingLocation];
#endif
    }
}

#pragma mark - Destruction

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (settings)
    {
        [self saveState:nil];
        delete settings;
        settings = nullptr;
    }
}

#pragma mark - User location

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status)
    {
        case kCLAuthorizationStatusAuthorized:
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        case kCLAuthorizationStatusAuthorizedWhenInUse:
#endif
        {
            [manager startUpdatingLocation];
            break;
        }
        default:
        {
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *latestLocation = locations.lastObject;

    if ([latestLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude]] > 100)
    {
        [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(latestLocation.coordinate.latitude, latestLocation.coordinate.longitude) zoomLevel:17 animated:YES];
    }

    [self.locationManager stopUpdatingLocation];
}

#pragma clang diagnostic pop

@end
