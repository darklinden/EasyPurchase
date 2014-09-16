//
//  VC_selectProduct.m
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 11/9/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import "VC_selectProduct.h"
#import "EasyPurchase.h"

@interface VC_selectProduct ()
@property (assign, nonatomic) BOOL                  once;

@property (strong, nonatomic) IBOutlet UITableView  *pVtable_products;
@property (strong, nonatomic) UIView                *pV_loading;
@property (strong, nonatomic) NSArray               *pArr_id;
@property (strong, nonatomic) NSArray               *pArr_data;
@property (strong, nonatomic) NSMutableDictionary   *pDict_title;
@property (strong, nonatomic) NSMutableDictionary   *pDict_price;
@end

@implementation VC_selectProduct

- (void)showLoading
{
    if (!_pV_loading) {
        self.pV_loading = [[UIView alloc] initWithFrame:self.navigationController.view.bounds];
        [_pV_loading setBackgroundColor:[UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.8f]];
        UIActivityIndicatorView *pV_indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [pV_indicator setCenter:_pV_loading.center];
        [pV_indicator startAnimating];
        [_pV_loading addSubview:pV_indicator];
    }
    
    [self.navigationController.view addSubview:_pV_loading];
}

- (void)removeLoading
{
    if (self.pV_loading) {
        [_pV_loading removeFromSuperview];
    }
}

- (void)pBtn_closeClick:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *pBtn_close = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(pBtn_closeClick:)];
    self.navigationItem.rightBarButtonItem = pBtn_close;
    
    _once = NO;
    
    [self showLoading];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_once) {
        _once = YES;
        
        self.pArr_id = @[@"darklinden.purchasetest.featureone",
                         @"darklinden.purchasetest.featuretwo",
                         @"darklinden.purchasetest.goldcoin"];
        [EasyPurchase requestProductsByIds:_pArr_id completion:^(NSArray *responseProducts) {
            [self removeLoading];
            self.pArr_data = responseProducts;
            
            self.pDict_price = [NSMutableDictionary dictionary];
            self.pDict_title = [NSMutableDictionary dictionary];
            for (SKProduct *p in responseProducts) {
                
                NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                [numberFormatter setFormatterBehavior:NSNumberFormatterBehaviorDefault];
                [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                [numberFormatter setLocale:p.priceLocale];
                NSString *formattedString = [numberFormatter stringFromNumber:p.price];
                
                [_pDict_price setObject:formattedString forKey:p.productIdentifier];
                [_pDict_title setObject:p.localizedTitle forKey:p.productIdentifier];
            }
            
            [self.pVtable_products reloadData];
        }];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.pArr_id.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"cellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    NSString *pStr_key = [self.pArr_id objectAtIndex:indexPath.row];
    NSString *pStr_title = pStr_key;
    NSString *pStr_price = @"no price";
    
    if ([self.pDict_title objectForKey:pStr_key]) {
        pStr_title = [self.pDict_title objectForKey:pStr_key];
    }
    
    if ([self.pDict_price objectForKey:pStr_key]) {
        pStr_price = [self.pDict_price objectForKey:pStr_key];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", pStr_title, pStr_price];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.pArr_id.count) {
        NSString *product_id = [self.pArr_id objectAtIndex:indexPath.row];
        
        for (SKProduct *product in self.pArr_data) {
            if ([product.productIdentifier isEqualToString:product_id]) {
                if (self.delegate) {
                    if ([self.delegate respondsToSelector:@selector(didSelectProduct:)]) {
                        [self.delegate didSelectProduct:product];
                    }
                }
                break;
            }
        }
    }
    [self pBtn_closeClick:nil];
}

@end
