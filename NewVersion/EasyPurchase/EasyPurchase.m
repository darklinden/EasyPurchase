//
//  EasyPurchase.m
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import "EasyPurchase.h"
#import "EPProductInfo.h"
#import "EPPurchaseObserver.h"
#import "EPReceiptChecker.h"

@implementation EasyPurchase

#pragma mark - product info
//request products informations
+ (void)requestProductsByIds:(NSArray *)productIds completion:(EPProductInfoCompletionHandle)completionHandle
{
    [EPProductInfo requestProductsByIds:productIds completion:completionHandle];
}

#pragma mark - Non-Consumable

+ (NSString *)getSecureValueForKey:(NSString *)key
{
    /*
     Return a value from the keychain
     */
    
    // Retrieve a value from the keychain
    NSArray *keys = [[NSArray alloc] initWithObjects: (__bridge NSString *)kSecClass, kSecAttrAccount, kSecReturnAttributes, nil];
    NSArray *objects = [[NSArray alloc] initWithObjects: (__bridge NSString *)kSecClassGenericPassword, key, kCFBooleanTrue, nil];
    NSDictionary *query = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
    
    // Check if the value was found
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != noErr) {
        // Value not found
        return nil;
    }
    else {
        NSDictionary *dict_result = (__bridge NSDictionary *)(result);
        // Value was found so return it
        NSString *value = nil;
        if ([dict_result objectForKey: (__bridge NSString *) kSecAttrGeneric]) {
            value = [NSString stringWithString:(NSString *) [dict_result objectForKey: (__bridge NSString *) kSecAttrGeneric]];
        }
        return value;
    }
}

+ (BOOL)storeSecureValue:(NSString *)value forKey:(NSString *)key
{
    /*
     Store a value in the keychain or remove the value by set it to nil
     */
    
    // Get the existing value for the key
    NSString *existingValue = [self getSecureValueForKey:key];
    
    OSStatus status = noErr;
    // Check if a value already exists for this key
    if (existingValue) {
        if (value) {
            // Value already exists, so update it
            NSArray *keys = [[NSArray alloc] initWithObjects:(__bridge NSString *) kSecClass, kSecAttrAccount, nil];
            NSArray *objects = [[NSArray alloc] initWithObjects:(__bridge NSString *) kSecClassGenericPassword, key, nil];
            NSDictionary *query = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
            status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObject:value forKey:(__bridge NSString *)kSecAttrGeneric]);
        }
        else {
            //value should be removed
            NSArray *keys = [[NSArray alloc] initWithObjects:(__bridge NSString *)kSecClass, kSecAttrAccount, kSecReturnAttributes, nil];
            NSArray *objects = [[NSArray alloc] initWithObjects:(__bridge NSString *)kSecClassGenericPassword, key, kCFBooleanTrue, nil];
            NSDictionary *query = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
            status = SecItemDelete((__bridge CFDictionaryRef)query);
        }
    }
    else {
        if (value) {
            // Value does not exist, so add it
            NSArray *keys = [[NSArray alloc] initWithObjects:(__bridge NSString *)kSecClass, kSecAttrAccount, kSecAttrGeneric, nil];
            NSArray *objects = [[NSArray alloc] initWithObjects:(__bridge NSString *)kSecClassGenericPassword, key, value, nil];
            NSDictionary *query = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
            status = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
        }
    }
    
    // Check if the value was stored
    if (status != noErr) {
        // Value was not stored
        return NO;
    } else {
        // Value was stored
        return YES;
    }
}

+ (BOOL)isPurchased:(NSString *)productId
{
    int64_t intKeyCount = [[self getSecureValueForKey:IAP_SECURE_VALUE_COUNT_KEY] longLongValue];
    if (intKeyCount > 0) {
        BOOL isSubscribed = NO;
        for (int64_t i = 0; i < intKeyCount; i++) {
            NSString *pStr_key = [NSString stringWithFormat:IAP_SECURE_VALUE_KEY_FORMAT, i];
            NSString *pStr_product = [self getSecureValueForKey:pStr_key];
            if ([productId isEqualToString:pStr_product]) {
                isSubscribed = YES;
                break;
            }
        }
        return isSubscribed;
    }
    else {
        return NO;
    }
}

+ (void)savePurchase:(NSString *)productId
{
    NSString *pStr_count = [self getSecureValueForKey:IAP_SECURE_VALUE_COUNT_KEY];
    int64_t intKeyCount = [pStr_count integerValue];
    if (intKeyCount > 0) {
        BOOL isSubscribed = NO;
        for (int64_t i = 0; i < intKeyCount; i++) {
            NSString *pStr_key = [NSString stringWithFormat:IAP_SECURE_VALUE_KEY_FORMAT, i];
            NSString *pStr_product = [self getSecureValueForKey:pStr_key];
            if ([productId isEqualToString:pStr_product]) {
                isSubscribed = YES;
                break;
            }
        }
        
        if (!isSubscribed) {
            [self storeSecureValue:productId forKey:[NSString stringWithFormat:IAP_SECURE_VALUE_KEY_FORMAT, intKeyCount]];
            intKeyCount++;
            [self storeSecureValue:[NSString stringWithFormat:@"%lld", intKeyCount] forKey:IAP_SECURE_VALUE_COUNT_KEY];
        }
    }
    else {
        intKeyCount = 0;
        [self storeSecureValue:productId forKey:[NSString stringWithFormat:IAP_SECURE_VALUE_KEY_FORMAT, intKeyCount]];
        intKeyCount++;
        [self storeSecureValue:[NSString stringWithFormat:@"%lld", intKeyCount] forKey:IAP_SECURE_VALUE_COUNT_KEY];
    }
}

