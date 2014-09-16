//
//  EPReceiptChecker.m
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import "EPReceiptChecker.h"
#import "ObjHolder.h"
#import "EasyPurchase.h"

@interface EPReceiptChecker () {
    EPReceiptCheckerCompletionHandle _completionHandle;
}
@property (nonatomic, strong) NSString                  *ticket;
@property (strong, nonatomic) NSMutableArray            *passedProducts;
@property (strong, nonatomic) NSString                  *checkingUrl;
@property (strong, nonatomic) NSString                  *receiptString;
@property (strong, nonatomic) NSMutableData             *dataRecv;
@property (strong, nonatomic) NSURLConnection           *connection;

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)sendrequest;
- (void)checkRequestFinishWithError:(NSString *)err;

@end

@implementation EPReceiptChecker

+ (void)checkReceiptWithCompletion:(EPReceiptCheckerCompletionHandle)completionHandle
{
    EPReceiptChecker *checker = [[EPReceiptChecker alloc] init];
    checker.ticket = [[ObjHolder sharedHolder] pushObject:checker];
    checker->_completionHandle = completionHandle;
    [checker start];
}

- (void)dealloc
{
    _completionHandle = nil;
    self.connection = nil;
    self.passedProducts = nil;
    self.checkingUrl = nil;
    self.receiptString = nil;
    self.dataRecv = nil;
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
	
	return [[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

- (void)start
{
    self.checkingUrl = IAP_PRODUCT_URL;
    
    if ([[NSBundle mainBundle] respondsToSelector:@selector(appStoreReceiptURL)]) {
        NSURL *url_receipt = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *receipt = [NSData dataWithContentsOfURL:url_receipt];
        if (receipt) {
            self.receiptString = [[self class] base64EncodedStringFrom:receipt];
        }
    }
    
    self.passedProducts = [NSMutableArray array];
    
    if (_receiptString) {
        [self sendrequest];
    }
    else {
        [self checkRequestFinishWithError:IAP_LOCALSTR_CheckReceiptFailed];
    }
}

- (void)sendrequest
{
    self.dataRecv = [NSMutableData data];
    NSString *json = [NSString stringWithFormat:IAP_JSON_FORMAT, self.receiptString];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.checkingUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:IAP_RECEIPT_TIMEOUT];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    
    if (self.connection) {
        [self.connection start];
    }
    else {
        [self checkRequestFinishWithError:IAP_LOCALSTR_CheckReceiptNetWorkFailed];
    }
}

- (void)checkRequestFinishWithError:(NSString *)err
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_completionHandle) {
            _completionHandle([self.passedProducts copy], [err copy]);
        }
        
        [[ObjHolder sharedHolder] popObjectWithTicket:_ticket];
    });
}

