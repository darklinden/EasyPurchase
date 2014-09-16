//
//  ViewController.m
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/18/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "ViewController.h"
#import "VC_selectProduct.h"
#import "V_loading.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIButton     *pBtn_selectProduct;
@property (strong, nonatomic) SKProduct             *selectedProduct;
@property (assign, nonatomic) SKProductPaymentType  selectedProductType;

@property (strong, nonatomic) NSString              *purchasingProductId;
@property (strong, nonatomic) NSString              *purchasingTransactionId;

@end

@implementation ViewController

- (void)pBtn_cancel_clicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(pBtn_cancel_clicked:)];
    self.navigationItem.leftBarButtonItem = btn;
}

- (void)didSelectProduct:(SKProduct *)product type:(SKProductPaymentType)type
{
    self.selectedProduct = product;
    self.selectedProductType = type;
    [self.pBtn_selectProduct setTitle:product.productIdentifier forState:UIControlStateNormal];
}

- (IBAction)pBtn_selectProductClick:(id)sender
{
    VC_selectProduct *pVC_selectProduct = [[VC_selectProduct alloc] initWithNibName:@"VC_selectProduct" bundle:nil];
    pVC_selectProduct.delegate = self;
    UINavigationController *pNC_nav = [[UINavigationController alloc] initWithRootViewController:pVC_selectProduct];
    
    [self presentViewController:pNC_nav animated:YES completion:nil];
}

- (IBAction)pBtn_buyClick:(id)sender
{
    if (self.selectedProduct) {
        
        switch (_selectedProductType) {
            case SKProductPaymentTypeNonConsumable:
            {
                [V_loading showLoadingView:self.navigationController.view title:nil message:@"Non-Consumable Purchasing"];
                [EasyPurchase nonConsumablePurchase:self.selectedProduct completion:^(NSString *productId, NSString *transactionId, NSString *errMsg) {
                    
                    [V_loading removeLoading];
                    
                    NSString *message = nil;
                    
                    if (!errMsg) {
                        [EasyPurchase savePurchase:productId];
                        message = [NSString stringWithFormat:@"product %@ purchase success", productId];
                    }
                    else {
                        if ([errMsg isEqualToString:IAP_LOCALSTR_SKErrorPaymentCancelled]) {
                            //throw away
                            NSLog(@"user canceled. remove loading and do nothing.");
                        }
                        else {
                            message = [NSString stringWithFormat:@"product %@ purchase failed. error msg: %@", productId, errMsg];
                        }
                    }
                    
                    if (message) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alert show];
                    }
                }];
            }
                break;
            case SKProductPaymentTypeConsumable:
            {
                [V_loading showLoadingView:self.navigationController.view title:nil message:@"Consumable Purchasing"];
                [EasyPurchase consumablePurchase:self.selectedProduct completion:^(NSString *productId, NSString *transactionId, NSString *errMsg) {
                    if (errMsg) {
                        [V_loading removeLoading];
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                                        message:[NSString stringWithFormat:@"product %@ purchase failed. error msg: %@", productId, errMsg]
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alert show];
                    }
                    else {
                        [self checkPurchaseProduct:[productId copy] transaction:[transactionId copy]];
                    }
                }];
            }
                break;
            default:
                break;
        }
    }
}

- (void)checkPurchaseProduct:(NSString *)pid transaction:(NSString *)tid
{
    [V_loading showLoadingView:self.navigationController.view title:nil message:@"Consumable Purchase Validating"];
    [EasyPurchase checkReceiptForProduct:pid transaction:tid completion:^(NSString *productId, NSString *transactionId, NSString *errMsg) {
        [V_loading removeLoading];
        
        if (errMsg) {
            if ([errMsg isEqualToString:IAP_LOCALSTR_CheckReceiptFailed]) {
                
                self.purchasingProductId = nil;
                self.purchasingTransactionId = nil;
                
#warning need to save transaction id & product id for apple solution
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                                message:[NSString stringWithFormat:@"Product: %@ Transaction: %@ Validate failed. You may using illegal plugin to purchase. Please Close All plugins. If not, please Check your Bank Card, If you have had paid for the latest purchase, please send us your product id and transaction id, we'll contact you as soon as possible. ", pid, tid]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
            else {
                self.purchasingProductId = pid;
                self.purchasingTransactionId = tid;
                
#warning need to save transaction id & product id for recheck, if recheck does not continue, the purchase may failed but the money paid
                
                //check receipt network failed, recheck or not
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                                message:[NSString stringWithFormat:@"Product: %@ Transaction: %@ Validate failed.  Check your network and tap 'Retry' to retry. If this alert shows several times, please send us your product id and transaction id, we'll contact you as soon as possible.", pid, tid]
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
                [alert show];
            }
        }
        else {
            self.purchasingProductId = nil;
            self.purchasingTransactionId = nil;
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                            message:[NSString stringWithFormat:@"product %@ purchase success.", pid]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
    }];
}

- (IBAction)pBtn_restoreClick:(id)sender
{
    if (self.selectedProductType == SKProductPaymentTypeConsumable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"Consumable purchase is not able to restore!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    [V_loading showLoadingView:self.navigationController.view title:nil message:@"Non-Consumable Restoring"];
    [EasyPurchase restorePurchaseWithCompletion:^(NSArray *restoredProducts, NSString *errMsg) {
        
        [V_loading removeLoading];
        
        for (NSString *pid in restoredProducts) {
            [EasyPurchase savePurchase:pid];
        }
        
        NSString *messgae = [NSString stringWithFormat:@"Restored products: %@ error: %@", restoredProducts, errMsg];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:messgae delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }];
}

- (IBAction)pBtn_productClick:(id)sender
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.f) {
        [V_loading showLoadingView:self.navigationController.view title:nil message:nil];
        [self viewSellProduct:[NSNumber numberWithInt:413971331]];
    }
}

- (IBAction)pBtn_checkClick:(id)sender
{
    if (self.selectedProductType == SKProductPaymentTypeConsumable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"Consumable purchase is not able to check!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    if ([EasyPurchase isPurchased:self.pBtn_selectProduct.currentTitle]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"purchased" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
        [alert show];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"haven't purchased" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)viewSellProduct:(NSNumber*)appId
{
    SKStoreProductViewController *viewController = [[SKStoreProductViewController alloc] init];
    viewController.delegate = (id)self;
    NSDictionary *parameters = @{SKStoreProductParameterITunesItemIdentifier:appId};
    [viewController loadProductWithParameters:parameters completionBlock: ^(BOOL result, NSError *error) {
        [V_loading removeLoading];
        if (result) {
            [self presentViewController:viewController animated:YES completion:nil];
        }
        else {
            NSLog(@"description: %@", [error localizedDescription]);
            NSLog(@"failure reason: %@", [error localizedFailureReason]);
            NSLog(@"code: %ld", (long)[error code]);
        }
    }];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self checkPurchaseProduct:_purchasingProductId transaction:_purchasingTransactionId];
    }
    else {
        [V_loading removeLoading];
        if (alertView.tag != 2014) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                            message:@"If you Cancel this validation, the purchase may failed with your money paid. Still want to Cancel? "
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
            alert.tag = 2014;
            [alert show];

        }
    }
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
}

@end
