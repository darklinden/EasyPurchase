//
//  C_IapPurchaseController.m
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/19/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import "C_IapPurchaseController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

#if __has_feature(objc_arc)
#error 请在非ARC下编译此类。在工程属性-Build Phases-Compile Sources中选择此文件，添加-fno-objc-arc标记以移除ARC。
#endif

@interface C_IapPurchaseController ()
@property (strong, nonatomic) C_IapProduct      *pC_IapProduct;
@property (strong, nonatomic) C_IapObserver     *pC_IapObserver;
@property (strong, nonatomic) SKProduct         *pProduct_purchasing;
@property (strong, nonatomic) NSMutableArray    *pArr_checker;
@property (strong, nonatomic) NSMutableArray    *pArr_check_pass;

@property (strong, nonatomic) NSString          *pStr_restoreErr;

// tool func keychain store
+ (NSString *)getSecureValueForKey:(NSString *)key;
+ (bool)storeSecureValue:(NSString *)value forKey:(NSString *)key;

// get product info
- (void)requestProductsByIds:(NSArray *)product_ids;
- (void)responseProducts:(NSArray *)products;

// purchase
- (void)requestPurchaseProduct:(SKProduct *)product;

@end

__strong static C_IapPurchaseController *pStaticController = nil;

@implementation C_IapPurchaseController

#pragma mark - life circle
+ (id)mainIapPurchaseController
{
    if (!pStaticController) {
        pStaticController = [[C_IapPurchaseController alloc] init];
        pStaticController.delegate = nil;
    }
    return pStaticController;
}

+ (void)close
{
    [pStaticController release], pStaticController = nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.pC_IapObserver = [C_IapObserver observerWithDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    [_pC_IapProduct release],           _pC_IapProduct = nil;
    [_pC_IapObserver release],          _pC_IapObserver = nil;
    [_pProduct_purchasing release],     _pProduct_purchasing = nil;
    [_pArr_checker release],            _pArr_checker = nil;
    [_pArr_check_pass release],         _pArr_check_pass = nil;
    [super dealloc];
}

#pragma mark - asset & store & deal with old purchase
+ (BOOL)assetIsSubscribe:(NSString *)product_id
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[defaults objectForKey:IAP_USER_DEFAULT_FIRST_RUN] isEqualToString:IAP_USER_DEFAULT_FIRST_RUN]) {
        [defaults setObject:IAP_USER_DEFAULT_FIRST_RUN forKey:IAP_USER_DEFAULT_FIRST_RUN];
        [defaults synchronize];
        
        NSString *pStr_count = [self getSecureValueForKey:IAP_SECURE_VALUE_COUNT_KEY];
        [self storeSecureValue:@"0" forKey:IAP_SECURE_VALUE_COUNT_KEY];
        
        NSInteger intKeyCount = [pStr_count integerValue];
        if (intKeyCount > 0) {
            for (int i = 0; i < intKeyCount; i++) {
                NSString *pStr_key = [NSString stringWithFormat:IAP_SECURE_VALUE_KEY_FORMAT, i];
                [self storeSecureValue:@"" forKey:pStr_key];
            }
        }
        return NO;
    }
    else {
        NSString *pStr_count = [self getSecureValueForKey:IAP_SECURE_VALUE_COUNT_KEY];
        NSInteger intKeyCount = [pStr_count integerValue];
        if (intKeyCount > 0) {
            BOOL isSubscribed = NO;
            for (int i = 0; i < intKeyCount; i++) {
                NSString *pStr_key = [NSString stringWithFormat:IAP_SECURE_VALUE_KEY_FORMAT, i];
                NSString *pStr_product = [self getSecureValueForKey:pStr_key];
                if ([product_id isEqualToString:pStr_product]) {
                    isSubscribed = YES;
                    break;
                }
            }
            return isSubscribed;
        }
        else {
            return NO;
        }
    }
}

