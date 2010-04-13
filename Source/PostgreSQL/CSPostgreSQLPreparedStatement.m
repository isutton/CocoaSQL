//
//  CSQLPostgreSQLPreparedStatement.m
//  CocoaSQL
//
//  Created by Igor Sutton on 4/13/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSPostgreSQLPreparedStatement.h"
#import <libpq-fe.h>

@implementation CSPostgreSQLPreparedStatement

- (CSQLPreparedStatement *)prepareStatementWithDatabase:(CSQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    CSPostgreSQLPreparedStatement *statement_ = [self initWithDatabase:aDatabase andSQL:sql error:error];
    return statement_;
}

- (id)initWithDatabase:(CSQLDatabase *)aDatabase error:(NSError **)error
{
    return [self initWithDatabase:aDatabase andSQL:nil error:error];
}

- (id)initWithDatabase:(CSQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    if (self = [super init]) {
        database = [aDatabase retain];
        
        PGresult *result = PQprepare(database.databaseHandle, "", [sql UTF8String], 0, nil);

        //
        // TODO: fill prepare statement return values.
        //
        if (!result) {
            [self getError:error];
        }
        
    }

    return self;
}

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
    BOOL returnValue = YES;
    
    //
    // TODO: prepare values to feed PQexecPrepared.
    //
    if (values && [values count] > 0) {
        
    }

    PGresult *result = PQexecPrepared(database.databaseHandle, "", 0, nil, nil, nil, 0);
    
    //
    // TODO: fill result status return values.
    //
    if (PQresultStatus(result) == PGRES_FATAL_ERROR) {
        canFetch = NO;
        returnValue = NO;
        [self getError:error];
    }
    else if (PQresultStatus(result) == PGRES_COMMAND_OK) {
        canFetch = NO;
    }
    else if (PQresultStatus(result) == PGRES_TUPLES_OK) {
        canFetch = YES;
    }

    PQclear(result);

    return YES;
}

- (void)getError:(NSError **)error
{
    if (error) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
        NSString *errorMessage = [NSString stringWithFormat:@"%s", PQerrorMessage(database.databaseHandle)];
        [errorDetail setObject:errorMessage forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:[[self class] description] code:100 userInfo:errorDetail];
    }
}

- (void)dealloc
{
    [database release];
    [super dealloc];
}

@end
