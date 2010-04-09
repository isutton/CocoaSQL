//
//  CSQLBindValue.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/29/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSQLBindValue.h"


@implementation CSQLBindValue

+ (id)bindValueWithData:(NSData *)aValue
{
    CSQLBindValue *value = [[CSQLBindValue alloc] initWithData:aValue];
    return [value autorelease];
}

- (id)initWithData:(NSData *)aValue
{
    if ([super init]) {
        value = [aValue retain];
        type = CSQLBlob;
        return self;
    }
    
    return nil;
}

+ (id)bindValueWithInt:(int)aValue
{
    CSQLBindValue *value = [[CSQLBindValue alloc] initWithInt:aValue];
    return [value autorelease];
}

- (id)initWithInt:(int)aValue
{
    if ([super init]) {
        value = [[NSNumber numberWithInt:aValue] retain];
        type = CSQLInteger;
        return self;
    }

    return nil;
}

+ (id)bindValueWithLong:(long)aValue
{
    CSQLBindValue *value = [[CSQLBindValue alloc] initWithLong:aValue];
    return [value autorelease];
}

- (id)initWithLong:(long)aValue
{
    if ([super init]) {
        value = [[NSNumber numberWithLong:aValue] retain];
        type = CSQLInteger;
        return self;
    }
    
    return nil;
}


+ (id)bindValueWithDouble:(double)aValue
{
    CSQLBindValue *value = [[CSQLBindValue alloc] initWithDouble:aValue];
    return [value autorelease];
}

- (id)initWithDouble:(double)aValue
{
    if ([super init]) {
        value = [[NSNumber numberWithDouble:aValue] retain];
        type = CSQLDouble;
        return self;
    }

    return nil;
}

+ (id)bindValueWithString:(NSString *)aValue
{
    CSQLBindValue *value = [[CSQLBindValue alloc] initWithString:aValue];
    return [value autorelease];
}

- (id)initWithString:(NSString *)aValue
{
    if ([super init]) {
        // better to retain it than the data than to make copies around
        value = [aValue retain]; 
        type = CSQLText;
        return self;
    }

    return nil;
}

+ (id)bindValueWithNull
{
    CSQLBindValue *value = [[CSQLBindValue alloc] initWithNull];
    return [value autorelease];
}

- (id)initWithNull
{
    if ([super init]) {
        value = nil;
        type = CSQLNull;
        return self;
    }
    
    return nil;
}

- (void)dealloc
{
    [value release];
    [super dealloc];
}

- (long)longValue
{
    if (type == CSQLInteger)
        return [value longValue];
    /* TODO - output a warning message */
    return 0;
}

- (int)intValue
{
    if (type == CSQLInteger)
        return [value intValue];
    /* TODO - output a warning message */
    return 0;
}

- (double)doubleValue
{
    if (type == CSQLDouble)
        return [value doubleValue];
    /* TODO - output a warning message */
    return 0;
}

- (NSData *)dataValue
{
    if (type == CSQLBlob)
        return (NSData *)value;
    return nil;
}

- (NSString *)stringValue
{
    if (type == CSQLText)
        return (NSString *)value;
    return nil;
}

- (CSQLBindValueType)type
{
    return type;
}

@end