+ (void)storeSubscribe:(NSString *)product_id
{
    NSString *pStr_count = [self getSecureValueForKey:IAP_SECURE_VALUE_COUNT_KEY];
    NSInteger intKeyCount = [pStr_count integerValue];
    if (intKeyCount > 0) {
        BOOL isSubscribed = NO;
        for (int i = 0; i < intKeyCount; i++) {
            NSString *pStr_key = [NSString stringWithFormat:IAP_SECURE_VALUE_KEY_FORMAT, i];
            NSString *pStr_product = [self getSecureValueForKey:pStr_key];
            if ([product_id isEqualToString:pStr_product]) {
                isSubscribed = YES;
                break;
            }
        }
        
        if (!isSubscribed) {
            [self storeSecureValue:product_id forKey:[NSString stringWithFormat:IAP_SECURE_VALUE_KEY_FORMAT, intKeyCount]];
            intKeyCount++;
            [self storeSecureValue:[NSString stringWithFormat:@"%d", intKeyCount] forKey:IAP_SECURE_VALUE_COUNT_KEY];
        }
    }
    else {
        intKeyCount = 0;
        [self storeSecureValue:product_id forKey:[NSString stringWithFormat:IAP_SECURE_VALUE_KEY_FORMAT, intKeyCount]];
        intKeyCount++;
        [self storeSecureValue:[NSString stringWithFormat:@"%d", intKeyCount] forKey:IAP_SECURE_VALUE_COUNT_KEY];
    }
}

+ (void)dealWithOldProduct:(NSString *)product_id forKey:(NSString *)key
{
    NSString *pStr_stored_id = [self getSecureValueForKey:key];
    NSLog(@"log izip_old pStr_stored_id %@", pStr_stored_id);
    if ([pStr_stored_id isEqualToString:product_id]) {
        [self storeSubscribe:product_id];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:IAP_USER_DEFAULT_FIRST_RUN forKey:IAP_USER_DEFAULT_FIRST_RUN];
        [defaults synchronize];
        [self storeSecureValue:@"" forKey:key];
    }
}

#pragma mark - get product info
+ (void)requestProductsByIds:(NSArray *)product_ids
{
    if (product_ids.count > 0) {
        if (pStaticController && pStaticController.delegate) {
            [pStaticController requestProductsByIds:product_ids];
        }
        else {
            NSAssert(0, @"should not reach this line");
        }
    }
    else {
        NSAssert(0, @"product id should not be null");
    }
}

- (void)requestProductsByIds:(NSArray *)product_ids;
{
    self.pC_IapProduct = [C_IapProduct requestProductsByIds:product_ids delegate:self];
}

- (void)C_IapProduct:(C_IapProduct *)sender products:(NSArray *)products
{
    [self responseProducts:products];
    self.pC_IapProduct = nil;
}

- (void)responseProducts:(NSArray *)products
{
    NSMutableDictionary *prices = [NSMutableDictionary dictionary];
    NSMutableDictionary *titles = [NSMutableDictionary dictionary];
    
    for (SKProduct *product in products) {
        
        IAP_CONTROLLER_LOG(@"get product %@", product.productIdentifier);
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.f) {
            IAP_CONTROLLER_LOG(@"downloadable: %d", product.downloadable);
            IAP_CONTROLLER_LOG(@"downloadContentLengths: %@", product.downloadContentLengths);
            IAP_CONTROLLER_LOG(@"downloadContentVersion: %@", product.downloadContentVersion);
        }
        
        IAP_CONTROLLER_LOG(@"localizedDescription: %@", product.localizedDescription);
        IAP_CONTROLLER_LOG(@"localizedTitle: %@", product.localizedTitle);
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehaviorDefault];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];
        NSString *formattedString = [numberFormatter stringFromNumber:product.price];
        [numberFormatter release], numberFormatter = nil;
        
        IAP_CONTROLLER_LOG(@"price: %@", formattedString);
        
        [prices setObject:formattedString forKey:product.productIdentifier];
        [titles setObject:product.localizedTitle forKey:product.productIdentifier];
    }
    
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(responseProducts:pricesByIDs:titlesByIDs:)]) {
            [self.delegate responseProducts:products pricesByIDs:prices titlesByIDs:titles];
        }
    }
}

#pragma mark - purchase
+ (void)requestPurchaseProduct:(SKProduct *)product
{
    if (pStaticController && pStaticController.delegate) {
        if ([self assetIsSubscribe:product.productIdentifier]) {
            [pStaticController purchaseProduct:product errMsg:nil];
        }
        else {
            if ([SKPaymentQueue canMakePayments]) {
                pStaticController.pProduct_purchasing = product;
                [pStaticController requestPurchaseProduct:product];
            }
            else {
                [pStaticController purchaseProduct:product errMsg:IAP_LOCALSTR_SKErrorPaymentNotAllowed];
            }
        }
    }
}

