//
//  ObjHolder.m
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import "ObjHolder.h"

#if DEBUG
#import "O_weak_list.h"
__strong static O_weak_list *_mem_check = nil;
#endif

__strong static ObjHolder *_holder = nil;

@interface ObjHolder ()
@property (nonatomic, strong) NSMutableDictionary *dict_container;

@end

@implementation ObjHolder

+ (id)sharedHolder
{
#if DEBUG
    if (!_mem_check) {
        _mem_check = [O_weak_list list];
    }
#endif
    
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
    
	NSString *uuid = [NSString stringWithString:(__bridge id)theString];
    
	CFRelease(theString); CFRelease(theUUID); // Cleanup
    
	return uuid;
}

- (NSString *)pushObject:(NSObject *)object
{
    if (object) {
        NSString *ticket = [self uuid];
        [_dict_container setObject:object forKey:ticket];
#if DEBUG
        [_mem_check addObj:object];
        NSLog(@"ObjHolder objects after push: \n%@", _mem_check.allObjs);
#endif
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
    
#if DEBUG
    NSLog(@"ObjHolder objects after pop: \n%@", _mem_check.allObjs);
#endif
    
    if (!_dict_container.allKeys.count) {
        self.dict_container = nil;
        _holder = nil;
    }
}

+ (void)check_memory
{
#if DEBUG
    NSLog(@"ObjHolder holding objects: \n%@", [[ObjHolder sharedHolder] dict_container]);
    NSLog(@"ObjHolder living objects: \n%@", _mem_check.allObjs);
#endif
}

@end
