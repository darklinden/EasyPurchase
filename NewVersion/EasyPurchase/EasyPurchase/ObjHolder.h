//
//  ObjHolder.h
//  EasyPurchase
//
//  Created by darklinden on 14-9-15.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjHolder : NSObject

+ (id)sharedHolder;

//retain object returns holding ticket
- (NSString *)pushObject:(NSObject *)object;

//release object with ticket
- (void)popObjectWithTicket:(NSString *)ticket;

@end
