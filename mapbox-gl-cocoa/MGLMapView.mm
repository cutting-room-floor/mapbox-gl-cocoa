#import "MGLMapView.h"

#import "foundation_request.h"
#import "nslog_log.hpp"

#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>

#include <llmr/llmr.hpp>
#include <llmr/platform/platform.hpp>

#import "MGLTypes.h"
#import "MGLStyleFunctionValue.h"

#import "UIColor+MGLAdditions.h"
#import "NSArray+MGLAdditions.h"
#import "NSDictionary+MGLAdditions.h"

extern NSString *const MGLStyleKeyGeneric;
extern NSString *const MGLStyleKeyFill;
extern NSString *const MGLStyleKeyLine;
extern NSString *const MGLStyleKeyIcon;
extern NSString *const MGLStyleKeyText;
extern NSString *const MGLStyleKeyRaster;
extern NSString *const MGLStyleKeyComposite;
extern NSString *const MGLStyleKeyBackground;

extern NSString *const MGLStyleValueFunctionAllowed;

@interface MGLMapView () <UIGestureRecognizerDelegate, GLKViewDelegate>

@property (nonatomic) EAGLContext *context;
@property (nonatomic) GLKView *glView;
@property (nonatomic) NSOperationQueue *regionChangeDelegateQueue;
@property (nonatomic) UIImageView *compass;
@property (nonatomic) UIImageView *logoBug;
@property (nonatomic) UIButton *attributionButton;
@property (nonatomic) UIPanGestureRecognizer *pan;
@property (nonatomic) UIPinchGestureRecognizer *pinch;
@property (nonatomic) UIRotationGestureRecognizer *rotate;
@property (nonatomic) UILongPressGestureRecognizer *quickZoom;
@property (nonatomic, readonly) NSDictionary *allowedStyleTypes;
@property (nonatomic) CGPoint centerPoint;
@property (nonatomic) CGFloat scale;
@property (nonatomic) CGFloat angle;
@property (nonatomic) CGFloat quickZoomStart;
@property (nonatomic, getter=isAnimatingGesture) BOOL animatingGesture;

@end

@interface MGLStyleFunctionValue (MGLMapViewFriend)

@property (nonatomic) NSString *functionType;
@property (nonatomic) NSDictionary *stops;
@property (nonatomic) CGFloat zBase;
@property (nonatomic) CGFloat val;
@property (nonatomic) CGFloat slope;
@property (nonatomic) CGFloat min;
@property (nonatomic) CGFloat max;
@property (nonatomic) CGFloat minimumZoom;
@property (nonatomic) CGFloat maximumZoom;

- (id)rawStyle;

@end

@implementation MGLMapView

@dynamic debugActive;

class LLMRView;

llmr::Map *llmrMap = nullptr;
LLMRView *llmrView = nullptr;

