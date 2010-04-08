//
//  CSQLPreparedStatement.m
//  CocoaSQL
//
//  Created by Igor Sutton on 4/6/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSQLPreparedStatement.h"

@implementation CSQLPreparedStatement

@synthesize database;
@synthesize canFetch;

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
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
        [errorDetail setObject:@"Driver needs to implement this message." forKey:@"errorMessage"];
        *error = [NSError errorWithDomain:@"CSQLPreparedStatement" code:500 userInfo:errorDetail];
    }
    return nil;
}

- (id)initWithDatabase:(CSQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    return [self initWithDatabase:aDatabase error:error];
}

- (BOOL)setSql:(NSString *)sql error:(NSError **)error
{
    if (error) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
        [errorDetail setObject:@"Driver needs to implement this message." forKey:@"errorMessage"];
        *error = [NSError errorWithDomain:@"CSQLPreparedStatement" code:500 userInfo:errorDetail];
    }
    return NO;
}

- (BOOL)setSql:(NSString *)sql
{
    return [self setSql:sql error:nil];
}

@end
