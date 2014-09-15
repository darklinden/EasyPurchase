//
//  C_IapCheck.h
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/18/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import <Foundation/Foundation.h>

@class C_IapCheck;

@protocol C_IapCheckDeleate <NSObject>
@required
- (void)C_IapCheck:(C_IapCheck *)sender products:(NSArray *)products error:(NSString *)errMsg;
@end

@interface C_IapCheck : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

+ (id)checkReceipt:(NSData *)receipt
           product:(NSString *)product
          delegate:(id<C_IapCheckDeleate>)delegate;

- (void)start;

- (void)cancel;

@end
