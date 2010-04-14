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
        
        PGresult *result = PQprepare(database.databaseHandle, [[NSString stringWithFormat:@"%u", [self hash]] UTF8String], 
                                     [sql UTF8String], 0, nil);

        //
        // TODO: fill prepare statement return values.
        //
        switch (PQresultStatus(result)) {
            case PGRES_FATAL_ERROR:
                [self getError:error];
                break;
            default:
                break;
        }
        
        PQclear(result);
    }

    return self;
}

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
    BOOL returnValue = YES;
    
    int nParams = 0;
    const char **paramValues = nil;
    int *paramLengths = nil; // don't need param lengths since text
    int *paramFormats = nil; // default to all text params
    int resultFormat = 0;    // ask for text results
    
    //
    // TODO: prepare values to feed PQexecPrepared.
    //
    if (values && [values count] > 0) {
        nParams = [values count];
        paramValues = malloc(nParams * sizeof(*paramValues));
        
        for (int i = 0; i < nParams; i++) {
            id value = [values objectAtIndex:i];
            
            if ([[value class] isSubclassOfClass:[NSNumber class]]) {
                paramValues[i] = [[(NSNumber *)value stringValue] UTF8String];
            }
            else if ([[value class] isSubclassOfClass:[NSString class]]) {
                paramValues[i] = [(NSString *)value UTF8String];
            }
            else if ([[value class] isSubclassOfClass:[NSData class]]) {
                paramValues[i] = [(NSData *)value bytes];
            }
        }
        
    }

    PGresult *result = PQexecPrepared(database.databaseHandle, 
                                      [[NSString stringWithFormat:@"%u", [self hash]] UTF8String],
                                      nParams, 
                                      paramValues, 
                                      paramLengths, 
                                      paramFormats, 
                                      resultFormat);
    
    if (paramValues)
        free(paramValues);
    
    //
    // TODO: fill result status return values.
    //
    switch (PQresultStatus(result)) {
        case PGRES_FATAL_ERROR:
            canFetch = NO;
            returnValue = NO;
            [self getError:error];
            break;
        case PGRES_COMMAND_OK:
            canFetch = NO;
            break;
        case PGRES_TUPLES_OK:
            canFetch = YES;
            statement = result;
        default:
            break;
    }
    
    // We have rows to retrieve from the database, don't free the result value.
    if (PQresultStatus(result) != PGRES_TUPLES_OK) {
        PQclear(result);
    }

    return returnValue;
}

- (BOOL)finish
{
    if (statement) {
        PQclear(statement);
    }
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
