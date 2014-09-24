//
//  EPPurchaseObserver.m
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import "EPPurchaseObserver.h"
#import "ObjHolder.h"

@interface EPPurchaseObserver () <SKPaymentTransactionObserver>{
    EPPurchaseCompletionHandle  _purchaseCompletionHandle;
    EPRestoreCompletionHandle   _restoreCompletionHandle;
}


typedef enum : NSUInteger {
    EPObserverTypePurchase,
    EPObserverTypeRestore
} EPObserverType;

@property (nonatomic, strong) NSString                  *ticket;

@property (nonatomic, assign) EPObserverType            obType;
@property (nonatomic, assign) SKProductPaymentType      payType;
@property (nonatomic, strong) NSString                  *purchaseProductId;
@property (nonatomic, strong) NSMutableArray            *restoredProducts;

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
#if IAP_Check_DeadLock
    //any time when you start a purchase or restore, if there's any transactions in payment queue there may be a great chance to be a dead lock like "purchase has made but didn't download" and cause "user canceled"
    //this check may also cause dead lock if there already has
    return !![[[SKPaymentQueue defaultQueue] transactions] count];
#else
    return NO;
#endif
}

+ (void)purchase:(SKProduct *)product type:(SKProductPaymentType)type completion:(EPPurchaseCompletionHandle)completionHandle
{
    if (![SKPaymentQueue canMakePayments]) {
        if (completionHandle) {
            completionHandle(product.productIdentifier, nil, EPErrorPaymentNotAllowed);
        }
    }
    else if ([self hasDeadLock]) {
        if (completionHandle) {
            completionHandle(product.productIdentifier, nil, EPErrorQueueDeadLock);
        }
    }
    else {
        EPPurchaseObserver *ob = [[EPPurchaseObserver alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:ob];
        
        //ob should be Singleton
        ob.ticket = [[ObjHolder sharedHolder] pushObject:ob];
        ob.obType = EPObserverTypePurchase;
        ob.payType = type;
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
            completionHandle(nil, EPErrorQueueDeadLock);
        }
    }
    else {
        EPPurchaseObserver *ob = [[EPPurchaseObserver alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:ob];
        
        //ob should be Singleton
        ob.ticket = [[ObjHolder sharedHolder] pushObject:ob];
        ob.obType = EPObserverTypeRestore;
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

- (void)doFinishTransaction:(SKPaymentTransaction *)transaction error:(EPError)err
{
    if (transaction.transactionState == SKPaymentTransactionStatePurchased
        || transaction.transactionState == SKPaymentTransactionStateRestored) {
        IAP_OBSERVER_LOG(@"transaction id: %@, original transaction id: %@", transaction.transactionIdentifier, transaction.originalTransaction.transactionIdentifier);    
    }
    
    switch (_obType) {
        case EPObserverTypePurchase:
        {
            if ([transaction.payment.productIdentifier isEqualToString:_purchaseProductId]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_purchaseCompletionHandle) {
                        if (transaction.originalTransaction) {
                            _purchaseCompletionHandle(transaction.payment.productIdentifier,
                                                      transaction.originalTransaction.transactionIdentifier,
                                                      err);
                        }
                        else {
                            _purchaseCompletionHandle(transaction.payment.productIdentifier, transaction.transactionIdentifier, err);
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
        case EPObserverTypeRestore:
        {
            if (EPErrorSuccess == err) {
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
                
            case SKPaymentTransactionStateDeferred:
            {
                if (_obType == EPObserverTypePurchase && _payType == SKProductPaymentTypeNonConsumable) {
#if IAP_Check_TransactionDeferred
                    //if non-consumable purchase, deal as user cancelled and
                    [self doFinishTransaction:transaction error:EPErrorTransactionDeferred];
#endif
                }
                IAP_OBSERVER_LOG(@"\n");
                IAP_OBSERVER_LOG(@"productIdentifier %@", transaction.payment.productIdentifier);
                IAP_OBSERVER_LOG(@"SKPaymentTransactionStateDeferred");
                break;
            }
				
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
                [self doFinishTransaction:transaction error:EPErrorSuccess];
                
				break;
            }
				
			case SKPaymentTransactionStateRestored:
            {
                // Verified that user has already paid for this item.
                IAP_OBSERVER_LOG(@"\n");
                IAP_OBSERVER_LOG(@"productIdentifier %@", transaction.payment.productIdentifier);
                IAP_OBSERVER_LOG(@"SKPaymentTransactionStateRestored");
				
                //check if the payment is OK
                [self doFinishTransaction:transaction error:EPErrorSuccess];
                
				break;
            }
                
			case SKPaymentTransactionStateFailed:
            {
                // Purchase was either cancelled by user or an error occurred.
                IAP_OBSERVER_LOG(@"\n");
                IAP_OBSERVER_LOG(@"productIdentifier %@", transaction.payment.productIdentifier);
				IAP_OBSERVER_LOG(@"SKPaymentTransactionStateFailed");
                
                EPError err = EPErrorSuccess;
                
                switch (transaction.error.code) {
                        
                    case SKErrorPaymentCancelled:
                    {
                        // user cancelled the request, etc.
                        err = EPErrorCancelled;
                        break;
                    }
                        
                    case SKErrorUnknown:
                    {
                        // A transaction error occurred, so notify user.
                        err = EPErrorUnknown;
                        break;
                    }
                        
                    case SKErrorClientInvalid:
                    {
                        // client is not allowed to issue the request, etc.
                        err = EPErrorClientInvalid;
                        break;
                    }
                        
                    case SKErrorPaymentInvalid:
                    {
                        // purchase identifier was invalid, etc.
                        err = EPErrorPaymentInvalid;
                        break;
                    }
                        
                    case SKErrorPaymentNotAllowed:
                    {
                        // this device is not allowed to make the payment
                        err = EPErrorPaymentNotAllowed;
                        break;
                    }
                        
                    case SKErrorStoreProductNotAvailable:
                    {
                        // Product is not available in the current storefront
                        err = EPErrorProductNotAvailable;
                        break;
                    }
                        
                    default:
                        break;
                }
                
                [self doFinishTransaction:transaction error:err];
                
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
    
    if (_obType == EPObserverTypeRestore) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_restoreCompletionHandle) {
                _restoreCompletionHandle([_restoredProducts copy], EPErrorRestoreError);
            }
            
            [self clean];
        });
        
    }
}

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    IAP_OBSERVER_LOG(@"paymentQueueRestoreCompletedTransactionsFinished");
    
    if (_obType == EPObserverTypeRestore) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_restoreCompletionHandle) {
                _restoreCompletionHandle([_restoredProducts copy], EPErrorSuccess);
            }
            
            [self clean];
        });
    }
}


@end
