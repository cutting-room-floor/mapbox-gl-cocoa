#import "MVKMapView.h"

#import "foundation_request.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>

#include <llmr/llmr.hpp>
#include <llmr/platform/platform.hpp>

@interface MVKMapView () <UIGestureRecognizerDelegate>

@property (nonatomic) EAGLContext *context;
@property (nonatomic) GLKView *mapView;
@property (nonatomic) UIImageView *logoBug;
@property (nonatomic) UIImageView *compass;
@property (nonatomic) UIPanGestureRecognizer *pan;
@property (nonatomic) UIPinchGestureRecognizer *pinch;
@property (nonatomic) UIRotationGestureRecognizer *rotate;
@property (nonatomic) CGPoint centerPoint;
@property (nonatomic) CGFloat scale;
@property (nonatomic) CGFloat angle;
@property (nonatomic) CGFloat quickZoomStart;

@end

@implementation MVKMapView

@dynamic debugActive;

class LLMRView;

llmr::Map *llmrMap = nullptr;
LLMRView *llmrView = nullptr;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) return [self commonInit];

    return nil;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];

    if (self) return [self commonInit];

    return nil;
}

- (id)commonInit
{
    // create context
    //
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if ( ! self.context)
    {
        NSLog(@"Failed to create OpenGL ES context");

        return nil;
    }

    // create GL view
    //
    self.mapView = [[GLKView alloc] initWithFrame:self.bounds context:self.context];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.enableSetNeedsDisplay = NO;
    self.mapView.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    self.mapView.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    [self.mapView bindDrawable];
    [self addSubview:self.mapView];

    // setup llmr map
    //
    llmrView = new LLMRView(self);
    llmrMap = new llmr::Map(*llmrView);
    [self setNeedsLayout];

    // setup interaction
    //
    _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    _pan.delegate = self;
    [self addGestureRecognizer:_pan];
    _scrollEnabled = YES;

    _pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    _pinch.delegate = self;
    [self addGestureRecognizer:_pinch];
    _zoomEnabled = YES;

    _rotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotateGesture:)];
    _rotate.delegate = self;
    [self addGestureRecognizer:_rotate];
    _rotateEnabled = YES;

    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];

    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTapGesture:)];
    twoFingerTap.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:twoFingerTap];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        UILongPressGestureRecognizer *quickZoom = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleQuickZoomGesture:)];
        quickZoom.numberOfTapsRequired = 1;
        quickZoom.minimumPressDuration = 0.25;
        [self addGestureRecognizer:quickZoom];
    }

    // observe app activity
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    // start it up
    //
    llmrMap->start();

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (llmrMap)
    {
        delete llmrMap;
        llmrMap = nullptr;
    }

    if (llmrView)
    {
        delete llmrView;
        llmrView = nullptr;
    }

    if ([[EAGLContext currentContext] isEqual:self.context])
    {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];

    [self setNeedsLayout];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    [self setNeedsLayout];
}

- (void)didMoveToSuperview
{
    [self setNeedsUpdateConstraints];
}

- (void)layoutSubviews
{
    if (self.mapView)
    {
        CGRect rect = self.bounds;
        llmrMap->resize(rect.size.width, rect.size.height, self.mapView.contentScaleFactor, self.mapView.drawableWidth, self.mapView.drawableHeight);

        if ( ! self.logoBug)
        {
            self.logoBug = [[UIImageView alloc] initWithImage:[[self class] resourceImageNamed:@"mapbox.png"]];
            self.logoBug.frame = CGRectMake(8, self.bounds.size.height - self.logoBug.bounds.size.height - 4, self.logoBug.bounds.size.width, self.logoBug.bounds.size.height);
            self.logoBug.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
            [self addSubview:self.logoBug];

            [self setNeedsUpdateConstraints];
        }

        if ( ! self.compass)
        {
            UIImage *compassImage = [[self class] resourceImageNamed:@"Compass"];
            UIView *compassContainer = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width - compassImage.size.width - 5, 5, compassImage.size.width, compassImage.size.height)];
            compassContainer.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:compassContainer];

            self.compass = [[UIImageView alloc] initWithImage:compassImage];
            self.compass.userInteractionEnabled = YES;
            [self.compass addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCompassTapGesture:)]];
            self.compass.alpha = 0;
            [compassContainer addSubview:self.compass];

            [self setNeedsUpdateConstraints];
        }
    }

    [super layoutSubviews];
}

