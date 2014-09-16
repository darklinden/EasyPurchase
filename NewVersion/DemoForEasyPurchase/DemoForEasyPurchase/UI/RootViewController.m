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
    [self presentViewController:pNav animated:YES completion:nil];
}

@end
