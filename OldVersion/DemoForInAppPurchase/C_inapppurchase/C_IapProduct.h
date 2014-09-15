//
//  C_IapProduct.h
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/18/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class C_IapProduct;

@protocol C_IapProductDelegate <NSObject>
@required
- (void)C_IapProduct:(C_IapProduct *)sender products:(NSArray *)products;
@end

@interface C_IapProduct : NSObject <SKProductsRequestDelegate>
+ (id)requestProductsByIds:(NSArray *)product_ids delegate:(id<C_IapProductDelegate>)delegate;
@end
