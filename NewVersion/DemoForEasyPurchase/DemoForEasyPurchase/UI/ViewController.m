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
        
        [V_loading showLoadingView:self.navigationController.view title:nil message:@"Non-Consumable Purchasing"];
        [EasyPurchase purchase:self.selectedProduct type:_selectedProductType completion:^(NSString *productId, NSString *transactionId, EPError error) {
            
            [V_loading removeLoading];
            
            NSString *message = nil;
            
            if (EPErrorSuccess == error) {
                [EasyPurchase savePurchase:productId];
                message = [NSString stringWithFormat:@"product %@ purchase success", productId];
            }
            else {
                if (EPErrorCancelled == error) {
                    //throw away
                    NSLog(@"user canceled. remove loading and do nothing.");
                }
                else {
#if DEBUG
                    message = [NSString stringWithFormat:@"product %@ purchase failed. error: %@", productId, EPErrorName[@(error)]];
#else
                    message = [NSString stringWithFormat:@"product %@ purchase failed. error code: %llu", productId, (u_int64_t)error];
#endif
                }
            }
            
            if (message) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
        }];
    }
}

- (IBAction)pBtn_restoreClick:(id)sender
{
    if (self.selectedProductType == SKProductPaymentTypeConsumable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"Consumable purchase is not able to restore!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    [V_loading showLoadingView:self.navigationController.view title:nil message:@"Non-Consumable Restoring"];
    [EasyPurchase restorePurchaseWithCompletion:^(NSArray *restoredProducts, EPError error) {
        
        [V_loading removeLoading];
        
        for (NSString *pid in restoredProducts) {
            [EasyPurchase savePurchase:pid];
        }
        
#if DEBUG
        NSString *messgae = [NSString stringWithFormat:@"Restored products: %@ error: %@", restoredProducts, EPErrorName[@(error)]];
#else
        NSString *messgae = [NSString stringWithFormat:@"Restored products: %@ error code: %lld", restoredProducts, (u_int64_t)error];
#endif
        
        
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
    
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
}

@end