- (void)updateConstraints
{
    UIView *container = self.compass.superview;

    if (container)
    {
        UIViewController *viewController = nil;
        UIResponder *responder = self;
        while ((responder = [responder nextResponder]))
        {
            if ([responder isKindOfClass:[UIViewController class]])
            {
                viewController = (UIViewController *)responder;
                break;
            }
        }

        if (viewController)
        {
            while (viewController.parentViewController)
            {
                viewController = viewController.parentViewController;
            }

            [container removeConstraints:container.constraints];

            CGFloat topSpacing   = container.frame.origin.y;
            CGFloat rightSpacing = container.superview.bounds.size.width - container.frame.origin.x;

            [viewController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-topSpacing-[container]"
                                                                                        options:0
                                                                                        metrics:@{ @"topSpacing"     : @(topSpacing) }
                                                                                          views:@{ @"topLayoutGuide" : viewController.topLayoutGuide,
                                                                                                   @"container"      : container }]];

            [viewController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[container]-rightSpacing-|"
                                                                                        options:0
                                                                                        metrics:@{ @"rightSpacing" : @(rightSpacing) }
                                                                                          views:@{ @"container"    : container }]];
        }
    }

    [super updateConstraints];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

- (void)appDidBackground:(NSNotification *)notification
{
    llmrMap->cleanup();
    [self.mapView deleteDrawable];
}

- (void)appWillForeground:(NSNotification *)notification
{
    [self.mapView bindDrawable];
}

#pragma clang diagnostic pop

- (BOOL)cancelPreviousActions
{
    if (llmrMap->getState().isInteractive())
    {
        llmrMap->cancelTransitions();

        return YES;
    }

    return NO;
}

- (void)handleCompassTapGesture:(UITapGestureRecognizer *)compassTap
{
    if (compassTap.state == UIGestureRecognizerStateEnded) [self resetNorth];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)pan
{
    if ( ! self.isScrollEnabled) return;

    if ( ! [self cancelPreviousActions]) return;

    if (pan.state == UIGestureRecognizerStateBegan)
    {
        self.centerPoint = CGPointMake(0, 0);
    }
    else if (pan.state == UIGestureRecognizerStateChanged)
    {
        CGPoint delta = CGPointMake([pan translationInView:pan.view].x - self.centerPoint.x,
                                    [pan translationInView:pan.view].y - self.centerPoint.y);

        llmrMap->moveBy(delta.x, delta.y);

        self.centerPoint = CGPointMake(self.centerPoint.x + delta.x, self.centerPoint.y + delta.y);
    }
    else if (pan.state == UIGestureRecognizerStateEnded)
    {
        if ([pan velocityInView:pan.view].x < 50 && [pan velocityInView:pan.view].y < 50) return;

        CGPoint finalCenter = CGPointMake(self.centerPoint.x + (0.1 * [pan velocityInView:pan.view].x),
                                          self.centerPoint.y + (0.1 * [pan velocityInView:pan.view].y));

        CGFloat duration = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 0.3 : 0.5);

        llmrMap->moveBy(finalCenter.x - self.centerPoint.x, finalCenter.y - self.centerPoint.y, duration);
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinch
{
    if ( ! self.isZoomEnabled) return;

    if ( ! [self cancelPreviousActions]) return;

    if (pinch.state == UIGestureRecognizerStateBegan)
    {
        llmrMap->startScaling();

        self.scale = llmrMap->getScale();
    }
    else if (pinch.state == UIGestureRecognizerStateChanged)
    {
        CGFloat tolerance  = 2.5;
        CGFloat adjustment = 0;

        if (pinch.scale > 1)
        {
            adjustment = (pinch.scale / tolerance) - (1 / tolerance);
        }
        else
        {
            adjustment = (-1 / pinch.scale) / tolerance + (1 / tolerance);
        }

        CGFloat newZoom = log2f(self.scale) + adjustment;

        if (newZoom < llmrMap->getMinZoom()) return;

        llmrMap->scaleBy(powf(2, newZoom) / llmrMap->getScale(), [pinch locationInView:pinch.view].x, [pinch locationInView:pinch.view].y);
    }
    else if (pinch.state == UIGestureRecognizerStateEnded)
    {
        llmrMap->stopScaling();

        if (fabsf(pinch.velocity) < 20) return;

        CGFloat finalZoom = log2f(llmrMap->getScale()) + (0.01 * pinch.velocity);

        double scale = llmrMap->getScale();
        double new_scale = powf(2, finalZoom);

        CGFloat duration = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 0.3 : 0.5);

        llmrMap->scaleBy(new_scale / scale, [pinch locationInView:pinch.view].x, [pinch locationInView:pinch.view].y, duration);
    }
    else if (pinch.state == UIGestureRecognizerStateCancelled)
    {
        llmrMap->stopScaling();
    }
}

