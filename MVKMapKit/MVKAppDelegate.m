//
//  MVKAppDelegate.m
//  MVKMapKit
//
//  Created by Justin R. Miller on 4/23/14.
//  Copyright (c) 2014 Mapbox. All rights reserved.
//

#import "MVKAppDelegate.h"

#import "MVKViewController.h"

@implementation MVKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [MVKViewController new];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
