//
//  EPPurchaseObserver.m
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import "EPPurchaseObserver.h"
#import "ObjHolder.h"

//NS_ENUM(u_int64_t, EPPurchaseType) {
//    EPPurchaseTypePurchase,
//    EPPurchaseTypeRestore
//};

typedef enum : NSUInteger {
    EPPurchaseTypePurchase,
    EPPurchaseTypeRestore
} EPPurchaseType;

@interface EPPurchaseObserver () <SKPaymentTransactionObserver>{
    EPPurchaseCompletionHandle  _purchaseCompletionHandle;
    EPRestoreCompletionHandle   _restoreCompletionHandle;
}
@property (nonatomic, strong) NSString          *ticket;

@property (nonatomic, assign) EPPurchaseType    type;
@property (nonatomic, strong) NSString          *purchaseProductId;
@property (nonatomic, strong) NSMutableArray    *restoredProducts;

// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;

// Sent when transactions are removed from the queue (via finishTransaction:).
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions;

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error;

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue;

@end

@implementation EPPurchaseObserver

+ (BOOL)hasDeadLock
{
    return !![[[SKPaymentQueue defaultQueue] transactions] count];
}

+ (void)purchase:(SKProduct *)product completion:(EPPurchaseCompletionHandle)completionHandle
{
    if ([self hasDeadLock]) {
        if (completionHandle) {
            completionHandle(product.productIdentifier, nil, IAP_LOCALSTR_InAppPurchaseDeadLock);
        }
    }
    else {
        EPPurchaseObserver *ob = [[EPPurchaseObserver alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:ob];
        
        //ob should be Singleton
        ob.ticket = [[ObjHolder sharedHolder] pushObject:ob];
        ob.type = EPPurchaseTypePurchase;
        ob.purchaseProductId = product.productIdentifier;
        ob->_purchaseCompletionHandle = completionHandle;
        
        SKMutablePayment *pPayment = [SKMutablePayment paymentWithProduct:product];
        pPayment.quantity = 1;
        [[SKPaymentQueue defaultQueue] addPayment:pPayment];
    }
}

+ (void)restorePurchaseWithCompletion:(EPRestoreCompletionHandle)completionHandle;
{
    if ([self hasDeadLock]) {
        if (completionHandle) {
            completionHandle(nil, IAP_LOCALSTR_InAppPurchaseDeadLock);
        }
    }
    else {
        EPPurchaseObserver *ob = [[EPPurchaseObserver alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:ob];
        
        //ob should be Singleton
        ob.ticket = [[ObjHolder sharedHolder] pushObject:ob];
        ob.type = EPPurchaseTypeRestore;
        ob.restoredProducts = [NSMutableArray array];
        ob->_restoreCompletionHandle = completionHandle;
        
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
}

- (void)clean
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [[ObjHolder sharedHolder] popObjectWithTicket:_ticket];
}

- (void)doFinishTransaction:(SKPaymentTransaction *)transaction error:(NSString *)errMsg
{
    if (transaction.transactionState == SKPaymentTransactionStatePurchased
        || transaction.transactionState == SKPaymentTransactionStateRestored) {
        IAP_OBSERVER_LOG(@"transaction type:%d transaction id: %@, original transaction id: %@", transaction.transactionState, transaction.transactionIdentifier, transaction.originalTransaction.transactionIdentifier);    
    }
    
    switch (_type) {
        case EPPurchaseTypePurchase:
        {
            if ([transaction.payment.productIdentifier isEqualToString:_purchaseProductId]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_purchaseCompletionHandle) {
                        if (transaction.originalTransaction) {
                            _purchaseCompletionHandle(transaction.payment.productIdentifier, transaction.originalTransaction.transactionIdentifier, errMsg);
                        }
                        else {
                            _purchaseCompletionHandle(transaction.payment.productIdentifier, transaction.transactionIdentifier, errMsg);
                        }
                    }
                    
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    
                    [self clean];
                });
            }
            else {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
        }
            break;
        case EPPurchaseTypeRestore:
        {
            if (!errMsg) {
                if (transaction.originalTransaction) {
                    NSDictionary *dict = @{@"product_id": transaction.payment.productIdentifier,
                                           @"transaction_id": transaction.originalTransaction.transactionIdentifier};
                    [_restoredProducts addObject:dict];
                }
            }
            
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
            break;
        default:
            break;
    }
}

// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        
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
                IAP_OBSERVER_LOG(@"SKPaymentTransactionStatePurchased");
                
                //check if the payment is OK
                [self doFinishTransaction:transaction error:nil];
                
				break;
            }
				
			case SKPaymentTransactionStateRestored:
            {
                // Verified that user has already paid for this item.
                IAP_OBSERVER_LOG(@"\n");
                IAP_OBSERVER_LOG(@"productIdentifier %@", transaction.payment.productIdentifier);
                IAP_OBSERVER_LOG(@"SKPaymentTransactionStateRestored");
				
                //check if the payment is OK
                [self doFinishTransaction:transaction error:nil];
                
				break;
            }
                
			case SKPaymentTransactionStateFailed:
            {
                // Purchase was either cancelled by user or an error occurred.
                IAP_OBSERVER_LOG(@"\n");
                IAP_OBSERVER_LOG(@"productIdentifier %@", transaction.payment.productIdentifier);
				IAP_OBSERVER_LOG(@"SKPaymentTransactionStateFailed");
                
                NSString *errMsg = nil;
                
                switch (transaction.error.code) {
                        
                    case SKErrorPaymentCancelled:
                    {
                        // user cancelled the request, etc.
                        errMsg = IAP_LOCALSTR_SKErrorPaymentCancelled;
                        break;
                    }
                        
                    case SKErrorUnknown:
                    {
                        // A transaction error occurred, so notify user.
                        errMsg = IAP_LOCALSTR_SKErrorUnknown;
                        break;
                    }
                        
                    case SKErrorClientInvalid:
                    {
                        // client is not allowed to issue the request, etc.
                        errMsg = IAP_LOCALSTR_SKErrorClientInvalid;
                        break;
                    }
                        
                    case SKErrorPaymentInvalid:
                    {
                        // purchase identifier was invalid, etc.
                        errMsg = IAP_LOCALSTR_SKErrorPaymentInvalid;
                        break;
                    }
                        
                    case SKErrorPaymentNotAllowed:
                    {
                        // this device is not allowed to make the payment
                        errMsg = IAP_LOCALSTR_SKErrorPaymentNotAllowed;
                        break;
                    }
                        
                    case SKErrorStoreProductNotAvailable:
                    {
                        // Product is not available in the current storefront
                        errMsg = IAP_LOCALSTR_SKErrorStoreProductNotAvailable;
                        break;
                    }
                        
                    default:
                        break;
                }
                
                [self doFinishTransaction:transaction error:errMsg];
                
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
    
    if (_type == EPPurchaseTypeRestore) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_restoreCompletionHandle) {
                _restoreCompletionHandle([_restoredProducts copy], [error.localizedDescription copy]);
            }
            
            [self clean];
        });
        
    }
}

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    IAP_OBSERVER_LOG(@"paymentQueueRestoreCompletedTransactionsFinished");
    
    if (_type == EPPurchaseTypeRestore) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_restoreCompletionHandle) {
                _restoreCompletionHandle([_restoredProducts copy], nil);
            }
            
            [self clean];
        });
    }
}


@end
