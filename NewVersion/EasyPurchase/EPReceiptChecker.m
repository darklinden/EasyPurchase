//
//  EPReceiptChecker.m
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import "EPReceiptChecker.h"
#import "ObjHolder.h"

#import <Security/Security.h>

#include <openssl/pkcs7.h>
#include <openssl/objects.h>
#include <openssl/sha.h>
#include <openssl/x509.h>
#include <openssl/err.h>

@implementation EPTransactionProduct

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, product_id: %@, transaction_id: %@, quantity: %lld>",
            [self class],
            self,
            _product_id,
            _transaction_id,
            (int64_t)_quantity];
}

@end

@interface EPReceiptChecker () <SKRequestDelegate>
{
    EPReceiptCheckerCompletionHandle _completionHandle;
}

@property (nonatomic, strong) NSString                  *ticket;
@property (nonatomic, strong) NSMutableArray            *passedProducts;

@property (nonatomic, assign) BOOL                      refreshable;

@property (nonatomic, strong) SKReceiptRefreshRequest   *request;
@property (nonatomic, strong) NSString                  *srcBundleId;
@property (nonatomic, strong) NSString                  *srcVersion;

@end

@implementation EPReceiptChecker

+ (void)checkReceiptWithBundleId:(const NSString *)bundleId
                         version:(const NSString *)version
                     refreshable:(BOOL)refreshable
                      completion:(EPReceiptCheckerCompletionHandle)completionHandle
{
    NSAssert([bundleId isEqualToString:[[NSBundle mainBundle] bundleIdentifier]], @"bundle id not equal");
    NSAssert([version isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"version not equal");
    
    EPReceiptChecker *checker = [[EPReceiptChecker alloc] init];
    checker.ticket = [[ObjHolder sharedHolder] pushObject:checker];
    checker.srcBundleId = (NSString *)bundleId;
    checker.srcVersion = (NSString *)version;
    checker.refreshable = refreshable;
    checker->_completionHandle = completionHandle;
    [checker parseReceipt];
}

- (void)dealloc
{
    _completionHandle = nil;
   self.passedProducts = nil;
   self.request = nil;
   self.srcBundleId = nil;
   self.srcVersion = nil;
}

#pragma mark - parse receipt

- (void)validateFailed
{
    if (_refreshable) {
        _refreshable = NO;
        self.passedProducts = nil;
        [self refreshReceipt];
    }
    else {
        if (_completionHandle) {
            _completionHandle(nil, EPErrorCheckReceiptFailed);
        }
        
        [[ObjHolder sharedHolder] popObjectWithTicket:_ticket];
    }
}

- (void)validateSuccess
{
    if (_completionHandle) {
        _completionHandle([_passedProducts copy], EPErrorSuccess);
    }
    
    [[ObjHolder sharedHolder] popObjectWithTicket:_ticket];
}

- (void)parsePurchaseProductsFromBuffer:(const uint8_t *)vp length:(long)vLenght
{
    //In-App Purchase Receipt Fields
    const int IRF_quantity                  = 1701;
    const int IRF_product_id                = 1702;
    const int IRF_transaction_id            = 1703;
    const int IRF_original_transaction_id   = 1705;
    const int IRF_purchase_date             = 1704;
    const int IRF_original_purchase_date    = 1706;
    const int IRF_expires_date              = 1708;
    const int IRF_cancellation_date         = 1712;
    const int IRF_web_order_line_item_id    = 1711;
    
    //prepare array
    if (!_passedProducts) {
        self.passedProducts = [NSMutableArray array];
    }
    
    int type = 0;
    int xclass = 0;
    long length = 0;
    
//    NSUInteger dataLenght = [data length];
    const uint8_t *p = vp;
    const uint8_t *end = p + vLenght;
    
    while (p < end) {
        ASN1_get_object(&p, &length, &type, &xclass, end - p);
        
        const uint8_t *set_end = p + length;
        
        if(type != V_ASN1_SET) {
            break;
        }
        
        EPTransactionProduct *product = [[EPTransactionProduct alloc] init];
        
        while (p < set_end) {
            ASN1_get_object(&p, &length, &type, &xclass, set_end - p);
            if (type != V_ASN1_SEQUENCE) {
                break;
            }
            
            const uint8_t *seq_end = p + length;
            
            int attr_type = 0;
            int attr_version = 0;
            
            // Attribute type
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            if (type == V_ASN1_INTEGER) {
                if(length == 1) {
                    attr_type = p[0];
                }
                else if(length == 2) {
                    attr_type = p[0] * 0x100 + p[1]
                    ;
                }
            }
            p += length;
            
            // Attribute version
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            if (type == V_ASN1_INTEGER && length == 1) {
                // clang analyser hit (wontfix at the moment, since the code might come in handy later)
                // But if someone has a convincing case throwing that out, I might do so, Roddi
                attr_version = p[0];
            }
            p += length;
            
            // Only parse attributes we're interested in
            if (IRF_quantity == attr_type
                || IRF_product_id == attr_type
                || IRF_transaction_id == attr_type
                || IRF_original_transaction_id == attr_type
                || IRF_purchase_date == attr_type
                || IRF_original_purchase_date == attr_type
                || IRF_expires_date == attr_type
                || IRF_cancellation_date == attr_type
                || IRF_web_order_line_item_id == attr_type) {
                
                ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
                if (type == V_ASN1_OCTET_STRING) {
                    //NSData *data = [NSData dataWithBytes:p length:(NSUInteger)length];
                    
                    // Integers
                    if (attr_type == IRF_quantity || attr_type == IRF_web_order_line_item_id) {
                        int num_type = 0;
                        long num_length = 0;
                        const uint8_t *num_p = p;
                        ASN1_get_object(&num_p, &num_length, &num_type, &xclass, seq_end - num_p);
                        if (num_type == V_ASN1_INTEGER) {
                            long get_int = 0;
                            if (num_length) {
                                get_int += num_p[0];
                                if (num_length > 1) {
                                    get_int += num_p[1] * 0x100;
                                    if (num_length > 2) {
                                        get_int += num_p[2] * 0x10000;
                                        if (num_length > 3) {
                                            get_int += num_p[3] * 0x1000000;
                                        }
                                    }
                                }
                            }
                            
                            if (attr_type == IRF_quantity) {
                                product.quantity = get_int;
                            }
                            else if (attr_type == IRF_web_order_line_item_id) {
                                product.web_order_line_item_id = get_int;
                            }
                        }
                    }
                    
                    // Strings
                    if (IRF_product_id == attr_type
                        || IRF_transaction_id == attr_type
                        || IRF_original_transaction_id == attr_type
                        || IRF_purchase_date == attr_type
                        || IRF_original_purchase_date == attr_type
                        || IRF_expires_date == attr_type
                        || IRF_cancellation_date == attr_type)
                    {
                        int str_type = 0;
                        long str_length = 0;
                        const uint8_t *str_p = p;
                        ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p);
                        if (str_type == V_ASN1_UTF8STRING) {
                            NSString *string = [[NSString alloc] initWithBytes:str_p
                                                                        length:(NSUInteger)str_length
                                                                      encoding:NSUTF8StringEncoding];
                            
                            switch (attr_type) {
                                case IRF_product_id:
                                    product.product_id = string;
                                    break;
                                case IRF_transaction_id:
                                    product.transaction_id = string;
                                    break;
                                case IRF_original_transaction_id:
                                    product.original_transaction_id = string;
                                    break;
                            }
                        }
                        
                        if (str_type == V_ASN1_IA5STRING) {
                            NSString *string = [[NSString alloc] initWithBytes:str_p
                                                                        length:(NSUInteger)str_length
                                                                      encoding:NSASCIIStringEncoding];
                            
                            //https://developer.apple.com/library/ios/qa/qa1480/_index.html date format
                            
                            NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
                            NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
                            
                            [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
                            [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
                            [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
                            
                            NSDate *date = [rfc3339DateFormatter dateFromString:string];
                            switch (attr_type) {
                                case IRF_purchase_date:
                                    product.purchase_date = date;
                                    break;
                                case IRF_original_purchase_date:
                                    product.original_purchase_date = date;
                                    break;
                                case IRF_expires_date:
                                    product.expires_date = date;
                                    break;
                                case IRF_cancellation_date:
                                    product.cancellation_date = date;
                                    break;
                            }
                        }
                    }
                }
                
                p += length;
            }
            
            // Skip any remaining fields in this SEQUENCE
            while (p < seq_end) {
                ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
                p += length;
            }
        }
        
        // Skip any remaining fields in this SET
        while (p < set_end) {
            ASN1_get_object(&p, &length, &type, &xclass, set_end - p);
            p += length;
        }
        
        [_passedProducts addObject:product];
    }
}

- (void)parseReceipt
{
    //App Receipt Fields
    const int ARF_bundle_id                     = 2;
    const int ARF_application_version           = 3;
    const int ARF_opaque_value                  = 4;
    const int ARF_sha1_hash                     = 5;
    const int ARF_in_app                        = 17;
    const int ARF_original_application_version  = 19;
    const int ARF_expiration_date               = 21;
    
    ERR_load_PKCS7_strings();
    ERR_load_X509_strings();
    OpenSSL_add_all_digests();
    
    // Expected input is a PKCS7 container with signed data containing
    // an ASN.1 SET of SEQUENCE structures. Each SEQUENCE contains
    // two INTEGERS and an OCTET STRING.
//    NSString *receiptPath = [[[NSBundle mainBundle] appStoreReceiptURL] path];
//    const char * path = [[receiptPath stringByStandardizingPath] fileSystemRepresentation];
//    FILE *fp = fopen(path, "rb");
//    if (fp == NULL) {
//        [self parseFailed];
//        return;
//    }
//    PKCS7 *p7 = d2i_PKCS7_fp(fp, NULL);
//    fclose(fp);
    
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    BIO *b_receipt = BIO_new_mem_buf((void *)[receiptData bytes], (int)[receiptData length]);
    
    //bio malloc and copied the data, so release it
    receiptData = nil;
    
    PKCS7 *p7 = d2i_PKCS7_bio(b_receipt, NULL);
    
    //bio memory management uses refrence count, use BIO_free to ref--
    BIO_free(b_receipt);
    
    // Check if the receipt file was invalid (otherwise we go crashing and burning)
    if (p7 == NULL) {
        [self validateFailed];
        return;
    }
    
    if (!PKCS7_type_is_signed(p7)) {
        PKCS7_free(p7);
        [self validateFailed];
        return;
    }
    
    if (!PKCS7_type_is_data(p7->d.sign->contents)) {
        PKCS7_free(p7);
        [self validateFailed];
        return;
    }
    
    int result = 0;
    X509_STORE *store = X509_STORE_new();
    if (store) {
        NSData *cerData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"AppleIncRootCertificate" withExtension:@"cer"]];
        BIO *b_x509 = BIO_new_mem_buf((void *)[cerData bytes], (int)[cerData length]);
        
        //bio malloc and copied the data, so release it
        cerData = nil;
        
//        X509 *appleCA = d2i_X509(NULL, &data, (long)rootCertData.length);
        X509 *appleRootCA = d2i_X509_bio(b_x509, NULL);
        
        BIO_free(b_x509);
        
        if (appleRootCA) {
            
            BIO *b_receiptPayload = BIO_new(BIO_s_mem());
            X509_STORE_add_cert(store, appleRootCA);
            
            if (b_receiptPayload) {
                // Verify the Signature
                result = PKCS7_verify(p7, NULL, store, NULL, b_receiptPayload, 0);
                BIO_free(b_receiptPayload);
            }
            
            X509_free(appleRootCA);
        }
        
        X509_STORE_free(store);
    }
    
    EVP_cleanup();
    
    if (result != 1) {
        PKCS7_free(p7);
        [self validateFailed];
        return;
    }
    
    // Receipt Signature is VALID
    // check id, version, and hash
    
    // p7 is the same PKCS7 Structure
    ASN1_OCTET_STRING *octets = p7->d.sign->contents->d.data;
    const uint8_t *p = octets->data;
    const uint8_t *end = p + octets->length;
    
    int type = 0;
    int xclass = 0;
    long length = 0;
    
    //get root object
    ASN1_get_object(&p, &length, &type, &xclass, end - p);
    if (type != V_ASN1_SET) {
        PKCS7_free(p7);
        [self validateFailed];
        return;
    }
    
    //temp var for check
    NSString *receipt_bundle_id                     = nil;
    NSString *receipt_application_version           = nil;
    NSString *receipt_original_application_version  = nil;
    NSDate   *receipt_expiration_date               = nil;
    
    NSData   *receipt_bundle_id_data                = nil;
    NSData   *receipt_opaque_value_data             = nil;
    NSData   *receipt_sha1_hash_data                = nil;
    
    while (p < end) {
        ASN1_get_object(&p, &length, &type, &xclass, end - p);
        if (type != V_ASN1_SEQUENCE) {
            break;
        }
        
        const uint8_t *seq_end = p + length;
        
        int attr_type = 0;
        int attr_version = 0;
        
        // Attribute type
        ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
        if (type == V_ASN1_INTEGER && length == 1) {
            attr_type = p[0];
        }
        p += length;
        
        // Attribute version
        ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
        if (type == V_ASN1_INTEGER && length == 1) {
            attr_version = p[0];
            attr_version = attr_version;
        }
        p += length;
        
        // Only parse attributes we're interested in
        if (ARF_bundle_id == attr_type
            || ARF_application_version == attr_type
            || ARF_opaque_value == attr_type
            || ARF_sha1_hash == attr_type
            || ARF_in_app == attr_type
            || ARF_original_application_version == attr_type
            || ARF_expiration_date == attr_type) {
            
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            if (type == V_ASN1_OCTET_STRING) {
                
                // Bytes
                // This is included for hash generation
                    switch (attr_type) {
                        case ARF_bundle_id:
                            receipt_bundle_id_data = [NSData dataWithBytes:p length:(NSUInteger)length];
                            break;
                        case ARF_opaque_value:
                            receipt_opaque_value_data = [NSData dataWithBytes:p length:(NSUInteger)length];
                            break;
                        case ARF_sha1_hash:
                            receipt_sha1_hash_data = [NSData dataWithBytes:p length:(NSUInteger)length];
                            break;
                    }
                
                // Strings
                if (ARF_bundle_id == attr_type
                    || ARF_application_version == attr_type
                    || ARF_original_application_version == attr_type
                    || ARF_expiration_date == attr_type) {
                    
                    int str_type = 0;
                    long str_length = 0;
                    const uint8_t *str_p = p;
                    ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p);
                    if (str_type == V_ASN1_UTF8STRING) {
                        NSString *string = [[NSString alloc] initWithBytes:str_p
                                                                    length:(NSUInteger)str_length
                                                                  encoding:NSUTF8StringEncoding];
                        
                        switch (attr_type) {
                            case ARF_bundle_id:
                                receipt_bundle_id = string;
                                break;
                            case ARF_application_version:
                                receipt_application_version = string;
                                break;
                            case ARF_original_application_version:
                                receipt_original_application_version = string;
                                break;
                        }
                    }
                    
                    if (str_type == V_ASN1_IA5STRING && ARF_expiration_date == attr_type) {
                        NSString *string = [[NSString alloc] initWithBytes:str_p
                                                                    length:(NSUInteger)str_length
                                                                  encoding:NSASCIIStringEncoding];
                        
                        //https://developer.apple.com/library/ios/qa/qa1480/_index.html date format
                        
                        NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
                        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
                        
                        [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
                        [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
                        [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
                        
                        receipt_expiration_date = [rfc3339DateFormatter dateFromString:string];
                    }
                }
                
                // In-App purchases
                if (attr_type == ARF_in_app) {
                    [self parsePurchaseProductsFromBuffer:p length:length];
                }
            }
            p += length;
        }
        
        // Skip any remaining fields in this SEQUENCE
        while (p < seq_end) {
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            p += length;
        }
    }
    
    //expiration_date check
    if (receipt_expiration_date) {
        NSDate *now = [NSDate date];
        if ([[receipt_expiration_date laterDate:now] isEqualToDate:now]) {
            PKCS7_free(p7);
            [self validateFailed];
            return;
        }
    }
    
    //hash check
    unsigned char uuidBytes[16];
    NSUUID *vendorUUID = [[UIDevice currentDevice] identifierForVendor];
    [vendorUUID getUUIDBytes:uuidBytes];
    
    NSMutableData *input = [NSMutableData data];
    [input appendBytes:uuidBytes length:sizeof(uuidBytes)];
    [input appendData:receipt_opaque_value_data];
    [input appendData:receipt_bundle_id_data];
    
    NSMutableData *hash = [NSMutableData dataWithLength:SHA_DIGEST_LENGTH];
    SHA1([input bytes], [input length], [hash mutableBytes]);
    
    if (![_srcBundleId isEqualToString:receipt_bundle_id]
        || ![_srcVersion isEqualToString:receipt_application_version]
        || ![hash isEqualToData:receipt_sha1_hash_data]) {
        PKCS7_free(p7);
        [self validateFailed];
        return;
    }
    
    PKCS7_free(p7);
    [self validateSuccess];
}

#pragma mark - refresh receipt only runs if receipt invalid
- (void)refreshReceipt
{
    self.request = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:@{}];
    _request.delegate = self;
    [_request start];
}

- (void)requestDidFinish:(SKRequest *)request
{
    [self parseReceipt];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    if (_completionHandle) {
        _completionHandle(nil, EPErrorRefreshReceiptFailed);
    }
    
    [[ObjHolder sharedHolder] popObjectWithTicket:_ticket];
}

@end
