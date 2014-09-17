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

#warning use apple webservice check to validate receipt, may should be rewrite after ios8 release
#warning local validation solution on https://github.com/robotmedia/RMStore may works, but I think this is not the last solution, waiting for apple doc

+ (void)checkReceiptWithCompletion:(EPReceiptCheckerCompletionHandle)completionHandle;

@end
