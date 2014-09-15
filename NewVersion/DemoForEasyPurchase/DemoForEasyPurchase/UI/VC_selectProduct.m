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
@property (strong, nonatomic) IBOutlet UITableView  *pVtable_products;
@property (strong, nonatomic) UIView                *pV_loading;
@property (strong, nonatomic) NSArray               *pArr_id;
@property (strong, nonatomic) NSArray               *pArr_data;
@property (strong, nonatomic) NSDictionary          *pDict_title;
@property (strong, nonatomic) NSDictionary          *pDict_price;
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)pBtn_closeClick:(id)sender
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
    
    UIBarButtonItem *pBtn_close = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(pBtn_closeClick:)];
    self.navigationItem.rightBarButtonItem = pBtn_close;
    
    // Do any additional setup after loading the view from its nib.
    
    //contact manager
//    self.pArr_id = @[@"RemoveAds_20130922"];
    
    //izip
    self.pArr_id = @[@"2012073111",
                     @"2013052101",
                     @"2013052102"];
    
    //power reader
//    self.pArr_id = @[@"PowerReader_20130415",
//                     @"PowerReader_Box_20130904",
//                     @"PowerReader_Dropbox_20130905",
//                     @"PowerReader_GoogleDrive_20130905"];
    
    [self showLoading];
#warning
//    [[C_IapPurchaseController mainIapPurchaseController] setDelegate:self];
//    [C_IapPurchaseController requestProductsByIds:self.pArr_id];
}

#pragma mark - for get product
- (void)responseProducts:(NSArray *)products pricesByIDs:(NSDictionary *)prices titlesByIDs:(NSDictionary *)titles
{
    [self removeLoading];
    self.pArr_data = products;
    self.pDict_price = prices;
    self.pDict_title = titles;
    [self.pVtable_products reloadData];
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