- (instancetype)initWithFrame:(CGRect)frame styleJSON:(NSString *)styleJSON accessToken:(NSString *)accessToken
{
    self = [super initWithFrame:frame];

    if (self && [self commonInit])
    {
        if (accessToken) [self setAccessToken:accessToken];

        if (styleJSON || accessToken)
        {
            // If style is set directly, pass it on. If not, if we have an access
            // token, we can pass nil and use the default style.
            //
            [self setStyleJSON:styleJSON];
        }
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame accessToken:(NSString *)accessToken
{
    return [self initWithFrame:frame styleJSON:nil accessToken:accessToken];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];

    if (self && [self commonInit])
    {
        return self;
    }

    return nil;
}

- (void)setAccessToken:(NSString *)accessToken
{
    if (accessToken)
    {
        llmrMap->setAccessToken((std::string)[accessToken cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (void)setStyleJSON:(NSString *)styleJSON
{
    if ( ! styleJSON)
    {
        if ( ! [@(llmrMap->getAccessToken().c_str()) length])
        {
            [NSException raise:@"invalid access token"
                        format:@"default map style requires a Mapbox API access token"];
        }

        NSString *path = [MGLMapView pathForBundleResourceNamed:@"style.min" ofType:@"js"];

        styleJSON = [NSString stringWithContentsOfFile:path encoding:[NSString defaultCStringEncoding] error:nil];
    }

    llmrMap->stop();
    llmrMap->setStyleJSON((std::string)[styleJSON cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    llmrMap->start();
}

- (BOOL)commonInit
{
    // set logging backend
    //
    llmr::Log::Set<llmr::NSLogBackend>();

    // create context
    //
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if ( ! _context)
    {
        llmr::Log::Error(llmr::Event::Setup, "Failed to create OpenGL ES context");

        return NO;
    }

    // setup accessibility
    //
    self.accessibilityLabel = @"Map";

    // create GL view
    //
    _glView = [[GLKView alloc] initWithFrame:self.bounds context:_context];
    _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _glView.enableSetNeedsDisplay = NO;
    _glView.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    _glView.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    _glView.delegate = self;
    [_glView bindDrawable];
    [self addSubview:_glView];

    // setup llmr map
    //
    llmrView = new LLMRView(self);
    llmrMap = new llmr::Map(*llmrView);
    llmrMap->resize(self.bounds.size.width, self.bounds.size.height, _glView.contentScaleFactor, _glView.drawableWidth, _glView.drawableHeight);

    // setup logo bug
    //
    _logoBug = [[UIImageView alloc] initWithImage:[MGLMapView resourceImageNamed:@"mapbox.png"]];
    _logoBug.accessibilityLabel = @"Mapbox logo";
    _logoBug.frame = CGRectMake(8, self.bounds.size.height - _logoBug.bounds.size.height - 4, _logoBug.bounds.size.width, _logoBug.bounds.size.height);
    _logoBug.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_logoBug];

    // setup attribution
    //
    _attributionButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    _attributionButton.accessibilityLabel = @"Attribution info";
    [_attributionButton addTarget:self action:@selector(showAttribution:) forControlEvents:UIControlEventTouchUpInside];
    _attributionButton.frame = CGRectMake(self.bounds.size.width - _attributionButton.bounds.size.width - 8, self.bounds.size.height - _attributionButton.bounds.size.height - 8, _attributionButton.bounds.size.width, _attributionButton.bounds.size.height);
    _attributionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_attributionButton];

    // setup compass
    //
    _compass = [[UIImageView alloc] initWithImage:[MGLMapView resourceImageNamed:@"Compass.png"]];
    _compass.accessibilityLabel = @"Compass";
    UIImage *compassImage = [MGLMapView resourceImageNamed:@"Compass.png"];
    _compass.frame = CGRectMake(0, 0, compassImage.size.width, compassImage.size.height);
    _compass.alpha = 0;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width - compassImage.size.width - 5, 5, compassImage.size.width, compassImage.size.height)];
    [container addSubview:_compass];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    [container addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCompassTapGesture:)]];
    [self addSubview:container];

    self.viewControllerForLayoutGuides = nil;

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
        _quickZoom = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleQuickZoomGesture:)];
        _quickZoom.numberOfTapsRequired = 1;
        _quickZoom.minimumPressDuration = 0.25;
        [self addGestureRecognizer:_quickZoom];
    }

    // observe app activity
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    // set initial position
    //
    llmrMap->setLonLatZoom(0, 0, llmrMap->getMinZoom());

    // setup change delegate queue
    //
    _regionChangeDelegateQueue = [NSOperationQueue new];
    _regionChangeDelegateQueue.maxConcurrentOperationCount = 1;

    return YES;
}

- (void)dealloc
{
    [_regionChangeDelegateQueue cancelAllOperations];

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

    if ([[EAGLContext currentContext] isEqual:_context])
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

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (void)didMoveToSuperview
{
    [self.compass.superview removeConstraints:self.compass.superview.constraints];
    [self.logoBug removeConstraints:self.logoBug.constraints];
    [self.attributionButton removeConstraints:self.attributionButton.constraints];

    [self setNeedsUpdateConstraints];
}

- (void)setViewControllerForLayoutGuides:(UIViewController *)viewController
{
    _viewControllerForLayoutGuides = viewController;

    [self.compass.superview removeConstraints:self.compass.superview.constraints];
    [self.logoBug removeConstraints:self.logoBug.constraints];
    [self.attributionButton removeConstraints:self.attributionButton.constraints];

    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints
{
    // If we have a view controller reference, use its layout guides for our various top & bottom
    // views so they don't underlap navigation or tool bars. If we don't have a reference, apply
    // constraints against ourself to maintain (albeit less ideal) placement of the subviews.
    //
    NSString *topGuideFormatString    = (self.viewControllerForLayoutGuides ? @"[topLayoutGuide]"    : @"|");
    NSString *bottomGuideFormatString = (self.viewControllerForLayoutGuides ? @"[bottomLayoutGuide]" : @"|");

    id topGuideViewsObject            = (self.viewControllerForLayoutGuides ? (id)self.viewControllerForLayoutGuides.topLayoutGuide    : (id)@"");
    id bottomGuideViewsObject         = (self.viewControllerForLayoutGuides ? (id)self.viewControllerForLayoutGuides.bottomLayoutGuide : (id)@"");

    UIView *constraintParentView = (self.viewControllerForLayoutGuides.view ? self.viewControllerForLayoutGuides.view : self);

    // compass
    //
    UIView *compassContainer = self.compass.superview;

    [constraintParentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:%@-topSpacing-[container]", topGuideFormatString]
                                                                                 options:0
                                                                                 metrics:@{ @"topSpacing"     : @(5) }
                                                                                   views:@{ @"topLayoutGuide" : topGuideViewsObject,
                                                                                            @"container"      : compassContainer }]];

    [constraintParentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[container]-rightSpacing-|"
                                                                                 options:0
                                                                                 metrics:@{ @"rightSpacing" : @(5) }
                                                                                   views:@{ @"container"    : compassContainer }]];

    [compassContainer addConstraint:[NSLayoutConstraint constraintWithItem:compassContainer
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1
                                                                  constant:self.compass.image.size.width]];

    [compassContainer addConstraint:[NSLayoutConstraint constraintWithItem:compassContainer
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1
                                                                  constant:self.compass.image.size.height]];

    // logo bug
    //
    [constraintParentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[logoBug]-bottomSpacing-%@", bottomGuideFormatString]
                                                                                 options:0
                                                                                 metrics:@{ @"bottomSpacing"     : @(4) }
                                                                                   views:@{ @"logoBug"           : self.logoBug,
                                                                                            @"bottomLayoutGuide" : bottomGuideViewsObject }]];

    [constraintParentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leftSpacing-[logoBug]"
                                                                                 options:0
                                                                                 metrics:@{ @"leftSpacing"       : @(8) }
                                                                                   views:@{ @"logoBug"           : self.logoBug }]];

    // attribution button
    //
    [constraintParentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[attributionButton]-bottomSpacing-%@", bottomGuideFormatString]
                                                                                 options:0
                                                                                 metrics:@{ @"bottomSpacing"     : @(8) }
                                                                                   views:@{ @"attributionButton" : self.attributionButton,
                                                                                            @"bottomLayoutGuide" : bottomGuideViewsObject }]];

    [constraintParentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[attributionButton]-rightSpacing-|"
                                                                                 options:0
                                                                                 metrics:@{ @"rightSpacing"      : @(8) }
                                                                                   views:@{ @"attributionButton" : self.attributionButton }]];

    [super updateConstraints];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    llmrMap->resize(rect.size.width, rect.size.height, view.contentScaleFactor, view.drawableWidth, view.drawableHeight);
}

