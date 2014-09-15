//
//  AppDelegate.m
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/18/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"
#import "GAI.h"
#import "GAITrackerCompatible.h"

#warning set google analytics tracking id here
#define kTrackingId @""

@implementation AppDelegate
@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    [GAI sharedInstance].debug = YES;
    [GAI sharedInstance].dispatchInterval = 120;
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAITrackerCompatible setupTrackerWithTrackingId:kTrackingId];
//    [[GAI sharedInstance] trackerWithTrackingId:kTrackingId];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    RootViewController *viewController = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil];
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
