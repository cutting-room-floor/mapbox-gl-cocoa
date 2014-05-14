#import "MVKMapView.h"

#import "../common/foundation_request.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>

#include <llmr/llmr.hpp>

@interface MVKMapView () <UIGestureRecognizerDelegate>

@property (nonatomic) EAGLContext *context;
@property (nonatomic) GLKView *mapView;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat scale;
@property (nonatomic) CGFloat angle;
@property (nonatomic) CGFloat quickZoomStart;

@end

@implementation MVKMapView

class LLMRView;

llmr::Map *llmrMap = nullptr;
LLMRView *llmrView = nullptr;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
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
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        pan.delegate = self;
        [self addGestureRecognizer:pan];

        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
        pinch.delegate = self;
        [self addGestureRecognizer:pinch];

        UIRotationGestureRecognizer *rotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotateGesture:)];
        rotate.delegate = self;
        [self addGestureRecognizer:rotate];

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

        // start it up
        //
        llmrMap->start();
    }

    return self;
}

- (void)dealloc
{
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

- (void)layoutSubviews
{
    if (self.mapView)
    {
        CGRect rect = self.bounds;
        llmrMap->resize(rect.size.width, rect.size.height, self.mapView.contentScaleFactor, self.mapView.drawableWidth, self.mapView.drawableHeight);
    }
}

- (void)cancelPreviousActions
{
    llmrMap->cancelTransitions();
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)pan
{
    [self cancelPreviousActions];

    if (pan.state == UIGestureRecognizerStateBegan)
    {
        self.center = CGPointMake(0, 0);
    }
    else if (pan.state == UIGestureRecognizerStateChanged)
    {
        CGPoint delta = CGPointMake([pan translationInView:pan.view].x - self.center.x,
                                    [pan translationInView:pan.view].y - self.center.y);

        llmrMap->moveBy(delta.x, delta.y);

        self.center = CGPointMake(self.center.x + delta.x, self.center.y + delta.y);
    }
    else if (pan.state == UIGestureRecognizerStateEnded)
    {
        if ([pan velocityInView:pan.view].x < 50 && [pan velocityInView:pan.view].y < 50)
        {
            return;
        }

        CGPoint finalCenter = CGPointMake(self.center.x + (0.1 * [pan velocityInView:pan.view].x),
                                          self.center.y + (0.1 * [pan velocityInView:pan.view].y));

        CGFloat duration = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 0.3 : 0.5);

        llmrMap->moveBy(finalCenter.x - self.center.x, finalCenter.y - self.center.y, duration);
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinch
{
    [self cancelPreviousActions];

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

        llmrMap->scaleBy(powf(2, newZoom) / llmrMap->getScale(), [pinch locationInView:pinch.view].x, [pinch locationInView:pinch.view].y);
    }
    else if (pinch.state == UIGestureRecognizerStateEnded)
    {
        llmrMap->stopScaling();

        if (fabsf(pinch.velocity) < 20)
        {
            return;
        }

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
    [self cancelPreviousActions];

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
    [self cancelPreviousActions];

    if (doubleTap.state == UIGestureRecognizerStateEnded)
    {
        llmrMap->scaleBy(2, [doubleTap locationInView:doubleTap.view].x, [doubleTap locationInView:doubleTap.view].y, 0.3);
    }
}

- (void)handleTwoFingerTapGesture:(UITapGestureRecognizer *)twoFingerTap
{
    [self cancelPreviousActions];

    if (twoFingerTap.state == UIGestureRecognizerStateEnded)
    {
        llmrMap->scaleBy(0.5, [twoFingerTap locationInView:twoFingerTap.view].x, [twoFingerTap locationInView:twoFingerTap.view].y, 0.3);
    }
}

- (void)handleQuickZoomGesture:(UILongPressGestureRecognizer *)quickZoom
{
    [self cancelPreviousActions];

    if (quickZoom.state == UIGestureRecognizerStateBegan)
    {
        self.scale = llmrMap->getScale();

        self.quickZoomStart = [quickZoom locationInView:quickZoom.view].y;
    }
    else if (quickZoom.state == UIGestureRecognizerStateChanged)
    {
        CGFloat distance = self.quickZoomStart - [quickZoom locationInView:quickZoom.view].y;

        CGFloat newZoom = log2f(self.scale) + (distance / 100);

        llmrMap->scaleBy(powf(2, newZoom) / llmrMap->getScale(), self.bounds.size.width / 2, self.bounds.size.height / 2);
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    NSArray *validSimultaneousGestures = @[ [UIPanGestureRecognizer class], [UIPinchGestureRecognizer class], [UIRotationGestureRecognizer class] ];

    return ([validSimultaneousGestures containsObject:[gestureRecognizer class]] && [validSimultaneousGestures containsObject:[otherGestureRecognizer class]]);
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated
{
    double duration = (animated ? 0.3 : 0);

    llmrMap->setLonLat(coordinate.longitude, coordinate.latitude, duration);
}

- (CLLocationCoordinate2D)centerCoordinate
{
    double lon, lat;
    llmrMap->getLonLat(lon, lat);

    return CLLocationCoordinate2DMake(lat, lon);
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

@end
