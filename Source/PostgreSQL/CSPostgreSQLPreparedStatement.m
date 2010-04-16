//
//
//  This file is part of CocoaSQL
//
//  CocoaSQL is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  CocoaSQL is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with CocoaSQL.  If not, see <http://www.gnu.org/licenses/>.
//
//  CSQLPostgreSQLPreparedStatement.h by Igor Sutton on 4/13/10.
//

#import "CSPostgreSQLPreparedStatement.h"
#import "CSQLResultValue.h"
#include <libpq-fe.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>

//
// TODO: Find the proper way to wire PostgreSQL basic data types.
//
#define BYTEAOID   17
#define CHAROID    18
#define TEXTOID    25
#define INT8OID    20
#define INT2OID    21
#define INT4OID    23
#define NUMERICOID 1700
#define VARCHAROID 1043

@interface CSPostgreSQLBindsStorage : NSObject
{
    int type;
    int length;
    char *value;
}

@end


@implementation CSPostgreSQLBindsStorage


@end


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
    if ([self init]) {
        database = [aDatabase retain];
        
        PGresult *result = PQprepare(database.databaseHandle, 
                                     "", 
                                     [sql UTF8String], 0, nil);

        if (![self handleResultStatus:result error:error]) {
            [self release];
            self = nil;
        }
    }

    return self;
}

- (id)init
{
    if (self = [super init]) {
        currentRow = 0;
    }
    
    return self;
}

- (BOOL)handleResultStatus:(PGresult *)result error:(NSError **)error
{
    BOOL returnValue = YES;
    BOOL clearResult = YES;
    
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
            clearResult = NO;
            statement = result;
        default:
            break;
    }
    
    if (clearResult) {
        PQclear(result);
        result = nil;
    }
    
    return returnValue;
}

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
    int nParams = 0;
    const char **paramValues = nil;
    int *paramLengths = nil; // don't need param lengths since text
    int *paramFormats = nil; // default to all text params
    int resultFormat = 0;    // ask for binary results
    
    int *mallocBookKeeping = nil;
    
    //
    // TODO: prepare values to feed PQexecPrepared.
    //
    if (values && [values count] > 0) {
        nParams = [values count];
        paramValues = malloc(nParams * sizeof(char *));
        mallocBookKeeping = calloc(nParams, sizeof(int));

        if (resultFormat) {
            paramLengths = calloc(nParams, sizeof(int));
            paramFormats = calloc(nParams, sizeof(int));
        }

        for (int i = 0; i < nParams; i++) {
            id value = [values objectAtIndex:i];
            
            if ([[value class] isSubclassOfClass:[NSNumber class]]) {
                if (resultFormat) {
                    uint32_t value_ = htonl((uint32_t)[value intValue]);
                    paramFormats[i] = 1;
                    paramLengths[i] = sizeof(uint32_t);
                    paramValues[i] = (char *)&value_;
                }
                else {
                    paramValues[i] = [[value stringValue] UTF8String];
                }

            }
            else if ([[value class] isSubclassOfClass:[NSString class]]) {
                if (resultFormat) {
                    paramFormats[i] = 1;
                    paramLengths[i] = sizeof([[value dataUsingEncoding:NSASCIIStringEncoding] bytes]);
                    paramValues[i] = [[value dataUsingEncoding:NSASCIIStringEncoding] bytes];
                }
                else {
                    paramValues[i] = [value cStringUsingEncoding:NSASCIIStringEncoding];
                }
            }
            else if ([[value class] isSubclassOfClass:[NSData class]]) {
                if (resultFormat) {
                    paramFormats[i] = 1; // binary
                    paramLengths[i] = [value length];
                }
                
#if 0
                //
                // For some reason, if I use
                //
                // paramValues[i] = [value bytes]
                //
                // It is given an extra byte (probably the '\0' character, which is
                // interpreted by the database as space. The following might be wrong,
                // but I got better results malloc'ing and copying the bytes using
                // getBytes:length:
                //
                // I suspect something is leaking here, because the tests randomly 
                // passes.
                //

                mallocBookKeeping[i] = 1;
                void *buffer = malloc([value length]);
                [value getBytes:buffer length:([value length] * sizeof(char))];
                paramValues[i] = buffer;
#else
                // 
                // Here we always get the extra byte, but at least it is consistent. Another
                // thing is that it always fails with the GC on.
                //
                paramValues[i] = [value bytes];
#endif
            }
        }
    }
    
    PGresult *result = PQexecPrepared(database.databaseHandle, 
                                      "",
                                      nParams, 
                                      paramValues, 
                                      paramLengths, 
                                      paramFormats, 
                                      resultFormat);
    
    if (values && [values count] > 0) {
        for (int i = 0; i < [values count]; i++) {
            if (mallocBookKeeping[i]) {
                free((char *)paramValues[i]);
            }
        }
        free(paramValues);
        if (resultFormat) {
            free(paramLengths);
            free(paramFormats);        
        }
    }
    
    return [self handleResultStatus:result error:error];
}