- (void)cancel
{
    [self.connection cancel];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.dataRecv appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self checkRequestFinishWithError:IAP_LOCALSTR_CheckReceiptNetWorkFailed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    IAP_CHECK_LOG(@"IAP recv: \n%@\n", [[NSString alloc] initWithData:self.dataRecv encoding:NSUTF8StringEncoding]);
    
    id result = [NSJSONSerialization JSONObjectWithData:self.dataRecv
                                                options:NSJSONReadingAllowFragments
                                                  error:nil];
    
    if (!result) {
        [self checkRequestFinishWithError:IAP_LOCALSTR_CheckReceiptNetWorkFailed];
    }
    else {
        if ([result isKindOfClass:[NSDictionary class]]) {
            NSString *status = [[result objectForKey:@"status"] stringValue];
            
            if ([self.checkingUrl isEqualToString:IAP_PRODUCT_URL]) {
                
                if ([status isEqualToString:IAP_SUBSCRIBE_SUCCESS]) {
                    
                    NSDictionary *receipt = [result objectForKey:@"receipt"];
                    if (receipt && [receipt isKindOfClass:[NSDictionary class]]) {
                        
                        if ([receipt objectForKey:@"in_app"]) {
                            NSArray *array_in_app = [receipt objectForKey:@"in_app"];
                            for (NSDictionary *dict in array_in_app) {
                                IAP_CHECK_LOG(@"bid ------------------------> %@",[dict objectForKey:@"bid"]);
                                IAP_CHECK_LOG(@"product_id -----------------> %@",[dict objectForKey:@"product_id"]);
                                IAP_CHECK_LOG(@"purchase_date --------------> %@",[dict objectForKey:@"purchase_date"]);
                                IAP_CHECK_LOG(@"quantity -------------------> %@",[dict objectForKey:@"quantity"]);
                                IAP_CHECK_LOG(@"original_purchase_date -----> %@",[dict objectForKey:@"original_purchase_date"]);
                                IAP_CHECK_LOG(@"transaction_id -------------> %@",[dict objectForKey:@"transaction_id"]);
                                IAP_CHECK_LOG(@"original_transaction_id ----> %@",[dict objectForKey:@"original_transaction_id"]);
                                
                                if ([dict objectForKey:@"product_id"] && [dict objectForKey:@"transaction_id"]) {
                                    NSDictionary *dict_tmp = @{@"product_id": [dict objectForKey:@"product_id"],
                                                               @"transaction_id": [dict objectForKey:@"transaction_id"]};
                                    [_passedProducts addObject:dict_tmp];
                                }
                            }
                        }
                    }
                    
                    [self checkRequestFinishWithError:nil];
                }
                else if ([status isEqualToString:IAP_SUBSCRIBE_FAILED_SANDBOX]) {
                    IAP_CHECK_LOG(@"IAP recv sandbox failed, call sandbox url");
                    self.checkingUrl = IAP_SANDBOX_URL;
                    [self sendrequest];
                }
                else {
                    IAP_CHECK_LOG(@"err: purchase failed reason: error code %@", status);
                    [self checkRequestFinishWithError:IAP_LOCALSTR_CheckReceiptFailed];
                }
            }
            else if ([self.checkingUrl isEqualToString:IAP_SANDBOX_URL]) {
                
                if ([status isEqualToString:IAP_SUBSCRIBE_SUCCESS]) {
                    
                    NSDictionary *receipt = [result objectForKey:@"receipt"];
                    if (receipt && [receipt isKindOfClass:[NSDictionary class]]) {
                        
                        if ([receipt objectForKey:@"in_app"]) {
                            NSArray *array_in_app = [receipt objectForKey:@"in_app"];
                            for (NSDictionary *dict in array_in_app) {
                                IAP_CHECK_LOG(@"bid ------------------------> %@",[dict objectForKey:@"bid"]);
                                IAP_CHECK_LOG(@"product_id -----------------> %@",[dict objectForKey:@"product_id"]);
                                IAP_CHECK_LOG(@"purchase_date --------------> %@",[dict objectForKey:@"purchase_date"]);
                                IAP_CHECK_LOG(@"quantity -------------------> %@",[dict objectForKey:@"quantity"]);
                                IAP_CHECK_LOG(@"original_purchase_date -----> %@",[dict objectForKey:@"original_purchase_date"]);
                                IAP_CHECK_LOG(@"transaction_id -------------> %@",[dict objectForKey:@"transaction_id"]);
                                IAP_CHECK_LOG(@"original_transaction_id ----> %@",[dict objectForKey:@"original_transaction_id"]);
                                
                                if ([dict objectForKey:@"product_id"] && [dict objectForKey:@"transaction_id"]) {
                                    NSDictionary *dict_tmp = @{@"product_id": [dict objectForKey:@"product_id"],
                                                               @"transaction_id": [dict objectForKey:@"transaction_id"]};
                                    [_passedProducts addObject:dict_tmp];
                                }
                            }
                        }
                    }
                    
                    [self checkRequestFinishWithError:nil];
                }
                else {
                    IAP_CHECK_LOG(@"err: purchase failed reason: error code %@", status);
                    [self checkRequestFinishWithError:IAP_LOCALSTR_CheckReceiptFailed];
                }
            }
        }
        else {
            IAP_CHECK_LOG(@"err:err JSON result reason:returns JSON is not NSDictionary");
            [self checkRequestFinishWithError:IAP_LOCALSTR_CheckReceiptFailed];
        }
    }
}

@end
