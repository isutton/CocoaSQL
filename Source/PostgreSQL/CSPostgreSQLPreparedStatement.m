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

#import "CSPostgreSQLDatabase.h"
#import "CSPostgreSQLPreparedStatement.h"
#import "CSPostgreSQLRow.h"
#import "CSPostgreSQLBindsStorage.h"
#import "CSQLResultValue.h"

#include <libpq-fe.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <libkern/OSByteOrder.h>

@implementation CSPostgreSQLPreparedStatement

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
        binds = nil;
        row = nil;
    }
    return self;
}

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
    if (!binds)
        binds = [[[CSPostgreSQLBindsStorage alloc] initWithStatement:self andValues:values] retain];
    else
        [binds setValues:values];

    
    PGresult *result = PQexecPrepared(database.databaseHandle, 
                                      "", 
                                      [binds numParams], 
                                      (const char **)[binds paramValues], 
                                      [binds paramLengths], 
                                      [binds paramFormats], 
                                      [binds resultFormat]);
    
    
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

- (BOOL)getError:(NSError **)error
{
    if (error) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
        NSString *errorMessage = [NSString stringWithFormat:@"%s", PQerrorMessage(database.databaseHandle)];
        [errorDetail setObject:errorMessage forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:[[self class] description] code:100 userInfo:errorDetail];
    }
    return YES;
}

- (id)fetchRowWithSelector:(SEL)aSelector error:(NSError **)error
{
    if (!canFetch || currentRow == PQntuples(statement)) {
        canFetch = NO;
        return nil;
    }
    
    if (row) {
        [row setRow:currentRow++];
    }
    else {
        row = [[CSPostgreSQLRow rowWithStatement:self andRow:currentRow++] retain];
    }

    return [row performSelector:aSelector];
}

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error
{
    return [self fetchRowWithSelector:@selector(rowAsDictionary) error:error];
}

- (NSArray *)fetchRowAsArray:(NSError **)error
{
    return [self fetchRowWithSelector:@selector(rowAsArray) error:error];
}

- (void)dealloc
{
    if (statement) {
        PQclear(statement);
        statement = nil;
    }
    if (row)
        [row release];
    if (binds)
        [binds release];
    [database release];
    [super dealloc];
}

@end
