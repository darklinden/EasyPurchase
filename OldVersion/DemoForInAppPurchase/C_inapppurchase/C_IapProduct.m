//
//  C_IapProduct.m
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/18/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import "C_IapProduct.h"
#import "C_IapConstants.h"

#if __has_feature(objc_arc)
#error 请在非ARC下编译此类。在工程属性-Build Phases-Compile Sources中选择此文件，添加-fno-objc-arc标记以移除ARC。
#endif

@interface C_IapProduct ()
@property (unsafe_unretained) id<C_IapProductDelegate>  delegate;
@property (strong, nonatomic) NSArray                   *pArr_product_ids;
@property (strong, nonatomic) NSArray                   *pArr_products;
@property (strong, nonatomic) SKProductsRequest         *pProductRequest;

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response;
- (void)requestDidFinish:(SKRequest *)request;
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error;
- (void)start;
@end

@implementation C_IapProduct

- (void)dealloc
{
    _delegate = nil;
    [_pArr_product_ids release],    _pArr_product_ids = nil;
    [_pArr_products release],       _pArr_products = nil;
    [_pProductRequest release],     _pProductRequest = nil;
    [super dealloc];
}

+ (id)requestProductsByIds:(NSArray *)product_ids delegate:(id<C_IapProductDelegate>)delegate
{
    C_IapProduct *pC_IapProduct = [[C_IapProduct alloc] init];
    [pC_IapProduct setDelegate:delegate];
    pC_IapProduct.pArr_product_ids = product_ids;
    [pC_IapProduct start];
    return [pC_IapProduct autorelease];
}

- (void)start
{
    self.pArr_products = nil;
    self.pProductRequest = [[[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:self.pArr_product_ids]] autorelease];
    [self.pProductRequest setDelegate:self];
    [self.pProductRequest start];
}

- (void)productRequestFinish
{
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(C_IapProduct:products:)]) {
            [self.delegate C_IapProduct:self products:self.pArr_products];
        }
    }
}

// Sent immediately before -requestDidFinish:
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	int count = [response.products count];
	if (count > 0) {
		self.pArr_products = response.products;
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