- (void)handleRotateGesture:(UIRotationGestureRecognizer *)rotate
{
    if ( ! self.isRotateEnabled) return;

    if ( ! [self cancelPreviousActions]) return;

    if ( ! llmrMap->canRotate()) return;

    if (rotate.state == UIGestureRecognizerStateBegan)
    {
        llmrMap->startRotating();

        self.angle = llmrMap->getAngle();
    }
    else if (rotate.state == UIGestureRecognizerStateChanged)
    {
        llmrMap->setAngle(self.angle + rotate.rotation, [rotate locationInView:rotate.view].x, [rotate locationInView:rotate.view].y);
    }
    else if (rotate.state == UIGestureRecognizerStateEnded || rotate.state == UIGestureRecognizerStateCancelled)
    {
        llmrMap->stopRotating();
    }
}

- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)doubleTap
{
    if ( ! self.isZoomEnabled) return;

    if ( ! [self cancelPreviousActions]) return;

    if (doubleTap.state == UIGestureRecognizerStateEnded)
    {
        llmrMap->scaleBy(2, [doubleTap locationInView:doubleTap.view].x, [doubleTap locationInView:doubleTap.view].y, 0.3);
    }
}

- (void)handleTwoFingerTapGesture:(UITapGestureRecognizer *)twoFingerTap
{
    if ( ! self.isZoomEnabled) return;

    if ( ! [self cancelPreviousActions]) return;

    if (llmrMap->getZoom() == llmrMap->getMinZoom()) return;

    if (twoFingerTap.state == UIGestureRecognizerStateEnded)
    {
        llmrMap->scaleBy(0.5, [twoFingerTap locationInView:twoFingerTap.view].x, [twoFingerTap locationInView:twoFingerTap.view].y, 0.3);
    }
}

