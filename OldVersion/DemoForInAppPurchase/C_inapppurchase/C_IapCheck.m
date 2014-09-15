//
//  C_IapCheck.m
//  DemoForInAppPurchase
//
//  Created by DarkLinden on 9/18/12.
//  Copyright (c) 2012 DarkLinden. All rights reserved.
//

#import "C_IapCheck.h"
#import "C_IapConstants.h"

#if __has_feature(objc_arc)
#error 请在非ARC下编译此类。在工程属性-Build Phases-Compile Sources中选择此文件，添加-fno-objc-arc标记以移除ARC。
#endif

@interface C_IapCheck ()
@property (strong, nonatomic) NSArray                   *array_products;
@property (strong, nonatomic) NSString                  *pStr_checkingUrl;
@property (strong, nonatomic) NSString                  *pStr_receipt;
@property (strong, nonatomic) NSMutableData             *pData_recv;
@property (unsafe_unretained) id<C_IapCheckDeleate>     delegate;
@property (strong, nonatomic) NSURLConnection           *connection;

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)sendrequest;
- (void)checkRequestFinishWithError:(NSString *)err;
@end

@implementation C_IapCheck
@synthesize array_products;
@synthesize pStr_checkingUrl;
@synthesize pStr_receipt;
@synthesize pData_recv;
@synthesize delegate;

- (void)dealloc
{
    delegate = nil;
    self.connection = nil;
    [array_products release], array_products = nil;
    [pStr_checkingUrl release], pStr_checkingUrl = nil;
    [pStr_receipt release], pStr_receipt = nil;
    [pData_recv release], pData_recv = nil;
    [super dealloc];
}

+ (NSString *)base64EncodedStringFrom:(NSData *)data
{
    static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
	if ([data length] == 0)
		return @"";
	
    char *characters = malloc((([data length] + 2) / 3) * 4);
	if (characters == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (i < [data length])
	{
		char buffer[3] = {0,0,0};
		short bufferLength = 0;
		while (bufferLength < 3 && i < [data length])
			buffer[bufferLength++] = ((char *)[data bytes])[i++];
		
		//  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
		characters[length++] = encodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
		if (bufferLength > 1)
			characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
		else characters[length++] = '=';
		if (bufferLength > 2)
			characters[length++] = encodingTable[buffer[2] & 0x3F];
		else characters[length++] = '=';
	}
	
	return [[[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES] autorelease];
}

+ (id)checkReceipt:(NSData *)receipt
           product:(NSString *)product
          delegate:(id<C_IapCheckDeleate>)delegate
{
    C_IapCheck *pC_IapCheck = [[C_IapCheck alloc] init];
    if (receipt) {
        pC_IapCheck.pStr_receipt = [self base64EncodedStringFrom:receipt];
    }
    else {
        pC_IapCheck.pStr_receipt = nil;
    }
    pC_IapCheck.delegate = delegate;
    return [pC_IapCheck autorelease];
}

- (void)start
{
    self.pStr_checkingUrl = IAP_PRODUCT_URL;
    [self sendrequest];
}

- (void)sendrequest
{
    if (!self.pStr_receipt) {
        if ([[NSBundle mainBundle] respondsToSelector:@selector(appStoreReceiptURL)]) {
            NSURL *url_receipt = [[NSBundle mainBundle] appStoreReceiptURL];
            NSData *receipt = [NSData dataWithContentsOfURL:url_receipt];
            if (receipt) {
                self.pStr_receipt = [[self class] base64EncodedStringFrom:receipt];
            }
        }
    }
    
    self.pData_recv = [NSMutableData data];
    NSString *json = [NSString stringWithFormat:IAP_JSON_FORMAT, self.pStr_receipt];
    NSMutableURLRequest *urlRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.pStr_checkingUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:IAP_RECEIPT_TIMEOUT] autorelease];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];
    
    self.connection = [[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self] autorelease];
    
    if (self.connection) {
        [self.connection start];
    }
    else {
        NSString *pStr_msg = @"err:connect failed reason:create connection returns null";
        [self checkRequestFinishWithError:pStr_msg];
    }
}

- (void)checkRequestFinishWithError:(NSString *)err
{
    if (delegate) {
        if ([delegate respondsToSelector:@selector(C_IapCheck:products:error:)]) {
            [delegate C_IapCheck:self products:self.array_products error:err];
        }
    }
}