- (BOOL)finish:(NSError **)error
{
    if (statement) {
        PQclear(statement);
        statement = nil;
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

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error
{
    if (!canFetch)
        return nil;
    
    int numFields = PQnfields(statement);
    int numTuples = PQntuples(statement);
    
    if (currentRow == numTuples) {
        canFetch = NO;
        return nil;
    }
    
    PGresult *result = PQdescribePrepared(database.databaseHandle, "");
    
    NSMutableDictionary *row = [NSMutableDictionary dictionaryWithCapacity:numFields];

    //
    // The following block is the same as in fetchRowAsArray:error:. We need to refactor
    // it so both messages can use.
    //
    for (int i = 0; i < numFields; i++) {
        CSQLResultValue *value;
        int type = PQftype(statement, i);
        int length_ = PQgetlength(statement, currentRow, i);
        char *value_ = PQgetvalue(statement, currentRow, i);
        
        if (PQfformat(statement, i)) {
            switch (type) {
                case BYTEAOID:
                    value = [CSQLResultValue valueWithData:[NSData dataWithBytes:value_ length:length_-sizeof(char *)]];
                    break;
                case CHAROID:
                case TEXTOID:
                case VARCHAROID:
                    value = [CSQLResultValue valueWithUTF8String:value_];
                    break;
                case INT8OID:
                case INT4OID:
                case INT2OID:
                case NUMERICOID:
                    value = [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:ntohl(*(int *)value_)]];
                default:
                    break;
            }
        }            
        else {
            switch (type) {
                case BYTEAOID:
                    value = [CSQLResultValue valueWithData:[NSData dataWithBytes:value_ length:length_]];
                    break;
                default:
                    value = [CSQLResultValue valueWithUTF8String:value_];        
                    break;
            }
        }
        
        NSString *key = [NSString stringWithFormat:@"%s", PQfname(statement, i)];

        [row setObject:value forKey:key];
    }

    if (result) {
        PQclear(result);
        result = nil;
    }
    
    currentRow++;
    
    return row;
}

- (NSArray *)fetchRowAsArray:(NSError **)error
{
    if (!canFetch)
        return nil;
    
    int numFields = PQnfields(statement);
    int numTuples = PQntuples(statement);
    
    if (currentRow == numTuples) {
        canFetch = NO;
        return nil;
    }
    
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:numFields];
    
    for (int i = 0; i < numFields; i++) {
        CSQLResultValue *value;
        int type = PQftype(statement, i);
        int length_ = PQgetlength(statement, currentRow, i);
        char *value_ = PQgetvalue(statement, currentRow, i);
        
        if (PQfformat(statement, i)) {
            switch (type) {
                case BYTEAOID:
                    value = [CSQLResultValue valueWithData:[NSData dataWithBytes:value_ length:length_-sizeof(char *)]];
                    break;
                case CHAROID:
                case TEXTOID:
                case VARCHAROID:
                    value = [CSQLResultValue valueWithUTF8String:value_];
                    break;
                case INT8OID:
                case INT4OID:
                case INT2OID:
                case NUMERICOID:
                    value = [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:ntohl(*(int *)value_)]];
                default:
                    break;
            }
        }            
        else {
            switch (type) {
                case BYTEAOID:
                    value = [CSQLResultValue valueWithData:[NSData dataWithBytes:value_ length:length_]];
                    break;
                default:
                    value = [CSQLResultValue valueWithUTF8String:value_];        
                    break;
            }
        }
        
        [row addObject:value];
    }
    
    currentRow++;
    
    return row;
}

- (void)dealloc
{
    if (statement) {
        PQclear(statement);
        statement = nil;
    }
        
    [database release];
    [super dealloc];
}

@end
