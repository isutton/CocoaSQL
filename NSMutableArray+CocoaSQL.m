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

@end
