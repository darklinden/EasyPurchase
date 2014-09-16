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

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIButton     *pBtn_selectProduct;
@property (strong, nonatomic) SKProduct             *pSKProduct_selected;
@property (strong, nonatomic) UIView                *pV_loading;

@end

@implementation ViewController
@synthesize pV_loading;

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

- (void)showLoading
{
    if (!pV_loading) {
        self.pV_loading = [[UIView alloc] initWithFrame:self.view.bounds];
        [pV_loading setBackgroundColor:[UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.8f]];
        UIActivityIndicatorView *pV_indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [pV_indicator setCenter:pV_loading.center];
        [pV_indicator startAnimating];
        [pV_loading addSubview:pV_indicator];
    }
    
    [self.navigationController.view addSubview:pV_loading];
}

- (void)removeLoading
{
    if (self.pV_loading) {
        [pV_loading removeFromSuperview];
    }
}

- (void)didSelectProduct:(SKProduct *)product
{
    self.pSKProduct_selected = product;
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
    if (self.pSKProduct_selected) {
        [self showLoading];
        
        [EasyPurchase purchase:self.pSKProduct_selected completion:^(NSString *productId, NSString *transactionId, NSString *errMsg) {
            
            [self removeLoading];
            
            NSString *message = nil;
            
            if (!errMsg) {
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
}

- (IBAction)pBtn_restoreClick:(id)sender
{
    [self showLoading];
    
    [EasyPurchase restorePurchaseWithCompletion:^(NSArray *restoredProducts, NSString *errMsg) {
        [self removeLoading];
        
        NSString *messgae = [NSString stringWithFormat:@"Restored products: %@ error: %@", restoredProducts, errMsg];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:messgae delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }];
}

- (IBAction)pBtn_productClick:(id)sender
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.f) {
        [self showLoading];
        [self viewSellProduct:[NSNumber numberWithInt:413971331]];
    }
}

- (IBAction)pBtn_checkClick:(id)sender
{
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
        [self removeLoading];
        if (result) {
            [self presentViewController:viewController animated:YES completion:nil];
        }
        else {
            NSLog(@"description: %@", [error localizedDescription]);
            NSLog(@"failure reason: %@", [error localizedFailureReason]);
            NSLog(@"code: %d", [error code]);
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
    NSLog(@"%@", self);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
}

@end