- (void)layoutSubviews
{
    llmrMap->update();

    [super layoutSubviews];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

- (void)appDidBackground:(NSNotification *)notification
{
    llmrMap->stop();

    [self.glView deleteDrawable];
}

- (void)appWillForeground:(NSNotification *)notification
{
    [self.glView bindDrawable];

    llmrMap->start();
}

- (void)handleCompassTapGesture:(id)sender
{
    [self resetNorth];
}

#pragma clang diagnostic pop

- (void)handlePanGesture:(UIPanGestureRecognizer *)pan
{
    if ( ! self.isScrollEnabled) return;

    llmrMap->cancelTransitions();

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
    else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled)
    {
        CGPoint velocity = [pan velocityInView:pan.view];
        CGFloat duration = 0;

        if ( ! CGPointEqualToPoint(velocity, CGPointZero))
        {
            CGFloat ease = 0.25;

            velocity.x = velocity.x * ease;
            velocity.y = velocity.y * ease;

            CGFloat speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
            CGFloat deceleration = 2500;
            duration = speed / (deceleration * ease);
        }

        CGPoint offset = CGPointMake(velocity.x * duration / 2, velocity.y * duration / 2);

        llmrMap->moveBy(offset.x, offset.y, duration);

        if (duration)
        {
            self.animatingGesture = YES;

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void)
            {
                self.animatingGesture = NO;

                [self notifyMapChange:@(llmr::platform::MapChangeRegionDidChangeAnimated)];
            });
        }
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinch
{
    if ( ! self.isZoomEnabled) return;

    if (llmrMap->getZoom() <= llmrMap->getMinZoom() && pinch.scale < 1) return;

    llmrMap->cancelTransitions();

    if (pinch.state == UIGestureRecognizerStateBegan)
    {
        llmrMap->startScaling();

        self.scale = llmrMap->getScale();
    }
    else if (pinch.state == UIGestureRecognizerStateChanged)
    {
        CGFloat newScale = self.scale * pinch.scale;

        if (log2(newScale) < llmrMap->getMinZoom()) return;

        double scale = llmrMap->getScale();

        llmrMap->scaleBy(newScale / scale, [pinch locationInView:pinch.view].x, [pinch locationInView:pinch.view].y);
    }
    else if (pinch.state == UIGestureRecognizerStateEnded || pinch.state == UIGestureRecognizerStateCancelled)
    {
        llmrMap->stopScaling();

        [self notifyMapChange:@(llmr::platform::MapChangeRegionDidChangeAnimated)];
    }
}

- (void)handleRotateGesture:(UIRotationGestureRecognizer *)rotate
{
    if ( ! self.isRotateEnabled) return;

    if ( ! llmrMap->canRotate()) return;

    llmrMap->cancelTransitions();

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

        [self notifyMapChange:@(llmr::platform::MapChangeRegionDidChangeAnimated)];
    }
}

- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)doubleTap
{
    if ( ! self.isZoomEnabled) return;

    llmrMap->cancelTransitions();

    if (doubleTap.state == UIGestureRecognizerStateEnded)
    {
        CGFloat duration = 0.3;

        llmrMap->scaleBy(2, [doubleTap locationInView:doubleTap.view].x, [doubleTap locationInView:doubleTap.view].y, duration);

        self.animatingGesture = YES;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void)
        {
            self.animatingGesture = NO;

            [self notifyMapChange:@(llmr::platform::MapChangeRegionDidChangeAnimated)];
        });
    }
}

- (void)handleTwoFingerTapGesture:(UITapGestureRecognizer *)twoFingerTap
{
    if ( ! self.isZoomEnabled) return;

    if (llmrMap->getZoom() == llmrMap->getMinZoom()) return;

    llmrMap->cancelTransitions();

    if (twoFingerTap.state == UIGestureRecognizerStateEnded)
    {
        CGFloat duration = 0.3;

        llmrMap->scaleBy(0.5, [twoFingerTap locationInView:twoFingerTap.view].x, [twoFingerTap locationInView:twoFingerTap.view].y, duration);

        self.animatingGesture = YES;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void)
        {
            self.animatingGesture = NO;

            [self notifyMapChange:@(llmr::platform::MapChangeRegionDidChangeAnimated)];
        });
    }
}

