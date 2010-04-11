//
//  CSQLPreparedStatement.m
//  CocoaSQL
//
//  Created by Igor Sutton on 4/6/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CocoaSQL.h"

@implementation CSQLPreparedStatement

@synthesize canFetch;
@synthesize database;

+ (id)preparedStatementWithDatabase:(id)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    id preparedStatement;
    preparedStatement = [[self alloc] initWithDatabase:aDatabase andSQL:sql error:error];
    if (preparedStatement) {
        return [preparedStatement autorelease];
    }
    return nil;
}

- (id)initWithDatabase:(CSQLDatabase *)aDatabase
{
    return [self initWithDatabase:aDatabase error:nil];
}

- (id)initWithDatabase:(CSQLDatabase *)aDatabase error:(NSError **)error
{
    if (error) {
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
    }
    return nil;
}

- (id)initWithDatabase:(CSQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    return [self initWithDatabase:aDatabase error:error];
}

- (BOOL)setSQL:(NSString *)sql error:(NSError **)error
{
    if (error) {
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
    }
    return NO;
}

- (BOOL)setSQL:(NSString *)sql
{
    return [self setSQL:sql error:nil];
}

- (BOOL)isActive:(NSError **)error
{
    // MUST be overridden by subclasses
    if (error) {
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
    }
    return NO;
}

- (BOOL)isActive
{
    return [self isActive:nil];
}

- (BOOL)finish:(NSError **)error
{
    // MUST be overridden by subclasses
    if (error) {
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
    }
    return NO;
}

- (BOOL)finish
{
    return [self finish:nil];
}

- (BOOL)bindIntegerValue:(NSNumber *)aValue forColumn:(int)column
{
    // MUST be overridden by subclasses
    NSLog(@"bindIntegerValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL)bindDecimalValue:(NSDecimalNumber *)aValue forColumn:(int)column
{
    // MUST be overridden by subclasses
    NSLog(@"bindDecimalValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL)bindStringValue:(NSString *)aValue forColumn:(int)column
{
    // MUST be overridden by subclasses
    NSLog(@"bindStringValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL)bindDataValue:(NSData *)aValue forColumn:(int)column
{
    // MUST be overridden by subclasses
    NSLog(@"bindDataValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL)bindNullValueForColumn:(int)column
{
    // MUST be overridden by subclasses
    NSLog(@"bindNullValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL)bindValue:(id)aValue forColumn:(int)column;
{
    // MUST be overridden by subclasses
    NSLog(@"bindValue not implemented by %@\n", [self className]);
    return NO;
}

@end
