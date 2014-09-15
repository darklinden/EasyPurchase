//
//  EPReceiptChecker.h
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^EPReceiptCheckerCompletionHandle)(NSArray *passedProducts, NSString *errMsg);

@interface EPReceiptChecker : NSObject

+ (id)checkReceiptWithCompletion:(EPReceiptCheckerCompletionHandle)completionHandle;

@end