- (void)handleQuickZoomGesture:(UILongPressGestureRecognizer *)quickZoom
{
    if ( ! self.isZoomEnabled) return;

    llmrMap->cancelTransitions();

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
    else if (quickZoom.state == UIGestureRecognizerStateEnded || quickZoom.state == UIGestureRecognizerStateCancelled)
    {
        [self notifyMapChange:@(llmr::platform::MapChangeRegionDidChangeAnimated)];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    NSArray *validSimultaneousGestures = @[ self.pan, self.pinch, self.rotate ];

    return ([validSimultaneousGestures containsObject:gestureRecognizer] && [validSimultaneousGestures containsObject:otherGestureRecognizer]);
}

- (void)tintColorDidChange
{
    for (UIView *subview in self.subviews)
    {
        if ([subview respondsToSelector:@selector(setTintColor:)])
        {
            subview.tintColor = self.tintColor;
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

- (void)showAttribution:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.mapbox.com/about/maps/"]];
}

#pragma clang diagnostic pop

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

    [UIView animateWithDuration:0.25
                     animations:^(void)
                     {
                         self.compass.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL finished)
                     {
                         if (finished)
                         {
                             [UIView animateWithDuration:0.25
                                              animations:^(void)
                                              {
                                                  self.compass.alpha = 0;
                                              }];
                         }
                     }];
}

- (void)resetPosition
{
    llmrMap->resetPosition();
}

- (void)toggleDebug
{
    llmrMap->toggleDebug();
}

- (void)toggleStyle
{
    llmrMap->setDefaultTransitionDuration(300);
    llmrMap->toggleClass("night");
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

    direction *= 180 / M_PI;

    while (direction > 360) direction -= 360;
    while (direction < 0) direction += 360;

    return direction;
}

- (void)setDirection:(CLLocationDirection)direction animated:(BOOL)animated
{
    double duration = (animated ? 0.3 : 0);

    direction *= M_PI / 180;

    llmrMap->setAngle(direction, duration);
}

- (void)setDirection:(CLLocationDirection)direction
{
    [self setDirection:direction animated:NO];
}

- (NSDictionary *)getRawStyle
{
    const std::string styleJSON = llmrMap->getStyleJSON();

    return [NSJSONSerialization JSONObjectWithData:[@(styleJSON.c_str()) dataUsingEncoding:[NSString defaultCStringEncoding]] options:0 error:nil];
}

- (void)setRawStyle:(NSDictionary *)style
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:style options:0 error:nil];

    llmrMap->setStyleJSON([[[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

- (NSArray *)getStyleOrderedLayerNames
{
    return [[self getRawStyle] valueForKeyPath:@"layers.id"];
}

- (void)setStyleOrderedLayerNames:(NSArray *)orderedLayerNames
{
    NSMutableDictionary *style = [[self getRawStyle] deepMutableCopy];
    NSArray *oldLayers = style[@"layers"];
    NSMutableArray *newLayers = [NSMutableArray array];

    if ([orderedLayerNames count] != [[oldLayers valueForKeyPath:@"id"] count])
    {
        [NSException raise:@"invalid layer count"
                    format:@"new layer count (%lu) should equal existing layer count (%lu)",
                        (unsigned long)[orderedLayerNames count],
                        (unsigned long)[[oldLayers valueForKeyPath:@"id"] count]];
    }
    else
    {
        for (NSString *newLayerName in orderedLayerNames)
        {
            if ( ! [[oldLayers valueForKeyPath:@"id"] containsObject:newLayerName])
            {
                [NSException raise:@"invalid layer name"
                            format:@"layer name %@ unknown",
                                newLayerName];
            }
            else
            {
                NSDictionary *newLayer = [oldLayers objectAtIndex:[[oldLayers valueForKeyPath:@"id"] indexOfObject:newLayerName]];
                [newLayers addObject:newLayer];
            }
        }
    }

    [style setValue:newLayers forKey:@"layers"];

    [self setRawStyle:style];
}

- (NSArray *)getAppliedStyleClasses
{
    NSMutableArray *returnArray = [NSMutableArray array];

    const std::vector<std::string> &appliedClasses = llmrMap->getAppliedClasses();

    for (auto class_it = appliedClasses.begin(); class_it != appliedClasses.end(); class_it++)
    {
        [returnArray addObject:@(class_it->c_str())];
    }

    return returnArray;
}

- (void)setAppliedStyleClasses:(NSArray *)appliedClasses
{
    [self setAppliedStyleClasses:appliedClasses transitionDuration:0];
}

- (void)setAppliedStyleClasses:(NSArray *)appliedClasses transitionDuration:(NSTimeInterval)transitionDuration
{
    std::vector<std::string> newAppliedClasses;

    for (NSString *appliedClass in appliedClasses)
    {
        newAppliedClasses.insert(newAppliedClasses.end(), [appliedClass cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }

    llmrMap->setDefaultTransitionDuration(transitionDuration);
    llmrMap->setAppliedClasses(newAppliedClasses);
}

- (NSString *)getKeyTypeForLayer:(NSString *)layerName
{
    NSDictionary *style = [self getRawStyle];

    NSString *bucketType;

    if ([layerName isEqualToString:@"background"])
    {
        bucketType = @"background";
    }
    else
    {
        for (NSDictionary *layer in style[@"structure"])
        {
            if ([layer[@"name"] isEqualToString:layerName])
            {
                bucketType = style[@"buckets"][layer[@"bucket"]][@"type"];
                break;
            }
        }
    }

    NSString *keyType;

    if ([bucketType isEqualToString:@"fill"])
    {
        keyType = MGLStyleKeyFill;
    }
    else if ([bucketType isEqualToString:@"line"])
    {
        keyType = MGLStyleKeyLine;
    }
    else if ([bucketType isEqualToString:@"point"])
    {
        keyType = MGLStyleKeyIcon;
    }
    else if ([bucketType isEqualToString:@"text"])
    {
        keyType = MGLStyleKeyText;
    }
    else if ([bucketType isEqualToString:@"raster"])
    {
        keyType = MGLStyleKeyRaster;
    }
    else if ([bucketType isEqualToString:@"composite"])
    {
        keyType = MGLStyleKeyComposite;
    }
    else if ([bucketType isEqualToString:@"background"])
    {
        keyType = MGLStyleKeyBackground;
    }
    else
    {
        [NSException raise:@"invalid bucket type"
                    format:@"bucket type %@ unknown",
                        bucketType];
    }

    return keyType;
}

- (NSDictionary *)getStyleDescriptionForLayer:(NSString *)layerName inClass:(NSString *)className
{
    NSDictionary *style = [self getRawStyle];

    if ( ! [[style valueForKeyPath:@"classes.name"] containsObject:className])
    {
        [NSException raise:@"invalid class name"
                    format:@"class name %@ unknown",
                        className];
    }

    NSUInteger classNumber = [[style valueForKeyPath:@"classes.name"] indexOfObject:className];

    if ( ! [[style[@"classes"][classNumber][@"layers"] allKeys] containsObject:layerName])
    {
        // layer specified in structure, but not styled
        //
        return nil;
    }

    NSDictionary *layerStyle = style[@"classes"][classNumber][@"layers"][layerName];

    NSMutableDictionary *styleDescription = [NSMutableDictionary dictionary];

    for (NSString *keyName in [layerStyle allKeys])
    {
        id value = layerStyle[keyName];

        while ([[style[@"constants"] allKeys] containsObject:value])
        {
            value = style[@"constants"][value];
        }

        if ([[self.allowedStyleTypes[MGLStyleKeyGeneric] allKeys] containsObject:keyName])
        {
            [styleDescription setValue:[self typedPropertyForKeyName:keyName
                                                              ofType:MGLStyleKeyGeneric
                                                           withValue:value]
                                forKey:keyName];
        }

        NSString *keyType = [self getKeyTypeForLayer:layerName];

        if ([[self.allowedStyleTypes[keyType] allKeys] containsObject:keyName])
        {
            [styleDescription setValue:[self typedPropertyForKeyName:keyName
                                                              ofType:keyType
                                                           withValue:value]
                                forKey:keyName];
        }
    }

    return styleDescription;
}

- (NSDictionary *)typedPropertyForKeyName:(NSString *)keyName ofType:(NSString *)keyType withValue:(id)value
{
    if ( ! [[self.allowedStyleTypes[keyType] allKeys] containsObject:keyName])
    {
        [NSException raise:@"invalid property name"
                    format:@"property name %@ unknown",
                        keyName];
    }

    NSArray *typeInfo = self.allowedStyleTypes[keyType][keyName];

    if ([value isKindOfClass:[NSArray class]] && ! [typeInfo containsObject:MGLStyleValueTypeColor])
    {
        if ([typeInfo containsObject:MGLStyleValueFunctionAllowed])
        {
            if ([[(NSArray *)value firstObject] isKindOfClass:[NSString class]])
            {
                NSString *functionType;

                if ([[(NSArray *)value firstObject] isEqualToString:@"linear"])
                {
                    functionType = MGLStyleValueTypeFunctionLinear;
                }
                else if ([[(NSArray *)value firstObject] isEqualToString:@"stops"])
                {
                    functionType = MGLStyleValueTypeFunctionStops;
                }
                else if ([[(NSArray *)value firstObject] isEqualToString:@"exponential"])
                {
                    functionType = MGLStyleValueTypeFunctionExponential;
                }
                else if ([[(NSArray *)value firstObject] isEqualToString:@"min"])
                {
                    functionType = MGLStyleValueTypeFunctionMinimumZoom;
                }
                else if ([[(NSArray *)value firstObject] isEqualToString:@"max"])
                {
                    functionType = MGLStyleValueTypeFunctionMaximumZoom;
                }

                if (functionType)
                {
                    return @{ @"type"  : functionType,
                              @"value" : value };
                }
            }
        }
        else if ([typeInfo containsObject:MGLStyleValueTypeNumberPair])
        {
            return @{ @"type"  : MGLStyleValueTypeNumberPair,
                      @"value" : value };
        }
    }
    else if ([typeInfo containsObject:MGLStyleValueTypeNumber])
    {
        return @{ @"type"  : MGLStyleValueTypeNumber,
                  @"value" : value };
    }
    else if ([typeInfo containsObject:MGLStyleValueTypeBoolean])
    {
        return @{ @"type"  : MGLStyleValueTypeBoolean,
                  @"value" : @([(NSString *)value boolValue]) };
    }
    else if ([typeInfo containsObject:MGLStyleValueTypeString])
    {
        return @{ @"type"  : MGLStyleValueTypeString,
                  @"value" : value };
    }
    else if ([typeInfo containsObject:MGLStyleValueTypeColor])
    {
        UIColor *color;

        if ([(NSString *)value hasPrefix:@"#"])
        {
            color = [UIColor colorWithHexString:value];
        }
        else if ([(NSString *)value hasPrefix:@"rgb"])
        {
            color = [UIColor colorWithRGBAString:value];
        }
        else if ([(NSString *)value hasPrefix:@"hsl"])
        {
            [NSException raise:@"invalid color format"
                        format:@"HSL color format not yet supported natively"];
        }
        else if ([value isKindOfClass:[NSArray class]] && [(NSArray *)value count] == 4)
        {
            color = [UIColor colorWithRed:[value[0] floatValue]
                                    green:[value[1] floatValue]
                                     blue:[value[2] floatValue]
                                    alpha:[value[3] floatValue]];
        }
        else if ([[UIColor class] respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"%@Color", [(NSString *)value lowercaseString]])])
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

            color = [[UIColor class] performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@Color", [(NSString *)value lowercaseString]])];

#pragma clang diagnostic pop
        }

        return @{ @"type"  : MGLStyleValueTypeColor,
                  @"value" : color };
    }

    return nil;
}

- (void)setStyleDescription:(NSDictionary *)styleDescription forLayer:(NSString *)layerName inClass:(NSString *)className
{
    NSMutableDictionary *convertedStyle = [NSMutableDictionary dictionary];

    for (NSString *key in [styleDescription allKeys])
    {
        NSArray *styleParameters = nil;

        if ([[self.allowedStyleTypes[MGLStyleKeyGeneric] allKeys] containsObject:key])
        {
            styleParameters = self.allowedStyleTypes[MGLStyleKeyGeneric][key];
        }
        else
        {
            NSString *keyType = [self getKeyTypeForLayer:layerName];

            if ([[self.allowedStyleTypes[keyType] allKeys] containsObject:key])
            {
                styleParameters = self.allowedStyleTypes[keyType][key];
            }
        }

        if (styleParameters)
        {
            if ([styleDescription[key][@"value"] isKindOfClass:[MGLStyleFunctionValue class]])
            {
                convertedStyle[key] = [(MGLStyleFunctionValue *)styleDescription[key][@"value"] rawStyle];
            }
            else if ([styleParameters containsObject:styleDescription[key][@"type"]])
            {
                NSString *valueType = styleDescription[key][@"type"];

                if ([valueType isEqualToString:MGLStyleValueTypeColor])
                {
                    convertedStyle[key] = [@"#" stringByAppendingString:[(UIColor *)styleDescription[key][@"value"] hexStringFromColor]];
                }
                else
                {
                    // the rest (bool/number/pair/string) are already JSON-convertible types
                    //
                    convertedStyle[key] = styleDescription[key][@"value"];
                }
            }
        }
        else
        {
            [NSException raise:@"invalid style description format"
                        format:@"unable to parse key '%@'",
                            key];
        }
    }

//    NSMutableDictionary *style = [[self getRawStyle] deepMutableCopy];
//
//    NSUInteger classIndex = [[[self getAllStyleClasses] valueForKey:@"name"] indexOfObject:className];
//
//    style[@"classes"][classIndex][@"layers"][layerName] = convertedStyle;
//
//    [self setRawStyle:style];
}

- (NSDictionary *)allowedStyleTypes
{
    static NSDictionary *MGLStyleAllowedTypes = @{
        MGLStyleKeyGeneric : @{
            @"enabled" : @[ MGLStyleValueTypeBoolean, MGLStyleValueFunctionAllowed ],
            @"translate" : @[ MGLStyleValueTypeNumberPair, MGLStyleValueFunctionAllowed ],
            @"translate-anchor" : @[ MGLStyleValueTypeString, MGLStyleValueFunctionAllowed ],
            @"opacity" : @[ MGLStyleValueTypeNumber, MGLStyleValueFunctionAllowed ],
            @"prerender" : @[ MGLStyleValueTypeBoolean ],
            @"prerender-buffer" : MGLStyleValueTypeNumber,
            @"prerender-size" : @[ MGLStyleValueTypeNumber ],
            @"prerender-blur" : @[ MGLStyleValueTypeNumber ] },
        MGLStyleKeyFill : @{
            @"color" : @[ MGLStyleValueTypeColor ],
            @"stroke" : @[ MGLStyleValueTypeColor ],
            @"antialias" : @[ MGLStyleValueTypeBoolean ],
            @"image" : @[ MGLStyleValueTypeString ] },
        MGLStyleKeyLine : @{
            @"color" : @[ MGLStyleValueTypeColor ],
            @"width" : @[ MGLStyleValueTypeNumber, MGLStyleValueFunctionAllowed ],
            @"dasharray" : @[ MGLStyleValueTypeNumberPair, MGLStyleValueFunctionAllowed ] },
        MGLStyleKeyIcon : @{
            @"color" : @[ MGLStyleValueTypeColor ],
            @"image" : @[ MGLStyleValueTypeString ],
            @"size" : @[ MGLStyleValueTypeNumber, MGLStyleValueFunctionAllowed ],
            @"radius" : @[ MGLStyleValueTypeNumber, MGLStyleValueFunctionAllowed],
            @"blur" : @[ MGLStyleValueTypeNumber, MGLStyleValueFunctionAllowed ] },
        MGLStyleKeyText : @{
            @"color" : @[ MGLStyleValueTypeColor ],
            @"stroke" : @[ MGLStyleValueTypeColor ],
            @"strokeWidth" : @[ MGLStyleValueTypeNumber, MGLStyleValueFunctionAllowed ],
            @"strokeBlur" : @[ MGLStyleValueTypeNumber, MGLStyleValueFunctionAllowed ],
            @"size" : @[ MGLStyleValueTypeNumber, MGLStyleValueFunctionAllowed ],
            @"rotate" : @[ MGLStyleValueTypeNumber, MGLStyleValueFunctionAllowed ],
            @"alwaysVisible" : @[ MGLStyleValueTypeBoolean ] },
        MGLStyleKeyRaster : @{},
        MGLStyleKeyComposite : @{},
        MGLStyleKeyBackground : @{
            @"color" : @[ MGLStyleValueTypeColor ] }
        };

    return MGLStyleAllowedTypes;
}

- (void)unsuspendRegionChangeDelegateQueue
{
    @synchronized (self.regionChangeDelegateQueue)
    {
        [self.regionChangeDelegateQueue setSuspended:NO];
    }
}

- (void)notifyMapChange:(NSNumber *)change
{
    switch ([change unsignedIntegerValue])
    {
        case llmr::platform::MapChangeRegionWillChange:
        case llmr::platform::MapChangeRegionWillChangeAnimated:
        {
            BOOL animated = ([change unsignedIntegerValue] == llmr::platform::MapChangeRegionWillChangeAnimated);

            @synchronized (self.regionChangeDelegateQueue)
            {
                if ([self.regionChangeDelegateQueue operationCount] == 0)
                {
                    if ([self.delegate respondsToSelector:@selector(mapView:regionWillChangeAnimated:)])
                    {
                        [self.delegate mapView:self regionWillChangeAnimated:animated];
                    }
                }

                [self.regionChangeDelegateQueue setSuspended:YES];

                if ([self.regionChangeDelegateQueue operationCount] == 0)
                {
                    [self.regionChangeDelegateQueue addOperationWithBlock:^(void)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^(void)
                        {
                            if ([self.delegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)])
                            {
                                [self.delegate mapView:self regionDidChangeAnimated:animated];
                            }
                        });
                    }];
                }
            }
            break;
        }
        case llmr::platform::MapChangeRegionDidChange:
        case llmr::platform::MapChangeRegionDidChangeAnimated:
        {
            if (self.pan.state       == UIGestureRecognizerStateChanged ||
                self.pinch.state     == UIGestureRecognizerStateChanged ||
                self.rotate.state    == UIGestureRecognizerStateChanged ||
                self.quickZoom.state == UIGestureRecognizerStateChanged) return;

            if (self.isAnimatingGesture) return;

            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(unsuspendRegionChangeDelegateQueue) object:nil];
            [self performSelector:@selector(unsuspendRegionChangeDelegateQueue) withObject:nil afterDelay:0];

            [self updateCompass];
            break;
        }
        case llmr::platform::MapChangeWillStartLoadingMap:
        {
            if ([self.delegate respondsToSelector:@selector(mapViewWillStartLoadingMap:)])
            {
                [self.delegate mapViewWillStartLoadingMap:self];
            }
            break;
        }
        case llmr::platform::MapChangeDidFinishLoadingMap:
        {
            if ([self.delegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)])
            {
                [self.delegate mapViewDidFinishLoadingMap:self];
            }
            break;
        }
        case llmr::platform::MapChangeDidFailLoadingMap:
        {
            if ([self.delegate respondsToSelector:@selector(mapViewDidFailLoadingMap:withError::)])
            {
                [self.delegate mapViewDidFailLoadingMap:self withError:nil];
            }
            break;
        }
        case llmr::platform::MapChangeWillStartRenderingMap:
        {
            if ([self.delegate respondsToSelector:@selector(mapViewWillStartRenderingMap:)])
            {
                [self.delegate mapViewWillStartRenderingMap:self];
            }
            break;
        }
        case llmr::platform::MapChangeDidFinishRenderingMap:
        {
            if ([self.delegate respondsToSelector:@selector(mapViewDidFinishRenderingMap:fullyRendered:)])
            {
                [self.delegate mapViewDidFinishRenderingMap:self fullyRendered:NO];
            }
            break;
        }
        case llmr::platform::MapChangeDidFinishRenderingMapFullyRendered:
        {
            if ([self.delegate respondsToSelector:@selector(mapViewDidFinishRenderingMap:fullyRendered:)])
            {
                [self.delegate mapViewDidFinishRenderingMap:self fullyRendered:YES];
            }
            break;
        }
    }
}

