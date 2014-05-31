#import "MGLSAppDelegate.h"

#import "MGLSViewController.h"

@implementation MGLSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [MGLSViewController new];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
