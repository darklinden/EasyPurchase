//
//  EPReceiptChecker.h
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EasyPurchase.h"

@interface EPTransactionProduct : NSObject
@property(nonatomic,    copy) NSString  *product_id;
@property(nonatomic,    copy) NSString  *transaction_id;
@property(nonatomic,    copy) NSString  *original_transaction_id;
@property(nonatomic,    copy) NSDate    *purchase_date;
@property(nonatomic,    copy) NSDate    *original_purchase_date;
@property(nonatomic,    copy) NSDate    *expires_date;
@property(nonatomic,    copy) NSDate    *cancellation_date;
@property(nonatomic,  assign) NSInteger quantity;
@property(nonatomic,  assign) NSInteger web_order_line_item_id;

@end

@interface EPReceiptChecker : NSObject

//https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Introduction.html#//apple_ref/doc/uid/TP40010573

//local validation https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW2
//receipt field
//https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1

//https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW2


//https://developer.apple.com/videos/wwdc/2014/
/*
 "Preventing Unauthorized Purchases with Receipts"
 pdf has been downloaded and added to repository
 
 Allows your servers to validate the receipt before issuing content
 Your app sends the receipt to your servers
 Your server sends the receipt to Apple’s server
 Never send the receipt directly from your app to Apple’s server  -> server check from app is not safe
 */


//https://github.com/rmaddy/VerifyStoreReceiptiOS a demo for receipt parse and check, get a lot of useful code


//https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW5
/*
 Consumable Products and Non-Renewing Subscriptions: The in-app purchase receipt for a consumable product or a non-renewing subscription is added to the receipt when the purchase is made. It is kept in the receipt until your app finishes that transaction. After that point, it is removed from the receipt the next time the receipt is updated—for example, when the user makes another purchase or if your app explicitly refreshes the receipt.

 so, refresh non-consumable if invalid, do not refresh receipt if consumable
 */

// check with client to apple server is not safe, use local check instead

+ (void)checkReceiptWithBundleId:(const NSString *)bundleId
                         version:(const NSString *)version
                     refreshable:(BOOL)refreshable
                      completion:(EPReceiptCheckerCompletionHandle)completionHandle;

@end