- (void)updateCompass
{
    double angle = llmrMap->getAngle();
    angle *= 180 / M_PI;
    while (angle >= 360) angle -= 360;
    while (angle < 0) angle += 360;

    self.compass.transform = CGAffineTransformMakeRotation(llmrMap->getAngle());

    if (llmrMap->getAngle() && self.compass.alpha < 1)
    {
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^(void)
        {
            self.compass.alpha = 1;
        }
                         completion:nil];
    }
}

+ (UIImage *)resourceImageNamed:(NSString *)imageName
{
    if ( ! [[imageName pathExtension] length])
        imageName = [imageName stringByAppendingString:@".png"];

    return [UIImage imageWithContentsOfFile:[MGLMapView pathForBundleResourceNamed:imageName ofType:nil]];
}

+ (NSString *)pathForBundleResourceNamed:(NSString *)name ofType:(NSString *)extension
{
    NSString *path;

    NSString *resourceBundlePath = [[NSBundle mainBundle] pathForResource:@"MapboxGL"
                                                                   ofType:@"bundle"];

    if (resourceBundlePath)
    {
        path = [[NSBundle bundleWithPath:resourceBundlePath] pathForResource:name
                                                                      ofType:extension];
    }
    else
    {
        path = [[NSBundle mainBundle] pathForResource:name ofType:extension];
    }

    NSAssert(path, @"Resource not found in application.");

    return path;
}

- (void)swap
{
    if (llmrMap->needsSwap())
    {
        [self.glView display];
        llmrMap->swapped();
    }
}

class LLMRView : public llmr::View
{
    public:
        LLMRView(MGLMapView *nativeView) : nativeView(nativeView) {}
        virtual ~LLMRView() {}

    void notify_map_change(llmr::platform::MapChange change)
    {
        [nativeView performSelector:@selector(notifyMapChange:)
                         withObject:@(change)
                         afterDelay:0];
    }

    void make_active()
    {
        [EAGLContext setCurrentContext:nativeView.context];
    }

    void swap()
    {
        [nativeView performSelectorOnMainThread:@selector(swap)
                                     withObject:nil
                                  waitUntilDone:NO];
    }

    unsigned int root_fbo()
    {
        return 1;
    }

    private:
        MGLMapView *nativeView = nullptr;
};

void llmr::platform::notify_map_change(MapChange change, timestamp delay)
{
    if (delay)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay)), dispatch_get_main_queue(), ^(void)
        {
            llmrView->notify_map_change(change);
        });
    }
    else
    {
        llmrView->notify_map_change(change);
    }
}

@end
