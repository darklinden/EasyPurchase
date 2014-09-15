//
//  RootViewController.m
//  DemoForInAppPurchase
//
//  Created by DarkLinden on M/9/2013.
//  Copyright (c) 2013 DarkLinden. All rights reserved.
//

#import "RootViewController.h"
#import "ViewController.h"

@implementation RootViewController

- (IBAction)pBtn_purchase_clicked:(id)sender
{
    ViewController *viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    UINavigationController *pNav = [[UINavigationController alloc] initWithRootViewController:viewController];
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0
    [self presentViewController:pNav animated:YES completion:nil];
#else
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.f) {
        [self presentViewController:pNav animated:YES completion:nil];
    }
    else {
        [self presentModalViewController:pNav animated:YES];
    }
#endif
}

@end