//single purchase
+ (void)nonConsumablePurchase:(SKProduct *)product completion:(EPPurchaseCompletionHandle)completionHandle
{
    [EPPurchaseObserver purchase:product completion:^(NSString *productId, NSString *transactionId, NSString *errMsg) {
        if (errMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandle) {
                    completionHandle(productId, nil, errMsg);
                }
            });
        }
        else {
            [EPReceiptChecker checkReceiptWithCompletion:^(NSArray *passedProducts, NSString *errMsg) {
                if (errMsg) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completionHandle) {
                            completionHandle(productId, nil, errMsg);
                        }
                    });
                }
                else {
                    BOOL match = NO;
                    for (NSDictionary *dict in passedProducts) {
                        NSString *pid = dict[@"product_id"];
                        NSString *tid = dict[@"transaction_id"];
                        
                        if ([productId isEqualToString:pid] && [transactionId isEqualToString:tid]) {
                            match = YES;
                            break;
                        }
                    }
                    
                    if (match) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completionHandle) {
                                completionHandle(productId, transactionId, nil);
                            }
                        });
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completionHandle) {
                                completionHandle(productId, nil, IAP_LOCALSTR_CheckReceiptFailed);
                            }
                        });
                    }
                }
            }];
        }
    }];
}

//single purchase
+ (void)nonConsumablePurchaseProductById:(NSString *)productId completion:(EPPurchaseCompletionHandle)completionHandle
{
    //get product by id
    [EPProductInfo requestProductsByIds:@[productId] completion:^(NSArray *responseProducts) {
        
        SKProduct *product = nil;
        for (SKProduct *p in responseProducts) {
            if ([p.productIdentifier isEqualToString:productId]) {
                product = p;
                break;
            }
        }
        
        if (!product) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandle) {
                    completionHandle(productId, nil, IAP_LOCALSTR_GetProductFailed);
                }
            });
        }
        else {
            [self nonConsumablePurchase:product completion:completionHandle];
        }
    }];
}

//restore
+ (void)restorePurchaseWithCompletion:(EPRestoreCompletionHandle)completionHandle
{
    [EPPurchaseObserver restorePurchaseWithCompletion:^(NSArray *restoredProducts, NSString *errMsg) {
        if (errMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandle) {
                    completionHandle(nil, errMsg);
                }
            });
        }
        else {
            if (!restoredProducts.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionHandle) {
                        completionHandle(nil, IAP_LOCALSTR_RestoreGetEmptyArray);
                    }
                });
            }
            else {
                [EPReceiptChecker checkReceiptWithCompletion:^(NSArray *passedProducts, NSString *errMsg) {
                    
                    NSMutableArray *result = [NSMutableArray array];
                    for (NSDictionary *dr in restoredProducts) {
                        for (NSDictionary *dp in passedProducts) {
                            NSString *rpid = dr[@"product_id"];
                            NSString *rtid = dr[@"transaction_id"];
                            
                            NSString *ppid = dp[@"product_id"];
                            NSString *ptid = dp[@"transaction_id"];
                            
                            if ([rpid isEqualToString:ppid] && [rtid isEqualToString:ptid]) {
//                                NSDictionary *dict = @{@"product_id": ppid,
//                                                       @"transaction_id": ptid};
                                [result addObject:ppid];
                            }
                        }
                    }
                    
                    if (result.count) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completionHandle) {
                                completionHandle(result, nil);
                            }
                        });
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completionHandle) {
                                completionHandle(nil, IAP_LOCALSTR_RestoreGetEmptyArray);
                            }
                        });
                    }
                }];
            }
        }
    }];
}

#pragma mark - Consumable

+ (void)consumablePurchase:(SKProduct *)product completion:(EPPurchaseCompletionHandle)completionHandle
{
    [EPPurchaseObserver purchase:product completion:completionHandle];
}

+ (void)consumablePurchaseProductById:(NSString *)productId completion:(EPPurchaseCompletionHandle)completionHandle
{
    [EPProductInfo requestProductsByIds:@[productId] completion:^(NSArray *responseProducts) {
        
        SKProduct *product = nil;
        for (SKProduct *p in responseProducts) {
            if ([p.productIdentifier isEqualToString:productId]) {
                product = p;
                break;
            }
        }
        
        if (!product) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandle) {
                    completionHandle(productId, nil, IAP_LOCALSTR_GetProductFailed);
                }
            });
        }
        else {
            [self consumablePurchase:product completion:completionHandle];
        }
    }];
}

+ (void)checkReceiptForProduct:(NSString *)productId transaction:(NSString *)transactionId completion:(EPConsumableReceiptCheckerCompletionHandle)completionHandle
{
    [EPReceiptChecker checkReceiptWithCompletion:^(NSArray *passedProducts, NSString *errMsg) {
        if (errMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandle) {
                    completionHandle(productId, transactionId, errMsg);
                }
            });
        }
        else {
            BOOL match = NO;
            for (NSDictionary *dict in passedProducts) {
                NSString *pid = dict[@"product_id"];
                NSString *tid = dict[@"transaction_id"];
                
                if ([productId isEqualToString:pid] && [transactionId isEqualToString:tid]) {
                    match = YES;
                    break;
                }
            }
            
            if (match) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionHandle) {
                        completionHandle(productId, transactionId, nil);
                    }
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionHandle) {
                        completionHandle(productId, transactionId, IAP_LOCALSTR_CheckReceiptFailed);
                    }
                });
            }
        }
    }];
}


@end