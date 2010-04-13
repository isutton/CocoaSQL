//
//  CSQLPostgreSQLDatabase.m
//  CocoaSQL
//
//  Created by Igor Sutton on 4/13/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSPostgreSQLDatabase.h"
#include <libpq-fe.h>

@implementation CSPostgreSQLDatabase

+ (CSQLDatabase *)databaseWithOptions:(NSDictionary *)options error:(NSError **)error
{
    CSQLDatabase *database = [[self alloc] initWithOptions:options error:error];
    if (database)
        return [database autorelease];
    return nil;
}

- (id)initWithOptions:(NSDictionary *)options error:(NSError **)error
{
    PGconn *databaseHandle_ = nil;
    
    if (self = [super init]) {
        databaseHandle_ = PQconnectdb("");
        if (databaseHandle_) {
            databaseHandle = (voidPtr)databaseHandle_;
        }
        return self;
    }
    return nil;
}

- (BOOL)disconnect:(NSError **)error
{
    if (databaseHandle) {
        PQfinish(databaseHandle);
        databaseHandle = nil;
    }
    return YES;
}

- (BOOL)isActive:(NSError **)error
{
    return PQstatus(databaseHandle) == CONNECTION_OK;
}

- (void)dealloc
{
    [self disconnect];
    [super dealloc];
}

@end
