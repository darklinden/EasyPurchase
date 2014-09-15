//
//  GAITracker+Compatible.m
//  DemoForInAppPurchase
//
//  Created by DarkLinden on S/23/2013.
//  Copyright (c) 2013 DarkLinden. All rights reserved.
//

#import "GAITrackerCompatible.h"
#import "GAIDictionaryBuilder.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <stdio.h>
#import <dlfcn.h>
#import "GAIFields.h"
#import <objc/objc.h>
#import <objc/runtime.h>

@implementation GAITrackerCompatible

static void gaiApiHookClass(Class selectClass,
                            Class hookClass,
                            SEL localSelector,
                            SEL privateSelector,
                            SEL originalSelector)
{
    //local get method
    Method local = class_getInstanceMethod(selectClass, localSelector);
    
    //private create method
    Method private = class_getInstanceMethod(hookClass, privateSelector);
    
    // bind original method
    IMP localImp = method_getImplementation(local);
    class_addMethod(selectClass,
                    originalSelector,
                    localImp,
                    method_getTypeEncoding(local));
    
    // replace local method
    IMP privateImp = method_getImplementation(private);
    class_replaceMethod(selectClass,
                        localSelector,
                        privateImp,
                        method_getTypeEncoding(local));
}


+ (void)setupTrackerWithTrackingId:(NSString *)trackingId
{
    id tracker = [[GAI sharedInstance] trackerWithTrackingId:trackingId];
    gaiApiHookClass([tracker class],
                    [self class],
                    @selector(trackView),
                    @selector(privateTrackView),
                    @selector(originalTrackView));
    
    gaiApiHookClass([tracker class],
                    [self class],
                    @selector(trackView:),
                    @selector(privateTrackView:),
                    @selector(originalTrackView:));
    
    gaiApiHookClass([tracker class],
                    [self class],
                    @selector(trackEventWithCategory:withAction:withLabel:withValue:),
                    @selector(privateTrackEventWithCategory:withAction:withLabel:withValue:),
                    @selector(originalTrackEventWithCategory:withAction:withLabel:withValue:));
}

- (BOOL)privateTrackView
{
    NSLog(@"[[GAI sharedInstance] trackView]");
    GAIDictionaryBuilder *builder = [GAIDictionaryBuilder createAppView];
    [[[GAI sharedInstance] defaultTracker] send:[builder build]];
    return YES;
}

- (BOOL)privateTrackView:(NSString *)screen
{
    NSLog(@"[[GAI sharedInstance] trackView:%@]", screen);
    if (screen) {
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName value:screen];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }
    
    return YES;
}

- (BOOL)privateTrackEventWithCategory:(NSString *)category
                    withAction:(NSString *)action
                     withLabel:(NSString *)label
                     withValue:(NSNumber *)value
{
    NSLog(@"[[GAI sharedInstance] privateTrackEventWithCategory:%@ \n\
          withAction:%@ \n\
          withLabel:%@ \n\
          withValue:%@]", category, action, label, value);
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category           // Event category (required)
                                                          action:action             // Event action (required)
                                                           label:label              // Event label
                                                           value:value] build]];    // Event value
    return YES;
}

@end