- (void)requestPurchaseProduct:(SKProduct *)product
{
    BOOL hasPerformed = NO;
    
    for (SKPaymentTransaction *transaction in [[SKPaymentQueue defaultQueue] transactions]) {
        if ([transaction.payment.productIdentifier isEqualToString:product.productIdentifier]) {
            IAP_CONTROLLER_LOG(@"product already in purchasing %@", product.productIdentifier);
            hasPerformed = YES;
            break;
        }
    }
    
    if (!hasPerformed) {
        SKMutablePayment *pPayment = [SKMutablePayment paymentWithProduct:product];
        pPayment.quantity = 1;
        [[SKPaymentQueue defaultQueue] addPayment:pPayment];
    }
    else {
        [self purchaseProduct:product errMsg:IAP_LOCALSTR_CheckReceiptFailed];
    }
}

- (void)purchaseProduct:(SKProduct *)product errMsg:(NSString *)errMsg
{
    IAP_CONTROLLER_LOG(@"purchaseProduct:%@ err:%@", product.productIdentifier, errMsg);
    
    SKProduct *current_product = [product retain];
    self.pProduct_purchasing = nil;
    
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(purchaseProduct:errMsg:)]) {
            [_delegate purchaseProduct:[current_product autorelease] errMsg:errMsg];
        }
    }
}

#pragma mark - restore
+ (void)requestRestore
{
    if ([SKPaymentQueue canMakePayments]) {
        [pStaticController requestRestore];
    }
    else {
        [pStaticController restoreProducts:nil errMsg:IAP_LOCALSTR_SKErrorPaymentNotAllowed];
    }
}

- (void)requestRestore
{
    self.pArr_checker = [NSMutableArray array];
    self.pArr_check_pass = [NSMutableArray array];
    self.pStr_restoreErr = nil;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)restoreProducts:(NSMutableArray *)product_ids errMsg:(NSString *)errMsg
{
    IAP_CONTROLLER_LOG(@"restore products: %@ err:%@", product_ids, errMsg);
    
    NSMutableArray *storeed_product_ids = [product_ids retain];
    
    self.pArr_check_pass = nil;
    
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(restoreProducts:errMsg:)]) {
            [_delegate restoreProducts:[storeed_product_ids autorelease] errMsg:errMsg];
        }
    }
}

#pragma mark - C_IapObserverDelegate
- (void)checkProduct:(NSString *)product_id receipt:(NSData *)receipt
{
    if (self.pProduct_purchasing) {
        IAP_CONTROLLER_LOG(@"checkProduct %@ receipt length %u", product_id, receipt.length);
        C_IapCheck *pC_IapCheck = [C_IapCheck checkReceipt:receipt product:product_id delegate:self];
        [self.pArr_checker addObject:pC_IapCheck];
        [pC_IapCheck start];
    }
    else if (self.pArr_check_pass) {
        IAP_CONTROLLER_LOG(@"checkProduct %@ receipt length %u", product_id, receipt.length);
        C_IapCheck *pC_IapCheck = [C_IapCheck checkReceipt:receipt product:product_id delegate:self];
        [self.pArr_checker addObject:pC_IapCheck];
    }
}

- (void)finishPurchase:(NSString *)product_id error:(NSString *)errMsg;
{
    if (errMsg) {
        IAP_CONTROLLER_LOG(@"purchase %@ err %@", product_id, errMsg);
        if (self.pProduct_purchasing) {
            if ([self.pProduct_purchasing.productIdentifier isEqualToString:product_id]) {
                [self purchaseProduct:self.pProduct_purchasing errMsg:errMsg];
            }
        }
    }
}

- (void)finishRestoreWithError:(NSString *)errMsg
{
    if (errMsg) {
        IAP_CONTROLLER_LOG(@"restoreWithError %@", errMsg);
        [self restoreProducts:nil errMsg:errMsg];
    }
    else {
        IAP_CONTROLLER_LOG(@"restoreSuccess");
        if (!self.pArr_checker.count) {
            [self restoreProducts:[NSMutableArray array] errMsg:nil];
        }
        else {
            C_IapCheck *checker = [self.pArr_checker lastObject];
            [checker start];
        }
    }
}

- (void)trackPurchase:(NSString *)product transaction:(NSString *)transaction_id
{
    GAIDictionaryBuilder *builder =
    [GAIDictionaryBuilder createTransactionWithId:transaction_id
                                      affiliation:@"InApp"
                                          revenue:[NSNumber numberWithLongLong:(int64_t)(self.pProduct_purchasing.price.floatValue * 1000000)]
                                              tax:[NSNumber numberWithLongLong:(int64_t)(0)]
                                         shipping:[NSNumber numberWithLongLong:(int64_t)(0)]
                                     currencyCode:self.pProduct_purchasing.productIdentifier];
    [[[GAI sharedInstance] defaultTracker] send:[builder build]];
}

