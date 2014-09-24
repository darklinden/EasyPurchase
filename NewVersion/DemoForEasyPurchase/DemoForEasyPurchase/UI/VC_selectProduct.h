//
//  VC_selectProduct.h
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 11/9/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EasyPurchase.h"



@protocol VC_selectProductDelegate <NSObject>
- (void)didSelectProduct:(SKProduct *)product type:(SKProductPaymentType)type;
@end

@interface VC_selectProduct : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (unsafe_unretained) id<VC_selectProductDelegate> delegate;
@end
