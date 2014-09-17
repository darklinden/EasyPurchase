//
//  EPPurchaseObserver.h
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "EasyPurchase.h"

//ob should be Singleton, so you should not call functions at the same time
@interface EPPurchaseObserver : NSObject

+ (void)purchase:(SKProduct *)product completion:(EPPurchaseCompletionHandle)completionHandle;

+ (void)restorePurchaseWithCompletion:(EPRestoreCompletionHandle)completionHandle;

@end
