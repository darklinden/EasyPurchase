//
//  C_IapObserver.m
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/18/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import "C_IapObserver.h"
#import "C_IapConstants.h"

#if __has_feature(objc_arc)
#error 请在非ARC下编译此类。在工程属性-Build Phases-Compile Sources中选择此文件，添加-fno-objc-arc标记以移除ARC。
#endif

@interface C_IapObserver ()
@property (unsafe_unretained) id<C_IapObserverDelegate> delegate;
// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;

// Sent when transactions are removed from the queue (via finishTransaction:).
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions;

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error;

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue;

- (void)didFinishTransaction:(SKPaymentTransaction *)transaction error:(NSString *)errMsg;

@end

@implementation C_IapObserver
@synthesize delegate;

+ (id)observerWithDelegate:(id<C_IapObserverDelegate>)delegate
{
    C_IapObserver *pC_IapObserver = [[C_IapObserver alloc] init];
    [pC_IapObserver setDelegate:delegate];
    return [pC_IapObserver autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc
{
    delegate = nil;
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [super dealloc];
}

- (void)didFinishTransaction:(SKPaymentTransaction *)transaction error:(NSString *)errMsg
{
    if (errMsg) {
        if (delegate) {
            if ([delegate respondsToSelector:@selector(finishPurchase:error:)]) {
                [delegate finishPurchase:transaction.payment.productIdentifier error:errMsg];
            }
        }
    }
    else {
        if (delegate) {
            if ([delegate respondsToSelector:@selector(checkProduct:receipt:)]) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
                [delegate checkProduct:transaction.payment.productIdentifier receipt:nil];
#else
                [delegate checkProduct:transaction.payment.productIdentifier receipt:transaction.transactionReceipt];
#endif
            }
        }
    }
}

// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for(SKPaymentTransaction *transaction in transactions) {
        
		switch (transaction.transactionState) {
				
			case SKPaymentTransactionStatePurchasing:
            {
                // Item is still in the process of being purchased
                IAP_OBSERVER_LOG(@"\n");
                IAP_OBSERVER_LOG(@"productIdentifier %@", transaction.payment.productIdentifier);
                IAP_OBSERVER_LOG(@"SKPaymentTransactionStatePurchasing");
				break;
            }
                
			case SKPaymentTransactionStatePurchased:
            {
                // Item was successfully purchased!
                IAP_OBSERVER_LOG(@"\n");
                IAP_OBSERVER_LOG(@"productIdentifier %@", transaction.payment.productIdentifier);
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
                IAP_OBSERVER_LOG(@"transactionReceipt %@", transaction.transactionReceipt);
#endif
                IAP_OBSERVER_LOG(@"SKPaymentTransactionStatePurchased");
                
                //check if the payment is OK
                [self didFinishTransaction:transaction error:nil];
                
                // After customer has successfully received purchased content,
				// remove the finished transaction from the payment queue.
				[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
				break;
            }
				
			case SKPaymentTransactionStateRestored:
            {
                // Verified that user has already paid for this item.
                IAP_OBSERVER_LOG(@"\n");
                IAP_OBSERVER_LOG(@"productIdentifier %@", transaction.payment.productIdentifier);
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
                IAP_OBSERVER_LOG(@"transactionReceipt %@", transaction.transactionReceipt);
#endif
                IAP_OBSERVER_LOG(@"SKPaymentTransactionStateRestored");
				
                //check if the payment is OK
                [self didFinishTransaction:transaction error:nil];
                
				// After customer has restored purchased content on this device,
				// remove the finished transaction from the payment queue.
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
				break;
            }
                
			case SKPaymentTransactionStateFailed:
            {
                // Purchase was either cancelled by user or an error occurred.
                IAP_OBSERVER_LOG(@"\n");
                IAP_OBSERVER_LOG(@"productIdentifier %@", transaction.payment.productIdentifier);
				IAP_OBSERVER_LOG(@"SKPaymentTransactionStateFailed");
                
                NSString *pStr_msg = nil;
                
                switch (transaction.error.code) {
                        
                    case SKErrorPaymentCancelled:
                    {
                        // user cancelled the request, etc.
                        pStr_msg = IAP_LOCALSTR_SKErrorPaymentCancelled;
                        break;
                    }
                        
                    case SKErrorUnknown:
                    {
                        // A transaction error occurred, so notify user.
                        pStr_msg = IAP_LOCALSTR_SKErrorUnknown;
                        break;
                    }
                        
                    case SKErrorClientInvalid:
                    {
                        // client is not allowed to issue the request, etc.
                        pStr_msg = IAP_LOCALSTR_SKErrorClientInvalid;
                        break;
                    }
                        
                    case SKErrorPaymentInvalid:
                    {
                        // purchase identifier was invalid, etc.
                        pStr_msg = IAP_LOCALSTR_SKErrorPaymentInvalid;
                        break;
                    }
                        
                    case SKErrorPaymentNotAllowed:
                    {
                        // this device is not allowed to make the payment
                        pStr_msg = IAP_LOCALSTR_SKErrorPaymentNotAllowed;
                        break;
                    }
                        
                    case SKErrorStoreProductNotAvailable:
                    {
                        // Product is not available in the current storefront
                        pStr_msg = IAP_LOCALSTR_SKErrorStoreProductNotAvailable;
                        break;
                    }
                        
                    default:
                        break;
                }
                
                [self didFinishTransaction:transaction error:pStr_msg];
                
				// Finished transactions should be removed from the payment queue.
				[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
				break;
            }
		}
	}
}

// Sent when transactions are removed from the queue (via finishTransaction:).
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    IAP_OBSERVER_LOG(@"removedTransactions");
    for (SKPaymentTransaction *transaction in transactions) {
        IAP_OBSERVER_LOG(@"removedTransaction %@", transaction.payment.productIdentifier);
    }
}

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    IAP_OBSERVER_LOG(@"restoreCompletedTransactionsFailedWithError: %@", error);
    NSString *pStr_msg = error.localizedDescription;
    if (delegate) {
        if ([delegate respondsToSelector:@selector(finishRestoreWithError:)]) {
            [delegate finishRestoreWithError:pStr_msg];
        }
    }
}

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    IAP_OBSERVER_LOG(@"paymentQueueRestoreCompletedTransactionsFinished");
    if (delegate) {
        if ([delegate respondsToSelector:@selector(finishRestoreWithError:)]) {
            [delegate finishRestoreWithError:nil];
        }
    }
}

@end
