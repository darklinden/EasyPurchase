//
//  ObjHolder.m
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import "ObjHolder.h"

__strong static ObjHolder *_holder = nil;

@interface ObjHolder ()
@property (nonatomic, strong) NSMutableDictionary *dict_container;

@end

@implementation ObjHolder

+ (id)sharedHolder
{
    if (!_holder) {
        _holder = [[ObjHolder alloc] init];
        _holder.dict_container = [NSMutableDictionary dictionary];
    }
    return _holder;
}

- (NSString *)uuid
{
	CFUUIDRef theUUID;
    
	CFStringRef theString;
    
	theUUID = CFUUIDCreate(NULL);
    
	theString = CFUUIDCreateString(NULL, theUUID);
    
	NSString *uuid = [NSString stringWithString:(id)theString];
    
	CFRelease(theString); CFRelease(theUUID); // Cleanup
    
	return uuid;
}

- (NSString *)pushObject:(NSObject *)object
{
    if (object) {
        NSString *ticket = [self uuid];
        [_dict_container setObject:object forKey:ticket];
        return ticket;
    }
    else {
        return nil;
    }
}

- (void)popObjectWithTicket:(NSString *)ticket
{
    if (ticket) {
        [_dict_container removeObjectForKey:ticket];
    }
    
    if (!_dict_container.allKeys.count) {
        self.dict_container = nil;
        _holder = nil;
    }
}

@end
