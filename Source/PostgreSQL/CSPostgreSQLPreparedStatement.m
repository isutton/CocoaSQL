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
    int resultFormat = 0;    // ask for text results
    
    //
    // TODO: prepare values to feed PQexecPrepared.
    //
    if (values && [values count] > 0) {
        nParams = [values count];
        paramValues = malloc(nParams * sizeof(*paramValues));
        if (resultFormat) {
            paramLengths = calloc(nParams, sizeof(int));
            paramFormats = calloc(nParams, sizeof(int));
        }
        
        for (int i = 0; i < nParams; i++) {
            id value = [values objectAtIndex:i];
            
            if ([[value class] isSubclassOfClass:[NSNumber class]]) {
                paramValues[i] = [[(NSNumber *)value stringValue] UTF8String];
            }
            else if ([[value class] isSubclassOfClass:[NSString class]]) {
                paramValues[i] = [(NSString *)value UTF8String];
            }
            else if ([[value class] isSubclassOfClass:[NSData class]]) {
                if (resultFormat) {
                    paramFormats[i] = 1; // binary
                    paramLengths[i] = [value length];
                }
                paramValues[i] = [value bytes];
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
    
    NSMutableDictionary *row = [NSMutableDictionary dictionaryWithCapacity:numFields];
    
    for (int i = 0; i < numFields; i++) {
        CSQLResultValue *value;
        
        NSString *key = [NSString stringWithFormat:@"%s", PQfname(statement, i)];
        /* TODO - fix once using resultFormat == 1 
        if (PQfformat(statement, i))
            value = [CSQLResultValue valueWithData:[NSData dataWithBytes:PQgetvalue(statement, currentRow, i) length:PQfsize(statement, i)]];
        else*/
            value = [CSQLResultValue valueWithUTF8String:PQgetvalue(statement, currentRow, i)];

        [row setObject:value forKey:key];
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
        /* TODO - fix once using resultFormat == 1 
        if (PQfformat(statement, i))
            value = [CSQLResultValue valueWithData:[NSData dataWithBytes:PQgetvalue(statement, currentRow, i) length:PQfsize(statement, i)]];
        else*/
            value = [CSQLResultValue valueWithUTF8String:PQgetvalue(statement, currentRow, i)];

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