- (void)cancel
{
    [self.connection cancel];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.pData_recv appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSString *pStr_msg = IAP_LOCALSTR_CheckReceiptNetWorkFailed;
    [self checkRequestFinishWithError:pStr_msg];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *pStr_result = [[[NSString alloc] initWithData:self.pData_recv encoding:NSUTF8StringEncoding] autorelease];
    
    IAP_CHECK_LOG(@"IAP recv: \n%@\n", pStr_result);
    
    id result = [NSJSONSerialization JSONObjectWithData:self.pData_recv
                                                options:NSJSONReadingAllowFragments
                                                  error:nil];
    
    if (!result) {
        NSString *pStr_msg = @"err:err JSON result reason:returns data can't be parsed by JSON";
        [self checkRequestFinishWithError:pStr_msg];
    }
    else {
        if ([result isKindOfClass:[NSDictionary class]]) {
            NSString *status = [[result objectForKey:@"status"] stringValue];
            
            if ([self.pStr_checkingUrl isEqualToString:IAP_PRODUCT_URL]) {
                
                if ([status isEqualToString:IAP_SUBSCRIBE_SUCCESS]) {
                
                    NSMutableArray *array_tmp_product = [NSMutableArray array];
                    
                    NSDictionary *receipt = [result objectForKey:@"receipt"];
                    if (receipt && [receipt isKindOfClass:[NSDictionary class]]) {
                        IAP_CHECK_LOG(@"bid ------------------------> %@",[receipt objectForKey:@"bid"]);
                        IAP_CHECK_LOG(@"product_id -----------------> %@",[receipt objectForKey:@"product_id"]);
                        IAP_CHECK_LOG(@"purchase_date --------------> %@",[receipt objectForKey:@"purchase_date"]);
                        IAP_CHECK_LOG(@"quantity -------------------> %@",[receipt objectForKey:@"quantity"]);
                        IAP_CHECK_LOG(@"original_purchase_date -----> %@",[receipt objectForKey:@"original_purchase_date"]);
                        IAP_CHECK_LOG(@"transaction_id -------------> %@",[receipt objectForKey:@"transaction_id"]);
                        IAP_CHECK_LOG(@"original_transaction_id ----> %@",[receipt objectForKey:@"original_transaction_id"]);
                        
                        if ([receipt objectForKey:@"product_id"] && [receipt objectForKey:@"transaction_id"]) {
                            NSDictionary *dict_tmp = @{@"product_id": [receipt objectForKey:@"product_id"],
                                                       @"transaction_id": [receipt objectForKey:@"transaction_id"]};
                            [array_tmp_product addObject:dict_tmp];
                        }
                        
                        if ([receipt objectForKey:@"in_app"]) {
                            NSArray *array_in_app = [receipt objectForKey:@"in_app"];
                            for (NSDictionary *dict in array_in_app) {
                                if ([dict objectForKey:@"product_id"] && [dict objectForKey:@"transaction_id"]) {
                                    NSDictionary *dict_tmp = @{@"product_id": [dict objectForKey:@"product_id"],
                                                               @"transaction_id": [dict objectForKey:@"transaction_id"]};
                                    [array_tmp_product addObject:dict_tmp];
                                }
                            }
                        }
                    }
                    
                    self.array_products = array_tmp_product;
                    [self checkRequestFinishWithError:nil];
                }
                else if ([status isEqualToString:IAP_SUBSCRIBE_FAILED_SANDBOX]) {
                    IAP_CHECK_LOG(@"IAP recv sandbox failed, call sandbox url");
                    self.pStr_checkingUrl = IAP_SANDBOX_URL;
                    [self sendrequest];
                }
                else {
                    NSString *pStr_msg = [NSString stringWithFormat:@"err:purchase failed reason:error code %@", status] ;
                    [self checkRequestFinishWithError:pStr_msg];
                }
            }
            else if ([self.pStr_checkingUrl isEqualToString:IAP_SANDBOX_URL]) {

                if ([status isEqualToString:IAP_SUBSCRIBE_SUCCESS]) {
                    
                    NSMutableArray *array_tmp_product = [NSMutableArray array];
                    
                    NSDictionary *receipt = [result objectForKey:@"receipt"];
                    if (receipt && [receipt isKindOfClass:[NSDictionary class]]) {
                        IAP_CHECK_LOG(@"bid ------------------------> %@",[receipt objectForKey:@"bid"]);
                        IAP_CHECK_LOG(@"product_id -----------------> %@",[receipt objectForKey:@"product_id"]);
                        IAP_CHECK_LOG(@"purchase_date --------------> %@",[receipt objectForKey:@"purchase_date"]);
                        IAP_CHECK_LOG(@"quantity -------------------> %@",[receipt objectForKey:@"quantity"]);
                        IAP_CHECK_LOG(@"original_purchase_date -----> %@",[receipt objectForKey:@"original_purchase_date"]);
                        IAP_CHECK_LOG(@"transaction_id -------------> %@",[receipt objectForKey:@"transaction_id"]);
                        IAP_CHECK_LOG(@"original_transaction_id ----> %@",[receipt objectForKey:@"original_transaction_id"]);
                        
                        if ([receipt objectForKey:@"product_id"] && [receipt objectForKey:@"transaction_id"]) {
                            NSDictionary *dict_tmp = @{@"product_id": [receipt objectForKey:@"product_id"],
                                                       @"transaction_id": [receipt objectForKey:@"transaction_id"]};
                            [array_tmp_product addObject:dict_tmp];
                        }
                        
                        if ([receipt objectForKey:@"in_app"]) {
                            NSArray *array_in_app = [receipt objectForKey:@"in_app"];
                            for (NSDictionary *dict in array_in_app) {
                                if ([dict objectForKey:@"product_id"] && [dict objectForKey:@"transaction_id"]) {
                                    NSDictionary *dict_tmp = @{@"product_id": [dict objectForKey:@"product_id"],
                                                               @"transaction_id": [dict objectForKey:@"transaction_id"]};
                                    [array_tmp_product addObject:dict_tmp];
                                }
                            }
                        }
                    }
                    
                    self.array_products = array_tmp_product;
                    [self checkRequestFinishWithError:nil];
                }
                else {
                    NSString *pStr_msg = [NSString stringWithFormat:@"err:purchase failed reason:error code %@", status] ;
                    [self checkRequestFinishWithError:pStr_msg];
                }
            }
            else {
                NSString *pStr_msg = [NSString stringWithFormat:@"err:unknown url reason:url is %@", pStr_checkingUrl];
                [self checkRequestFinishWithError:pStr_msg];
            }
        }
        else {
            NSString *pStr_msg = @"err:err JSON result reason:returns JSON is not NSDictionary";
            [self checkRequestFinishWithError:pStr_msg];
        }
    }
}

@end
