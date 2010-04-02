//
//  CSQLBindValue.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/29/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSQLBindValue.h"


@implementation CSQLBindValue

+ (id)bindValueWithInt:(int)aValue
{
    CSQLBindValue *value = [[CSQLBindValue alloc] initWithInt:aValue];
    return [value autorelease];
}

- (id)initWithInt:(int)aValue
{
    self = [super init];

    if (self) {
        value = [[NSNumber numberWithInt:aValue] retain];
        type = CSQLInteger;
    }

    return self;
}

+ (id)bindValueWithDouble:(double)aValue
{
    CSQLBindValue *value = [[CSQLBindValue alloc] initWithDouble:aValue];
    return [value autorelease];
}

- (id)initWithDouble:(double)aValue
{
    self = [super init];

    if (self) {
        value = [[NSNumber numberWithDouble:aValue] retain];
        type = CSQLDouble;
    }

    return self;
}

+ (id)bindValueWithString:(NSString *)aValue
{
    CSQLBindValue *value = [[CSQLBindValue alloc] initWithString:aValue];
    return [value autorelease];
}

- (id)initWithString:(NSString *)aValue
{
    self = [super init];

    if (self) {
        value = [aValue copy];
        type = CSQLText;
    }

    return self;
}

+ (id)bindValueWithNull
{
    CSQLBindValue *value = [[CSQLBindValue alloc] initWithNull];
    return [value autorelease];
}

- (id)initWithNull
{
    self = [super init];
    
    if (self) {
        value = nil;
        type = CSQLNull;
    }
    
    return self;
}

- (void)dealloc
{
    [value release];
    [super dealloc];
}

- (int)intValue
{
    NSNumber *value_ = value;
    return [value_ intValue];
}

- (CSQLBindValueType)type
{
    return type;
}

@end
