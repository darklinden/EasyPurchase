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

//copied from VerifyStoreReceipt
#ifndef YES_I_HAVE_READ_THE_WARNING_AND_I_ACCEPT_THE_RISK

#warning --- DON'T USE THIS CODE AS IS! IF EVERYONE USES THE SAME CODE
#warning --- IT IS PRETTY EASY TO BUILD AN AUTOMATIC CRACKING TOOL
#warning --- FOR APPS USING THIS CODE!
#warning --- BY USING THIS CODE YOU ACCEPT TAKING THE RESPONSIBILITY FOR
#warning --- ANY DAMAGE!
#warning ---
#warning --- YOU HAVE BEEN WARNED!

#endif

extern NSString const *bundleVersion;
extern NSString const *bundleIdentifier;

#define IAP_SECURE_VALUE_COUNT_KEY          @"IAP_SECURE_VALUE_COUNT_KEY"
#define IAP_SECURE_VALUE_KEY_FORMAT         @"IAP_SECURE_VALUE_KEY_%lld"

#if DEBUG

#define IAP_OBSERVER_LOG( ... )             NSLog(@"IAP_OBSERVER: %@", [NSString stringWithFormat:__VA_ARGS__])
#define IAP_PRODUCT_LOG( ... )              NSLog(@"IAP_PRODUCT:%@", [NSString stringWithFormat:__VA_ARGS__])
#define IAP_CHECK_LOG( ... )                NSLog(@"IAP_CHECK: %@", [NSString stringWithFormat:__VA_ARGS__])
#define IAP_CONTROLLER_LOG( ... )           NSLog(@"IAP_CONTROLLER: %@", [NSString stringWithFormat:__VA_ARGS__])

#else

#define IAP_OBSERVER_LOG( ... )             do {} while (0)
#define IAP_PRODUCT_LOG( ... )              do {} while (0)
#define IAP_CHECK_LOG( ... )                do {} while (0)
#define IAP_CONTROLLER_LOG( ... )           do {} while (0)

#endif

//if IAP_Check_DeadLock is setted to TRUE, the purchase will return an "EPErrorQueueDeadLock" error if there's any unfinished payment in queue
//for Non-Consumable purchase it recommended to restart the device, but I have no idea for consumable purchase.
//It is not a good idea to stop purchase in this case
//TODO: an solution for deadlock payment in queue
#define IAP_Check_DeadLock FALSE

//if IAP_Check_TransactionDeferred is setted to TRUE, the purchase will return an "EPErrorTransactionDeferred" error if an Non-Consumable purchase suffered the SKPaymentTransactionStateDeferred state
#define IAP_Check_TransactionDeferred TRUE

typedef enum : NSUInteger {
    //success
    EPErrorSuccess,
    
    //get product error
    EPErrorGetProductFailed,
    
    //purchase error
    EPErrorCancelled,
    EPErrorClientInvalid,
    EPErrorPaymentInvalid,
    EPErrorPaymentNotAllowed,
    EPErrorProductNotAvailable,
    EPErrorUnknown,
    
    //restore error
    EPErrorRestoreError,
    EPErrorRestoreGetEmptyArray,
    
    //check receipt error
    EPErrorCheckReceiptFailed,
    EPErrorRefreshReceiptFailed,
    
    //other definition
    EPErrorQueueDeadLock,
    EPErrorTransactionDeferred
} EPError;

typedef enum : NSUInteger {
    SKProductPaymentTypeNonConsumable,
    SKProductPaymentTypeConsumable
} SKProductPaymentType;

#if DEBUG

#define EPErrorName \
@{ \
@(EPErrorSuccess) : @"EPErrorSuccess", \
@(EPErrorGetProductFailed): @"EPErrorGetProductFailed", \
@(EPErrorCancelled): @"EPErrorCancelled", \
@(EPErrorClientInvalid): @"EPErrorClientInvalid", \
@(EPErrorPaymentInvalid): @"EPErrorPaymentInvalid", \
@(EPErrorPaymentNotAllowed): @"EPErrorPaymentNotAllowed", \
@(EPErrorProductNotAvailable): @"EPErrorProductNotAvailable", \
@(EPErrorRestoreGetEmptyArray): @"EPErrorRestoreGetEmptyArray", \
@(EPErrorCheckReceiptFailed): @"EPErrorCheckReceiptFailed", \
@(EPErrorQueueDeadLock): @"EPErrorQueueDeadLock", \
@(EPErrorTransactionDeferred): @"EPErrorTransactionDeferred" \
}

#endif

typedef void(^EPProductInfoCompletionHandle)(NSArray *requestProductIds, NSArray *responseProducts);

typedef void(^EPPurchaseCompletionHandle)(NSString *productId, NSString *transactionId, EPError error);

typedef void(^EPRestoreCompletionHandle)(NSArray *restoredProducts, EPError error);

typedef void(^EPReceiptCheckerCompletionHandle)(NSArray *passedProducts, EPError error);

typedef void(^EPConsumableReceiptCheckerCompletionHandle)(NSString *productId, NSString *transactionId, EPError error);

@interface EasyPurchase : NSObject

#pragma mark - product info

//request products informations
+ (void)requestProductsByIds:(NSArray *)productIds completion:(EPProductInfoCompletionHandle)completionHandle;

#pragma mark - Purchase

//keychain save/load purchase state
+ (BOOL)isPurchased:(NSString *)productId;
+ (void)savePurchase:(NSString *)productId;
+ (void)removeAllPurchase;

/*
 * warning: Purchase Observer should be Singleton, 
 *          so you should not call more than one purchase/restore function at the same time
 */

//single purchase
+ (void)purchase:(SKProduct *)product
            type:(SKProductPaymentType)type
      completion:(EPPurchaseCompletionHandle)completionHandle;

+ (void)purchaseProductById:(NSString *)productId
                       type:(SKProductPaymentType)type
                 completion:(EPPurchaseCompletionHandle)completionHandle;

#pragma mark - Restore

//restore
+ (void)restorePurchaseWithCompletion:(EPRestoreCompletionHandle)completionHandle;

@end

