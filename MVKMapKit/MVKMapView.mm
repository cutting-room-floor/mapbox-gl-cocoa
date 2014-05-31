#import "MVKMapView.h"

#import "foundation_request.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>

#include <llmr/llmr.hpp>
#include <llmr/platform/platform.hpp>

#import "MVKTypes.h"
#import "MVKStyleFunctionValue.h"

#import "UIColor+MVKAdditions.h"
#import "NSArray+MVKAdditions.h"
#import "NSDictionary+MVKAdditions.h"

extern NSString *const MVKStyleKeyGeneric;
extern NSString *const MVKStyleKeyFill;
extern NSString *const MVKStyleKeyLine;
extern NSString *const MVKStyleKeyIcon;
extern NSString *const MVKStyleKeyText;
extern NSString *const MVKStyleKeyRaster;
extern NSString *const MVKStyleKeyComposite;
extern NSString *const MVKStyleKeyBackground;

extern NSString *const MVKStyleValueFunctionAllowed;

@interface MVKMapView () <UIGestureRecognizerDelegate, GLKViewDelegate>

@property (nonatomic) EAGLContext *context;
@property (nonatomic) GLKView *glView;
@property (nonatomic) UIButton *compassButton;
@property (nonatomic) UIPanGestureRecognizer *pan;
@property (nonatomic) UIPinchGestureRecognizer *pinch;
@property (nonatomic) UIRotationGestureRecognizer *rotate;
@property (nonatomic, readonly) NSDictionary *allowedStyleTypes;
@property (nonatomic) CGPoint centerPoint;
@property (nonatomic) CGFloat scale;
@property (nonatomic) CGFloat angle;
@property (nonatomic) CGFloat quickZoomStart;

@end

@interface MVKStyleFunctionValue (MVKMapViewFriend)

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

- (NSString *)defaultStyleJSON
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"style.min" ofType:@"js"];

    NSString *json = [NSString stringWithContentsOfFile:path encoding:[NSString defaultCStringEncoding] error:nil];

    return json;
}

- (id)commonInit
{
    // create context
    //
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if ( ! _context)
    {
        NSLog(@"Failed to create OpenGL ES context");

        return nil;
    }

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
    UIView *logoBug = [[UIImageView alloc] initWithImage:[[self class] resourceImageNamed:@"mapbox.png"]];
    logoBug.frame = CGRectMake(8, self.bounds.size.height - logoBug.bounds.size.height - 4, logoBug.bounds.size.width, logoBug.bounds.size.height);
    logoBug.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:logoBug];

    // setup attribution
    //
    UIButton *attributionButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    attributionButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [attributionButton addTarget:self action:@selector(showAttribution:) forControlEvents:UIControlEventTouchUpInside];
    attributionButton.frame = CGRectMake(self.bounds.size.width  - 30, self.bounds.size.height - 30, attributionButton.bounds.size.width, attributionButton.bounds.size.height);
    [self addSubview:attributionButton];

    // setup compass
    //
    _compassButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *compassImage = [[self class] resourceImageNamed:@"Compass.png"];
    _compassButton.frame = CGRectMake(0, 0, compassImage.size.width, compassImage.size.height);
    [_compassButton setImage:compassImage forState:UIControlStateNormal];
    [_compassButton setImage:compassImage forState:UIControlStateHighlighted];
    _compassButton.alpha = 0;
    [_compassButton addTarget:self action:@selector(handleCompassTapGesture:) forControlEvents:UIControlEventTouchUpInside];
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width - compassImage.size.width - 5, [[UIApplication sharedApplication] statusBarFrame].size.height + 5, compassImage.size.width, compassImage.size.height)];
    container.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [container addSubview:_compassButton];
    [self addSubview:container];

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
    llmrMap->setStyleJSON((std::string)[[self defaultStyleJSON] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

- (void)handleCompassTapGesture:(id)sender
{
    [self resetNorth];
}

#pragma clang diagnostic pop

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
        CGFloat ease = 0.25;

        CGPoint velocity = [pan velocityInView:pan.view];
        velocity.x = velocity.x * ease;
        velocity.y = velocity.y * ease;

        CGFloat speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
        CGFloat deceleration = 2500;
        CGFloat duration = speed / (deceleration * ease);

        CGPoint offset = CGPointMake(velocity.x * duration / 2, velocity.y * duration / 2);

        llmrMap->moveBy(offset.x, offset.y, duration);
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
        CGFloat newScale = self.scale * pinch.scale;

        if (log2(newScale) < llmrMap->getMinZoom()) return;

        double scale = llmrMap->getScale();

        llmrMap->scaleBy(newScale / scale, [pinch locationInView:pinch.view].x, [pinch locationInView:pinch.view].y);
    }
    else if (pinch.state == UIGestureRecognizerStateEnded || pinch.state == UIGestureRecognizerStateCancelled)
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

    [UIView animateWithDuration:0.5 animations:^(void) { self.compassButton.transform = CGAffineTransformIdentity; }];
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
    llmrMap->toggleStyle();
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
    return [[self getRawStyle] valueForKeyPath:@"structure.name"];
}

