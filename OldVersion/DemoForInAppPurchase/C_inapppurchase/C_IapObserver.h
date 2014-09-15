//
//  C_IapObserver.h
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/18/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class C_IapObserver;

@protocol C_IapObserverDelegate <NSObject>
@required
- (void)checkProduct:(NSString *)product_id receipt:(NSData *)receipt;
- (void)finishPurchase:(NSString *)product_id error:(NSString *)errMsg;
- (void)finishRestoreWithError:(NSString *)errMsg;
@end

@interface C_IapObserver : NSObject <SKPaymentTransactionObserver>
+ (id)observerWithDelegate:(id<C_IapObserverDelegate>)delegate;
@end