#pragma mark - C_IapCheckDeleate
- (void)C_IapCheck:(C_IapCheck *)sender products:(NSArray *)products error:(NSString *)errMsg
{
    IAP_CONTROLLER_LOG(@"check products:%@ error:%@", products, errMsg);
    [self.pArr_checker removeObject:sender];
    
    if (self.pProduct_purchasing) {
        
        NSString *string_transaction_id = nil;
        for (NSDictionary *dict_tmp in products) {
            NSString *string_product_id = dict_tmp[@"product_id"];
            if ([self.pProduct_purchasing.productIdentifier isEqualToString:string_product_id]) {
                [[self class] storeSubscribe:string_product_id];
                string_transaction_id = dict_tmp[@"transaction_id"];
            }
        }
        
        if (string_transaction_id) {
            [self trackPurchase:self.pProduct_purchasing.productIdentifier transaction:string_transaction_id];
            [self purchaseProduct:self.pProduct_purchasing errMsg:nil];
        }
        else {
            if (errMsg) {
                if ([errMsg isEqualToString:IAP_LOCALSTR_CheckReceiptNetWorkFailed]) {
                    [self purchaseProduct:self.pProduct_purchasing errMsg:IAP_LOCALSTR_CheckReceiptNetWorkFailed];
                }
                else {
                    [self purchaseProduct:self.pProduct_purchasing errMsg:IAP_LOCALSTR_CheckReceiptFailed];
                }
            }
            else {
                [self purchaseProduct:self.pProduct_purchasing errMsg:IAP_LOCALSTR_CheckReceiptFailed];
            }
        }
    }
    else {
        
        for (NSDictionary *dict_tmp in products) {
            NSString *string_product_id = dict_tmp[@"product_id"];
            [[self class] storeSubscribe:string_product_id];
            
            if ([self.pArr_check_pass indexOfObject:string_product_id] == NSNotFound) {
                [self.pArr_check_pass addObject:string_product_id];
            }
        }
        
        if (errMsg) {
            if ([errMsg isEqualToString:IAP_LOCALSTR_CheckReceiptNetWorkFailed]) {
                self.pStr_restoreErr = IAP_LOCALSTR_CheckReceiptNetWorkFailed;
            }
        }
        
        if (self.pArr_checker.count) {
            C_IapCheck *checker = [self.pArr_checker lastObject];
            [checker start];
        }
        else {
            [self restoreProducts:self.pArr_check_pass errMsg:self.pStr_restoreErr];
        }
    }
}

#pragma mark - keychain store
+ (NSString *)getSecureValueForKey:(NSString *)key
{
    /*
     Return a value from the keychain
     */
    
    // Retrieve a value from the keychain
    NSDictionary *result = nil;
    NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, kSecAttrAccount, kSecReturnAttributes, nil] autorelease];
    NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, key, kCFBooleanTrue, nil] autorelease];
    NSDictionary *query = [[NSDictionary alloc] initWithObjects: objects forKeys: keys];
    
    // Check if the value was found
    OSStatus status = SecItemCopyMatching((CFDictionaryRef) query, (CFTypeRef *) &result);
    [query release];
    if (status != noErr) {
        // Value not found
        return nil;
    } else {
        // Value was found so return it
        NSString *value = [NSString stringWithString:(NSString *) [result objectForKey: (NSString *) kSecAttrGeneric]];
        [result release];
        return value;
    }
}

+ (bool)storeSecureValue:(NSString *)value forKey:(NSString *)key
{
    /*
     Store a value in the keychain
     */
    
    // Get the existing value for the key
    NSString *existingValue = [self getSecureValueForKey:key];
    
    // Check if a value already exists for this key
    OSStatus status;
    if (existingValue) {
        // Value already exists, so update it
        NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, kSecAttrAccount, nil] autorelease];
        NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, key, nil] autorelease];
        NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];
        status = SecItemUpdate((CFDictionaryRef) query, (CFDictionaryRef) [NSDictionary dictionaryWithObject:value forKey: (NSString *) kSecAttrGeneric]);
    } else {
        // Value does not exist, so add it
        NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, kSecAttrAccount, kSecAttrGeneric, nil] autorelease];
        NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, key, value, nil] autorelease];
        NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];
        status = SecItemAdd((CFDictionaryRef) query, NULL);
    }
    
    // Check if the value was stored
    if (status != noErr) {
        // Value was not stored
        return false;
    } else {
        // Value was stored
        return true;
    }
}

@end