- (void)setStyleOrderedLayerNames:(NSArray *)orderedLayerNames
{
    NSDictionary *style = [self getRawStyle];
    NSDictionary *oldStructure = style[@"structure"];
    NSMutableDictionary *newStructure = [NSMutableDictionary dictionary];

    if ([orderedLayerNames count] != [[oldStructure valueForKeyPath:@"name"] count])
    {
        [NSException raise:@"invalid layer count"
                    format:@"new layer count (%lu) should equal existing layer count (%lu)",
                        (unsigned long)[orderedLayerNames count],
                        (unsigned long)[[oldStructure valueForKeyPath:@"name"] count]];
    }
    else
    {
        for (NSString *newLayerName in orderedLayerNames)
        {
            if ( ! [[oldStructure valueForKeyPath:@"name"] containsObject:newLayerName])
            {
                [NSException raise:@"invalid layer name"
                            format:@"layer name %@ unknown",
                                newLayerName];
            }
            else
            {
                newStructure[newLayerName] = oldStructure[newLayerName];
            }
        }
    }

    [style setValue:newStructure forKey:@"structure"];

    [self setRawStyle:style];
}

- (NSArray *)getAllStyleClasses
{
    NSMutableArray *returnArray = [NSMutableArray array];

    NSArray *classNames = [[self getRawStyle] valueForKeyPath:@"classes.name"];

    std::set<std::string> appliedClasses = llmrMap->getAppliedClasses();

    for (NSString *className in classNames)
    {
        auto applied_it = appliedClasses.find([className cStringUsingEncoding:[NSString defaultCStringEncoding]]);

        BOOL applied = (applied_it != appliedClasses.end());

        [returnArray addObject:@{ @"name"    : className,
                                  @"applied" : @(applied) }];
    }

    return returnArray;
}

