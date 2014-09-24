//
//  EPProductInfo.m
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import "EPProductInfo.h"
#import "ObjHolder.h"

@interface EPProductInfo () <SKProductsRequestDelegate> {
    EPProductInfoCompletionHandle _completionHandle;
}
@property (nonatomic, strong) NSString              *ticket;
@property (nonatomic, strong) NSArray               *requestProductIds;
@property (nonatomic, strong) NSArray               *responseProducts;
@property (nonatomic, strong) SKProductsRequest     *request;

@end

@implementation EPProductInfo

+ (void)requestProductsByIds:(NSArray *)productIds completion:(EPProductInfoCompletionHandle)completionHandle
{
    EPProductInfo *pEPProductInfo = [[EPProductInfo alloc] init];
    pEPProductInfo.ticket = [[ObjHolder sharedHolder] pushObject:pEPProductInfo];
    pEPProductInfo.requestProductIds = productIds;
    pEPProductInfo->_completionHandle = completionHandle;
    [pEPProductInfo start];
}

- (void)dealloc
{
    _completionHandle = nil;
    self.ticket = nil;
    self.requestProductIds = nil;
    self.responseProducts = nil;
    self.request = nil;
}

- (void)start
{
    self.responseProducts = nil;
    self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:self.requestProductIds]];
    [self.request setDelegate:self];
    [self.request start];
}

- (void)productRequestFinish
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_completionHandle) {
            _completionHandle([self.requestProductIds copy], [self.responseProducts copy]);
        }
        
        [[ObjHolder sharedHolder] popObjectWithTicket:_ticket];
    });
}

// Sent immediately before -requestDidFinish:
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	if (response.products.count > 0) {
		self.responseProducts = response.products;
	}
    [request cancel];
}

- (void)requestDidFinish:(SKRequest *)request
{
    IAP_PRODUCT_LOG(@"requestDidFinish");
    [self productRequestFinish];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    IAP_PRODUCT_LOG(@"didFailWithError:%@", error);
    [self productRequestFinish];
}


@end
