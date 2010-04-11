//
//  NSMutableArray+CocoaSQL.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/31/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "NSMutableArray+CocoaSQL.h"

@implementation NSMutableArray (CocoaSQL)

- (void)bindDoubleValue:(double)aValue
{
    [self addObject:[NSNumber numberWithDouble:aValue]];
}

- (void)bindIntValue:(int)aValue
{
    [self addObject:[NSNumber numberWithInt:aValue]];
}

- (void)bindStringValue:(NSString *)aValue
{
    [self addObject:aValue];
}

- (void)bindDataValue:(NSData *)aValue
{
    [self addObject:aValue];
}

@end
