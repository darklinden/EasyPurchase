//
//  EasyPurchase.h
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
#error This lib is for iOS 7.0 and later
#endif

#define IAP_JSON_FORMAT                     @"{\"receipt-data\":\"%@\"}"
#define IAP_SUBSCRIBE_FAILED_SANDBOX        @"21007"
#define IAP_SUBSCRIBE_SUCCESS               @"0"
#define IAP_SANDBOX_URL                     @"https://sandbox.itunes.apple.com/verifyReceipt"
#define IAP_PRODUCT_URL                     @"https://buy.itunes.apple.com/verifyReceipt"
#define IAP_RECEIPT_TIMEOUT                 10.f

#define IAP_SECURE_VALUE_COUNT_KEY          @"IAP_SECURE_VALUE_COUNT_KEY"
#define IAP_SECURE_VALUE_KEY_FORMAT         @"IAP_SECURE_VALUE_KEY_%d"

#define IAP_OBSERVER_LOG( s, ... )          while (DEBUG) { NSLog( s, ... ); }
#define IAP_PRODUCT_LOG( s, ... )           while (DEBUG) { NSLog( s, ... ); }
#define IAP_CHECK_LOG( s, ... )             while (DEBUG) { NSLog( s, ... ); }
#define IAP_CONTROLLER_LOG( s, ... )        while (DEBUG) { NSLog( s, ... ); }

// user cancelled the request, etc.
#define IAP_LOCALSTR_SKErrorPaymentCancelled            @"IAP_LOCALSTR_SKErrorPaymentCancelled"

// A transaction error occurred, so notify user.
#define IAP_LOCALSTR_SKErrorUnknown                     NSLocalizedString(@"IAP_LOCALSTR_SKErrorUnknown", @"")

// client is not allowed to issue the request, etc.
#define IAP_LOCALSTR_SKErrorClientInvalid               NSLocalizedString(@"IAP_LOCALSTR_SKErrorClientInvalid", @"")

// purchase identifier was invalid, etc.
#define IAP_LOCALSTR_SKErrorPaymentInvalid              NSLocalizedString(@"IAP_LOCALSTR_SKErrorPaymentInvalid", @"")

// this device is not allowed to make the payment
#define IAP_LOCALSTR_SKErrorPaymentNotAllowed           NSLocalizedString(@"IAP_LOCALSTR_SKErrorPaymentNotAllowed", @"")

// Product is not available in the current storefront
#define IAP_LOCALSTR_SKErrorStoreProductNotAvailable    NSLocalizedString(@"IAP_LOCALSTR_SKErrorStoreProductNotAvailable", @"")

//get product failed
#define IAP_LOCALSTR_GetProductFailed                   NSLocalizedString(@"IAP_LOCALSTR_GetProductFailed", @"")

//check receipt failed
#define IAP_LOCALSTR_CheckReceiptFailed                 NSLocalizedString(@"IAP_LOCALSTR_CheckReceiptFailed", @"")

//check receipt network failed
#define IAP_LOCALSTR_CheckReceiptNetWorkFailed          NSLocalizedString(@"IAP_LOCALSTR_CheckReceiptNetWorkFailed", @"")

//inapppurchase dead lock
#define IAP_LOCALSTR_InAppPurchaseDeadLock              NSLocalizedString(@"IAP_LOCALSTR_InAppPurchaseDeadLock", @"")

//restore success but get nothing restored
#define IAP_LOCALSTR_RestoreGetEmptyArray               NSLocalizedString(@"IAP_LOCALSTR_RestoreGetEmptyArray", @"")

typedef void(^EPProductInfoCompletionHandle)(NSArray *responseProducts);

typedef void(^EPPurchaseCompletionHandle)(NSString *productId, NSString *errMsg);

typedef void(^EPRestoreCompletionHandle)(NSArray *restoredProducts, NSString *errMsg);

@interface EasyPurchase : NSObject

//for Non-Consumable
+ (BOOL)isPurchased:(NSString *)productId;

//request products informations
+ (void)requestProductsByIds:(NSArray *)productIds completion:(EPProductInfoCompletionHandle)completionHandle;

//Purchase Observer should be Singleton, so you should not call more than one purchase/restore function at the same time

//single purchase
+ (void)purchase:(SKProduct *)product completion:(EPPurchaseCompletionHandle)completionHandle;

//single purchase
+ (void)purchaseProductById:(NSString *)productId completion:(EPPurchaseCompletionHandle)completionHandle;

//restore
+ (void)restorePurchaseWithCompletion:(EPRestoreCompletionHandle)completionHandle;

@end

