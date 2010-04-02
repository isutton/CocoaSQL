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
    CSQLBindValue *value = [CSQLBindValue bindValueWithDouble:aValue];
    [self addObject:value];
}

- (void)bindIntValue:(int)aValue
{
    CSQLBindValue *value = [CSQLBindValue bindValueWithInt:aValue];
    [self addObject:value];
}

- (void)bindStringValue:(NSString *)aValue
{
    CSQLBindValue *value = [CSQLBindValue bindValueWithString:aValue];
    [self addObject:value];
}

- (void)bindDataValue:(NSData *)aValue
{
    CSQLBindValue *value = [CSQLBindValue bindValueWithData:aValue];
    [self addObject:value];
}

@end