- (void)handleQuickZoomGesture:(UILongPressGestureRecognizer *)quickZoom
{
    if ( ! self.isZoomEnabled) return;

    if ( ! [self cancelPreviousActions]) return;

    if (quickZoom.state == UIGestureRecognizerStateBegan)
    {
        self.scale = llmrMap->getScale();

        self.quickZoomStart = [quickZoom locationInView:quickZoom.view].y;
    }
    else if (quickZoom.state == UIGestureRecognizerStateChanged)
    {
        CGFloat distance = self.quickZoomStart - [quickZoom locationInView:quickZoom.view].y;

        CGFloat newZoom = log2f(self.scale) + (distance / 100);

        if (newZoom < llmrMap->getMinZoom()) return;

        llmrMap->scaleBy(powf(2, newZoom) / llmrMap->getScale(), self.bounds.size.width / 2, self.bounds.size.height / 2);
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    NSArray *validSimultaneousGestures = @[ self.pan, self.pinch, self.rotate ];

    return ([validSimultaneousGestures containsObject:gestureRecognizer] && [validSimultaneousGestures containsObject:otherGestureRecognizer]);
}

- (void)setDebugActive:(BOOL)debugActive
{
    llmrMap->setDebug(debugActive);
}

- (BOOL)isDebugActive
{
    return llmrMap->getDebug();
}

- (void)resetNorth
{
    llmrMap->resetNorth();

    [UIView animateWithDuration:0.5 animations:^(void) { self.compass.transform = CGAffineTransformIdentity; }];
}

- (void)resetPosition
{
    llmrMap->resetPosition();
}

- (void)toggleDebug
{
    llmrMap->toggleDebug();
}

- (void)toggleRaster
{
    llmrMap->toggleRaster();
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated
{
    double duration = (animated ? 0.3 : 0);

    llmrMap->setLonLat(coordinate.longitude, coordinate.latitude, duration);
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
{
    [self setCenterCoordinate:centerCoordinate animated:NO];
}

- (CLLocationCoordinate2D)centerCoordinate
{
    double lon, lat;
    llmrMap->getLonLat(lon, lat);

    return CLLocationCoordinate2DMake(lat, lon);
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(double)zoomLevel animated:(BOOL)animated
{
    double duration = (animated ? 0.3 : 0);

    llmrMap->setLonLatZoom(centerCoordinate.longitude, centerCoordinate.latitude, zoomLevel, duration);
}

- (double)zoomLevel
{
    return llmrMap->getZoom();
}

- (void)setZoomLevel:(double)zoomLevel animated:(BOOL)animated
{
    double duration = (animated ? 0.3 : 0);

    llmrMap->setZoom(zoomLevel, duration);
}

- (void)setZoomLevel:(double)zoomLevel
{
    [self setZoomLevel:zoomLevel animated:NO];
}

- (CLLocationDirection)direction
{
    double direction = llmrMap->getAngle();

    while (direction > 360) direction -= 360;
    while (direction < 0) direction += 360;

    return direction;
}

- (void)setDirection:(CLLocationDirection)direction animated:(BOOL)animated
{
    double duration = (animated ? 0.3 : 0);

    llmrMap->setAngle(direction, duration);
}

- (void)setDirection:(CLLocationDirection)direction
{
    [self setDirection:direction animated:NO];
}

- (void)notifyMapChange
{
    double lon, lat, zoom;
    llmrMap->getLonLatZoom(lon, lat, zoom);
    while (lon > 180) lon -= 360;
    while (lon <= -180) lon += 360;

    double angle = llmrMap->getAngle();
    angle *= 180 / M_PI;
    while (angle >= 360) angle -= 360;
    while (angle < 0) angle += 360;

//    NSLog(@"lat: %f, lon: %f, zoom: %f, angle: %f", lat, lon, zoom, angle);

    self.compass.transform = CGAffineTransformMakeRotation(llmrMap->getAngle());

    if (llmrMap->getAngle() && self.compass.alpha < 1)   [UIView animateWithDuration:0.5 animations:^(void) { self.compass.alpha = 1; }];
    else if ( ! llmrMap->getAngle() && self.compass.alpha > 0) [UIView animateWithDuration:0.5 animations:^(void) { self.compass.alpha = 0; }];
}

+ (UIImage *)resourceImageNamed:(NSString *)imageName
{
    if ( ! [[imageName pathExtension] length])
        imageName = [imageName stringByAppendingString:@".png"];

    return [UIImage imageWithContentsOfFile:[[self class] pathForBundleResourceNamed:imageName ofType:nil]];
}

+ (NSString *)pathForBundleResourceNamed:(NSString *)name ofType:(NSString *)extension
{
    NSAssert([[NSBundle mainBundle] pathForResource:@"MVKMapKit" ofType:@"bundle"], @"Resource bundle not found in application.");

    NSString *bundlePath      = [[NSBundle mainBundle] pathForResource:@"MVKMapKit" ofType:@"bundle"];
    NSBundle *resourcesBundle = [NSBundle bundleWithPath:bundlePath];

    return [resourcesBundle pathForResource:name ofType:extension];
}

- (void)swap
{
    if (llmrMap->needsSwap())
    {
        [self.mapView display];
        llmrMap->swapped();
    }
}

class LLMRView : public llmr::View
{
    public:
        LLMRView(MVKMapView *nativeView) : nativeView(nativeView) {}
        virtual ~LLMRView() {}

    void notify_map_change()
    {
        // This drives the map view delegate callbacks, which need to happen
        // in the next run loop pass to avoid lock contention when obtaining
        // lat/lon/zoom. Delegate callbacks are after-the-fact and don't need
        // to be synchronous anyway.
        //
        [nativeView performSelector:@selector(notifyMapChange) withObject:nil afterDelay:0];
    }

    void make_active()
    {
        [EAGLContext setCurrentContext:nativeView.context];
    }

    void swap()
    {
        [nativeView performSelectorOnMainThread:@selector(swap) withObject:nil waitUntilDone:NO];
    }

    private:
        MVKMapView *nativeView = nullptr;
};

void llmr::platform::notify_map_change()
{
    // Notify the map view wrapper, which has access to the native view object.
    //
    llmrView->notify_map_change();
}

@end