- (NSArray *)getAppliedStyleClasses
{
    NSMutableArray *returnArray = [NSMutableArray array];

    std::set<std::string> appliedClasses = llmrMap->getAppliedClasses();

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
    NSArray *currentClasses = [self getAllStyleClasses];

    std::set<std::string> newAppliedClasses;

    for (NSString *appliedClass in appliedClasses)
    {
        if ( ! [[currentClasses valueForKeyPath:@"name"] containsObject:appliedClass])
        {
            [NSException raise:@"invalid class name"
                        format:@"class name %@ unknown",
                            appliedClass];
        }

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
        keyType = MVKStyleKeyFill;
    }
    else if ([bucketType isEqualToString:@"line"])
    {
        keyType = MVKStyleKeyLine;
    }
    else if ([bucketType isEqualToString:@"point"])
    {
        keyType = MVKStyleKeyIcon;
    }
    else if ([bucketType isEqualToString:@"text"])
    {
        keyType = MVKStyleKeyText;
    }
    else if ([bucketType isEqualToString:@"raster"])
    {
        keyType = MVKStyleKeyRaster;
    }
    else if ([bucketType isEqualToString:@"composite"])
    {
        keyType = MVKStyleKeyComposite;
    }
    else if ([bucketType isEqualToString:@"background"])
    {
        keyType = MVKStyleKeyBackground;
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

        if ([[self.allowedStyleTypes[MVKStyleKeyGeneric] allKeys] containsObject:keyName])
        {
            [styleDescription setValue:[self typedPropertyForKeyName:keyName
                                                              ofType:MVKStyleKeyGeneric
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

    if ([value isKindOfClass:[NSArray class]] && ! [typeInfo containsObject:MVKStyleValueTypeColor])
    {
        if ([typeInfo containsObject:MVKStyleValueFunctionAllowed])
        {
            if ([[(NSArray *)value firstObject] isKindOfClass:[NSString class]])
            {
                NSString *functionType;

                if ([[(NSArray *)value firstObject] isEqualToString:@"linear"])
                {
                    functionType = MVKStyleValueTypeFunctionLinear;
                }
                else if ([[(NSArray *)value firstObject] isEqualToString:@"stops"])
                {
                    functionType = MVKStyleValueTypeFunctionStops;
                }
                else if ([[(NSArray *)value firstObject] isEqualToString:@"exponential"])
                {
                    functionType = MVKStyleValueTypeFunctionExponential;
                }
                else if ([[(NSArray *)value firstObject] isEqualToString:@"min"])
                {
                    functionType = MVKStyleValueTypeFunctionMinimumZoom;
                }
                else if ([[(NSArray *)value firstObject] isEqualToString:@"max"])
                {
                    functionType = MVKStyleValueTypeFunctionMaximumZoom;
                }

                if (functionType)
                {
                    return @{ @"type"  : functionType,
                              @"value" : value };
                }
            }
        }
        else if ([typeInfo containsObject:MVKStyleValueTypeNumberPair])
        {
            return @{ @"type"  : MVKStyleValueTypeNumberPair,
                      @"value" : value };
        }
    }
    else if ([typeInfo containsObject:MVKStyleValueTypeNumber])
    {
        return @{ @"type"  : MVKStyleValueTypeNumber,
                  @"value" : value };
    }
    else if ([typeInfo containsObject:MVKStyleValueTypeBoolean])
    {
        return @{ @"type"  : MVKStyleValueTypeBoolean,
                  @"value" : @([(NSString *)value boolValue]) };
    }
    else if ([typeInfo containsObject:MVKStyleValueTypeString])
    {
        return @{ @"type"  : MVKStyleValueTypeString,
                  @"value" : value };
    }
    else if ([typeInfo containsObject:MVKStyleValueTypeColor])
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

        return @{ @"type"  : MVKStyleValueTypeColor,
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

        if ([[self.allowedStyleTypes[MVKStyleKeyGeneric] allKeys] containsObject:key])
        {
            styleParameters = self.allowedStyleTypes[MVKStyleKeyGeneric][key];
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
            if ([styleDescription[key][@"value"] isKindOfClass:[MVKStyleFunctionValue class]])
            {
                convertedStyle[key] = [(MVKStyleFunctionValue *)styleDescription[key][@"value"] rawStyle];
            }
            else if ([styleParameters containsObject:styleDescription[key][@"type"]])
            {
                NSString *valueType = styleDescription[key][@"type"];

                if ([valueType isEqualToString:MVKStyleValueTypeColor])
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

    NSMutableDictionary *style = [[self getRawStyle] deepMutableCopy];

    style[@"classes"][0][@"layers"][layerName] = convertedStyle;

    [self setRawStyle:style];
}

- (NSDictionary *)allowedStyleTypes
{
    static NSDictionary *MVKStyleAllowedTypes = @{
        MVKStyleKeyGeneric : @{
            @"enabled" : @[ MVKStyleValueTypeBoolean, MVKStyleValueFunctionAllowed ],
            @"translate" : @[ MVKStyleValueTypeNumberPair, MVKStyleValueFunctionAllowed ],
            @"translate-anchor" : @[ MVKStyleValueTypeString, MVKStyleValueFunctionAllowed ],
            @"opacity" : @[ MVKStyleValueTypeNumber, MVKStyleValueFunctionAllowed ],
            @"prerender" : @[ MVKStyleValueTypeBoolean ],
            @"prerender-buffer" : MVKStyleValueTypeNumber,
            @"prerender-size" : @[ MVKStyleValueTypeNumber ],
            @"prerender-blur" : @[ MVKStyleValueTypeNumber ] },
        MVKStyleKeyFill : @{
            @"color" : @[ MVKStyleValueTypeColor ],
            @"stroke" : @[ MVKStyleValueTypeColor ],
            @"antialias" : @[ MVKStyleValueTypeBoolean ],
            @"image" : @[ MVKStyleValueTypeString ] },
        MVKStyleKeyLine : @{
            @"color" : @[ MVKStyleValueTypeColor ],
            @"width" : @[ MVKStyleValueTypeNumber, MVKStyleValueFunctionAllowed ],
            @"dasharray" : @[ MVKStyleValueTypeNumberPair, MVKStyleValueFunctionAllowed ] },
        MVKStyleKeyIcon : @{
            @"color" : @[ MVKStyleValueTypeColor ],
            @"image" : @[ MVKStyleValueTypeString ],
            @"size" : @[ MVKStyleValueTypeNumber, MVKStyleValueFunctionAllowed ],
            @"radius" : @[ MVKStyleValueTypeNumber, MVKStyleValueFunctionAllowed],
            @"blur" : @[ MVKStyleValueTypeNumber, MVKStyleValueFunctionAllowed ] },
        MVKStyleKeyText : @{
            @"color" : @[ MVKStyleValueTypeColor ],
            @"stroke" : @[ MVKStyleValueTypeColor ],
            @"strokeWidth" : @[ MVKStyleValueTypeNumber, MVKStyleValueFunctionAllowed ],
            @"strokeBlur" : @[ MVKStyleValueTypeNumber, MVKStyleValueFunctionAllowed ],
            @"size" : @[ MVKStyleValueTypeNumber, MVKStyleValueFunctionAllowed ],
            @"rotate" : @[ MVKStyleValueTypeNumber, MVKStyleValueFunctionAllowed ],
            @"alwaysVisible" : @[ MVKStyleValueTypeBoolean ] },
        MVKStyleKeyRaster : @{},
        MVKStyleKeyComposite : @{},
        MVKStyleKeyBackground : @{
            @"color" : @[ MVKStyleValueTypeColor ] }
        };

    return MVKStyleAllowedTypes;
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

    self.compassButton.transform = CGAffineTransformMakeRotation(llmrMap->getAngle());

    if (llmrMap->getAngle() && self.compassButton.alpha < 1)   [UIView animateWithDuration:0.5 animations:^(void) { self.compassButton.alpha = 1; }];
    else if ( ! llmrMap->getAngle() && self.compassButton.alpha > 0) [UIView animateWithDuration:0.5 animations:^(void) { self.compassButton.alpha = 0; }];
}

+ (UIImage *)resourceImageNamed:(NSString *)imageName
{
    if ( ! [[imageName pathExtension] length])
        imageName = [imageName stringByAppendingString:@".png"];

    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];

    NSAssert(imagePath, @"Resource image not found in application.");

    return [UIImage imageWithContentsOfFile:imagePath];
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
