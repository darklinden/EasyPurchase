//
//  VC_selectProduct.m
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 11/9/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import "VC_selectProduct.h"
#import "EasyPurchase.h"
#import "V_loading.h"

@interface VC_selectProduct ()
@property (assign, nonatomic) BOOL                          once;

@property (assign, nonatomic) SKProductPaymentType          type;
@property (strong, nonatomic) IBOutlet UITableView          *pVt_products;
@property (strong, nonatomic) IBOutlet UISegmentedControl   *pC_segment;

@property (strong, nonatomic) NSArray                       *array_consumable;
@property (strong, nonatomic) NSArray                       *array_nonconsumable;
@property (strong, nonatomic) NSMutableDictionary           *dict_consumable;
@property (strong, nonatomic) NSMutableDictionary           *dict_nonconsumable;
@property (strong, nonatomic) NSMutableDictionary           *dictTitle;
@property (strong, nonatomic) NSMutableDictionary           *dictPrice;
@end

@implementation VC_selectProduct

- (void)showLoading
{
    [V_loading showLoadingView:self.navigationController.view title:nil message:nil];
}

- (void)removeLoading
{
    [V_loading removeLoading];
}

- (void)pBtn_closeClick:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.titleView = _pC_segment;
    
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
        
        _array_consumable = @[@"darklinden.purchasetest.goldcoin"];
        _array_nonconsumable = @[@"darklinden.purchasetest.featureone",
                                 @"darklinden.purchasetest.featuretwo"];
        
        NSArray *arr = [NSArray arrayWithArray:_array_consumable];
        arr = [arr arrayByAddingObjectsFromArray:_array_nonconsumable];
        
        [EasyPurchase requestProductsByIds:arr completion:^(NSArray *requestProductIds, NSArray *responseProducts) {
            
            [self removeLoading];
            
            self.dict_consumable = [NSMutableDictionary dictionary];
            self.dict_nonconsumable = [NSMutableDictionary dictionary];
            self.dictPrice = [NSMutableDictionary dictionary];
            self.dictTitle = [NSMutableDictionary dictionary];
            
            for (SKProduct *p in responseProducts) {
                
                NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                [numberFormatter setFormatterBehavior:NSNumberFormatterBehaviorDefault];
                [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                [numberFormatter setLocale:p.priceLocale];
                NSString *formattedString = [numberFormatter stringFromNumber:p.price];
                
                if ([_array_consumable indexOfObject:p.productIdentifier] != NSNotFound) {
                    [_dict_consumable setObject:p forKey:p.productIdentifier];
                }
                
                if ([_array_nonconsumable indexOfObject:p.productIdentifier] != NSNotFound) {
                    [_dict_nonconsumable setObject:p forKey:p.productIdentifier];
                }
                
                [_dictPrice setObject:formattedString forKey:p.productIdentifier];
                [_dictTitle setObject:p.localizedTitle forKey:p.productIdentifier];
            }
            
            [self.pVt_products reloadData];
        }];
    }
}

- (IBAction)segmentValueChanged:(id)sender {
    _type = [(UISegmentedControl *)sender selectedSegmentIndex];
    [_pVt_products reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (_type) {
        case SKProductPaymentTypeConsumable:
        {
            return _dict_consumable.count;
        }
            break;
        case SKProductPaymentTypeNonConsumable:
        {
            return _dict_nonconsumable.count;
        }
            break;
        default:
            break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"cellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    NSString *pStr_key = nil;
    
    switch (_type) {
        case SKProductPaymentTypeConsumable:
        {
            pStr_key = [_dict_consumable.allKeys objectAtIndex:indexPath.row];
        }
            break;
        case SKProductPaymentTypeNonConsumable:
        {
            pStr_key = [_dict_nonconsumable.allKeys objectAtIndex:indexPath.row];
        }
            break;
        default:
            break;
    }
    
    NSString *pStr_title = pStr_key;
    NSString *pStr_price = @"no price";
    
    if ([self.dictTitle objectForKey:pStr_key]) {
        pStr_title = [self.dictTitle objectForKey:pStr_key];
    }
    
    if ([self.dictPrice objectForKey:pStr_key]) {
        pStr_price = [self.dictPrice objectForKey:pStr_key];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", pStr_title, pStr_price];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *pStr_key = nil;
    
    switch (_type) {
        case SKProductPaymentTypeConsumable:
        {
            pStr_key = [_dict_consumable.allKeys objectAtIndex:indexPath.row];
            SKProduct *product = _dict_consumable[pStr_key];
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(didSelectProduct:type:)]) {
                    [self.delegate didSelectProduct:product type:_type];
                }
            }
        }
            break;
        case SKProductPaymentTypeNonConsumable:
        {
            pStr_key = [_dict_nonconsumable.allKeys objectAtIndex:indexPath.row];
            SKProduct *product = _dict_nonconsumable[pStr_key];
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(didSelectProduct:type:)]) {
                    [self.delegate didSelectProduct:product type:_type];
                }
            }
        }
            break;
        default:
            break;
    }
    
    [self pBtn_closeClick:nil];
}

@end
