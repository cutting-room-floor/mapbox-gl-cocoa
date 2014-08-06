#import "MGLTAppDelegate.h"
#import "MGLTViewController.h"
#import "MGLTestCommon.h"
#import "VCR.h"
#import "VCRCassette.h"
#import "VCRCassetteManager.h"

#define MGLShouldRecordNetworkContent 0

@implementation MGLTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSNotificationCenter defaultCenter] addObserverForName:MGLTestsCompletedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        if (MGLShouldRecordNetworkContent) {
            NSString *newCassettePath = @"/tmp/cassette.json";
            [VCR save:newCassettePath];
            NSLog(@"=====");
            NSLog(@"WROTE NEW CASSETTE TO %@", newCassettePath);
            NSLog(@"=====");
        }
    }];

    if (!MGLShouldRecordNetworkContent) {
        VCRCassette *cassette = [[VCRCassette alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"cassette" ofType:@"json"]]];
        [[VCRCassetteManager defaultManager] setCurrentCassette:cassette];
    }
    [VCR start];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UINavigationController *wrapper = [[UINavigationController alloc] initWithRootViewController:[MGLTViewController new]];
    self.window.rootViewController = wrapper;
    wrapper.navigationBarHidden = YES;
    wrapper.toolbarHidden = YES;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
