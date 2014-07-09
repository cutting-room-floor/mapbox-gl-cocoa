#import "MGLTAppDelegate.h"
#import "MGLTViewController.h"

@implementation MGLTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [MGLTViewController new];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
