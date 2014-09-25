//
//  ViewController.h
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/18/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VC_selectProduct.h"

//// user cancelled the request, etc.
//#define IAP_LOCALSTR_SKErrorPaymentCancelled            @"IAP_LOCALSTR_SKErrorPaymentCancelled"
//
//// A transaction error occurred, so notify user.
//#define IAP_LOCALSTR_SKErrorUnknown                     NSLocalizedString(@"IAP_LOCALSTR_SKErrorUnknown", @"")
//
//// client is not allowed to issue the request, etc.
//#define IAP_LOCALSTR_SKErrorClientInvalid               NSLocalizedString(@"IAP_LOCALSTR_SKErrorClientInvalid", @"")
//
//// purchase identifier was invalid, etc.
//#define IAP_LOCALSTR_SKErrorPaymentInvalid              NSLocalizedString(@"IAP_LOCALSTR_SKErrorPaymentInvalid", @"")
//
//// this device is not allowed to make the payment
//#define IAP_LOCALSTR_SKErrorPaymentNotAllowed           NSLocalizedString(@"IAP_LOCALSTR_SKErrorPaymentNotAllowed", @"")
//
//// Product is not available in the current storefront
//#define IAP_LOCALSTR_SKErrorStoreProductNotAvailable    NSLocalizedString(@"IAP_LOCALSTR_SKErrorStoreProductNotAvailable", @"")
//
////get product failed
//#define IAP_LOCALSTR_GetProductFailed                   NSLocalizedString(@"IAP_LOCALSTR_GetProductFailed", @"")
//
////check receipt failed
//#define IAP_LOCALSTR_CheckReceiptFailed                 NSLocalizedString(@"IAP_LOCALSTR_CheckReceiptFailed", @"")
//
////check receipt network failed
//#define IAP_LOCALSTR_CheckReceiptNetWorkFailed          NSLocalizedString(@"IAP_LOCALSTR_CheckReceiptNetWorkFailed", @"")
//
////inapppurchase dead lock
//#define IAP_LOCALSTR_InAppPurchaseDeadLock              NSLocalizedString(@"IAP_LOCALSTR_InAppPurchaseDeadLock", @"")
//
////restore success but get nothing restored
//#define IAP_LOCALSTR_RestoreGetEmptyArray               NSLocalizedString(@"IAP_LOCALSTR_RestoreGetEmptyArray", @"")

@interface ViewController : UIViewController <UIAlertViewDelegate, VC_selectProductDelegate>
@end
