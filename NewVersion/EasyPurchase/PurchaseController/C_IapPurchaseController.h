//
//  C_IapPurchaseController.h
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/19/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol C_IapPurchaseControllerDelegate <NSObject>
@optional
- (void)responseProducts:(NSArray *)products pricesByIDs:(NSDictionary *)prices titlesByIDs:(NSDictionary *)titles;
- (void)purchaseProduct:(SKProduct *)product errMsg:(NSString *)errMsg;
- (void)restoreProducts:(NSMutableArray *)products errMsg:(NSString *)errMsg;
@end

@interface C_IapPurchaseController : NSObject 
@property (unsafe_unretained) id<C_IapPurchaseControllerDelegate> delegate;

// life circle
+ (id)mainIapPurchaseController;
+ (void)close;

// asset & store & deal with old purchase
+ (BOOL)assetIsSubscribe:(NSString *)product_id;
+ (void)storeSubscribe:(NSString *)product_id;
+ (void)dealWithOldProduct:(NSString *)product_id forKey:(NSString *)key;

// get product info
+ (void)requestProductsByIds:(NSArray *)product_ids;

// purchase
+ (void)requestPurchaseProduct:(SKProduct *)product;

// restore
+ (void)requestRestore;

@end
