//
//  C_IapConstants.h
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/18/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#ifndef DemoForInAppPurchase_C_IapConstants_h
#define DemoForInAppPurchase_C_IapConstants_h

#define IAP_JSON_FORMAT                     @"{\"receipt-data\":\"%@\"}"
#define IAP_SUBSCRIBE_FAILED_SANDBOX        @"21007"
#define IAP_SUBSCRIBE_SUCCESS               @"0"
#define IAP_SANDBOX_URL                     @"https://sandbox.itunes.apple.com/verifyReceipt"
#define IAP_PRODUCT_URL                     @"https://buy.itunes.apple.com/verifyReceipt"
#define IAP_RECEIPT_TIMEOUT                 10.f

#define IAP_USER_DEFAULT_FIRST_RUN          @"IAP_USER_DEFAULT_FIRST_RUN"
#define IAP_SECURE_VALUE_COUNT_KEY          @"IAP_SECURE_VALUE_COUNT_KEY"
#define IAP_SECURE_VALUE_KEY_FORMAT         @"IAP_SECURE_VALUE_KEY_%d"

#define IAP_OBSERVER_LOG( s, ... )          while (DEBUG) { NSLog(@"%@", [NSString stringWithFormat:(s), ##__VA_ARGS__]); }
#define IAP_PRODUCT_LOG( s, ... )           while (DEBUG) { NSLog(@"%@", [NSString stringWithFormat:(s), ##__VA_ARGS__]); }
#define IAP_CHECK_LOG( s, ... )             while (DEBUG) { NSLog(@"%@", [NSString stringWithFormat:(s), ##__VA_ARGS__]); }
#define IAP_CONTROLLER_LOG( s, ... )        while (DEBUG) { NSLog(@"%@", [NSString stringWithFormat:(s), ##__VA_ARGS__]); }

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

//error message
//chs:
//
//// A transaction error occurred, so notify user.
//"IAP_LOCALSTR_SKErrorUnknown" = "购买时出现未知错误，请尝试重新购买。";
//
//// client is not allowed to issue the request, etc.
//"IAP_LOCALSTR_SKErrorClientInvalid" = "此次购买请求被服务器拒绝，请尝试重新购买。";
//
//// purchase identifier was invalid, etc.
//"IAP_LOCALSTR_SKErrorPaymentInvalid" = "购买请求的编码不正确，请尝试重新购买。如果此错误多次发生，请联系我们。";
//
//// this device is not allowed to make the payment
//"IAP_LOCALSTR_SKErrorPaymentNotAllowed" = "该设备不支持程序内购买商品，请检查设备是否已被锁定。";
//
//// Product is not available in the current storefront
//"IAP_LOCALSTR_SKErrorStoreProductNotAvailable" = "此商品已从App Stroe下架。";
//
////get product failed
//"IAP_LOCALSTR_GetProductFailed" = "获取商品信息失败，请检查网络状态。";
//
////check receipt failed
//"IAP_LOCALSTR_CheckReceiptFailed" = "购买失败，请尝试重新购买。";
//
////restore success but no product
//"IAP_LOCALSTR_RestoreSuccessButNoProduct" = "购买失败，请尝试重新购买。";
//en:
//// A transaction error occurred, so notify user.
//"IAP_LOCALSTR_SKErrorUnknown" = "Sorry. We have encountered an unexpected error. Please try again later.";
//
//// client is not allowed to issue the request, etc.
//"IAP_LOCALSTR_SKErrorClientInvalid" = "Sorry. Your purchase request was declined by App Store. Please try again later.";
//
//// purchase identifier was invalid, etc.
//"IAP_LOCALSTR_SKErrorPaymentInvalid" = "Sorry. The product info was invalid. Please try again later. If this error occurs again, please contact us.";
//
//// this device is not allowed to make the payment
//"IAP_LOCALSTR_SKErrorPaymentNotAllowed" = "Sorry. Your device is not allowed to make purchases. Please check the Settings and try again.";
//
//// Product is not available in the current storefront
//"IAP_LOCALSTR_SKErrorStoreProductNotAvailable" = "Sorry. The product is currently not available in App Store.";
//
////get product failed
//"IAP_LOCALSTR_GetProductFailed" = "Sorry. The App failed to get the product info. Please check your internet connection and try again later.";
//
////check receipt failed
//"IAP_LOCALSTR_CheckReceiptFailed" = "Sorry. Your purchase failed. Please try again later.";

#endif
