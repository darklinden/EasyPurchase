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
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0
    [self dismissViewControllerAnimated:YES completion:nil];
#else
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.f) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [self dismissModalViewControllerAnimated:YES];
    }
#endif
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
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0
    [self presentViewController:pNC_nav animated:YES completion:nil];
#else
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.f) {
        [self presentViewController:pNC_nav animated:YES completion:nil];
    }
    else {
        [self presentModalViewController:pNC_nav animated:YES];
    }
#endif
}

- (IBAction)pBtn_buyClick:(id)sender
{
    if (self.pSKProduct_selected) {
        [self showLoading];
#warning
//        [[C_IapPurchaseController mainIapPurchaseController] setDelegate:self];
//        [C_IapPurchaseController requestPurchaseProduct:self.pSKProduct_selected];
    }
}

- (IBAction)pBtn_restoreClick:(id)sender
{
    [self showLoading];
#warning
//    [[C_IapPurchaseController mainIapPurchaseController] setDelegate:self];
//    [C_IapPurchaseController requestRestore];
}

- (IBAction)pBtn_endpurchaseClick:(id)sender
{
#warning
//    [C_IapPurchaseController close];
}

- (IBAction)pBtn_clearClick:(id)sender
{
#warning
//    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:IAP_USER_DEFAULT_FIRST_RUN];
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
#warning
//    if ([C_IapPurchaseController assetIsSubscribe:self.pBtn_selectProduct.currentTitle]) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"purchased" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
//        [alert show];
//    }
//    else {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"haven't purchased" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
//        [alert show];
//    }
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

#pragma mark - for purchase
- (void)purchaseProduct:(SKProduct *)product errMsg:(NSString *)errMsg
{
#warning
//    [C_IapPurchaseController close];
    [self removeLoading];
    
    NSString *pStr_msg = nil;
    
    if (!errMsg) {
        pStr_msg = [NSString stringWithFormat:@"product %@ purchase success", product.productIdentifier];
    }
    else {
        if ([errMsg isEqualToString:IAP_LOCALSTR_SKErrorPaymentCancelled]) {
            //throw away
            NSLog(@"user canceled. remove loading and do nothing.");
        }
        else {
            pStr_msg = [NSString stringWithFormat:@"product %@ purchase failed. error msg: %@", product.productIdentifier, errMsg];
        }
    }
    
    if (pStr_msg) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:pStr_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - for restore
- (void)restoreProducts:(NSMutableArray *)products errMsg:(NSString *)errMsg
{
    [self removeLoading];
#warning 
//    [C_IapPurchaseController close];
    
    NSString *pStr_msg = nil;
    
    if (!errMsg) {
        pStr_msg = [NSString stringWithFormat:@"restore success: %@", products];
    }
    else {
        pStr_msg = [NSString stringWithFormat:@"restore failed with error: %@", errMsg];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:pStr_msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%@", self);
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0
    [self dismissViewControllerAnimated:YES completion:nil];
#else
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.f) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [self dismissModalViewControllerAnimated:YES];
    }
#endif
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
}

@end
