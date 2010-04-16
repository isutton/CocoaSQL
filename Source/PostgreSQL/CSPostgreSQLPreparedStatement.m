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
    int numParams;
    int *paramTypes;
    int *paramLengths;
    int *paramFormats;
    char **paramValues;
    int resultFormat;
}

@property (readonly) int numParams;
@property (readonly) int *paramTypes;
@property (readonly) int *paramLengths;
@property (readonly) int *paramFormats;
@property (readonly) char **paramValues;
@property (readonly) int resultFormat;

- (id)initWithValues:(NSArray *)values;
- (BOOL)bindValue:(id)aValue toColumn:(int)index;

@end


@implementation CSPostgreSQLBindsStorage

@synthesize numParams;
@synthesize paramTypes;
@synthesize paramLengths;
@synthesize paramFormats;
@synthesize paramValues;
@synthesize resultFormat;

- (id)initWithValues:(NSArray *)values
{
    if ([self init]) {
        resultFormat = 0;
        numParams = [values count];
        paramValues = malloc([values count] * sizeof(char *));
        paramLengths = calloc([values count], sizeof(int));
        paramFormats = calloc([values count], sizeof(int));
        paramTypes = calloc([values count], sizeof(int));
        
        for (int i = 0; i < [values count]; i++) {
            [self bindValue:[values objectAtIndex:i] toColumn:i];
        }
    }
    return self;
}

- (BOOL)bindValue:(id)aValue toColumn:(int)index
{
    if ([[aValue class] isSubclassOfClass:[NSNumber class]]) {
        if (resultFormat) {
            uint32_t value_ = htonl((uint32_t)[aValue intValue]);
            paramFormats[index] = 1;
            paramLengths[index] = sizeof(uint32_t);
            paramValues[index] = (char *)&value_;
        }
        else {
            paramValues[index] = (char *)[[aValue stringValue] UTF8String];
        }
        
    }
    else if ([[aValue class] isSubclassOfClass:[NSString class]]) {
        if (resultFormat) {
            paramFormats[index] = 1;
            paramLengths[index] = sizeof([[aValue dataUsingEncoding:NSASCIIStringEncoding] bytes]);
            paramValues[index] = (char *)[[aValue dataUsingEncoding:NSASCIIStringEncoding] bytes];
        }
        else {
            paramValues[index] = (char *)[aValue cStringUsingEncoding:NSASCIIStringEncoding];
        }
    }
    else if ([[aValue class] isSubclassOfClass:[NSData class]]) {
        if (resultFormat) {
            paramFormats[index] = 1; // binary
            paramLengths[index] = [aValue length];
        }
        paramValues[index] = (char *)[aValue bytes];
    }
    
    return YES;
}

- (void)dealloc
{
    free(paramValues);
    free(paramLengths);
    free(paramFormats);
    free(paramTypes);
    [super dealloc];
}

@end

@interface CSPostgreSQLRow : NSObject
{
    int row;
    int numFields;
    CSPostgreSQLPreparedStatement *statement_;
}

@property (readonly) int numFields;

- (id)initWithStatement:(CSPostgreSQLPreparedStatement *)statement andRow:(int)index;
- (id)objectForColumn:(int)index;
- (id)nameForColumn:(int)index;

@end

@implementation CSPostgreSQLRow

@synthesize numFields;

- (id)initWithStatement:(CSPostgreSQLPreparedStatement *)statement andRow:(int)index
{
    row = index;
    statement_ = [statement retain];
    numFields = PQnfields(statement_.statement);
    return self;
}

- (BOOL)isBinary:(int)index
{
    return PQfformat(statement_.statement, index) == 1;
}

- (int)lengthForColumn:(int)index
{
    return PQgetlength(statement_.statement, row, index);
}

- (int)typeForColumn:(int)index
{
    return PQftype(statement_.statement, index);
}

- (char *)valueForColumn:(int)index
{
    return PQgetvalue(statement_.statement, row, index);
}

- (id)objectForColumn:(int)index
{
    CSQLResultValue *value;

    int type = [self typeForColumn:index];
    int length_ = [self lengthForColumn:index];
    char *value_ = [self valueForColumn:index];
    
    if ([self isBinary:index]) {
        switch (type) {
            case BYTEAOID:
                value = [CSQLResultValue valueWithData:[NSData dataWithBytes:value_ length:length_]];
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
    return value;
}

- (id)nameForColumn:(int)index
{
    return [NSString stringWithUTF8String:PQfname(statement_.statement, index)];
}

- (void)dealloc
{
    [statement_ release];
    [super dealloc];
}
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
    id binds = [[CSPostgreSQLBindsStorage alloc] initWithValues:values];

    PGresult *result = PQexecPrepared(database.databaseHandle, 
                                      "", 
                                      [binds numParams], 
                                      (const char **)[binds paramValues], 
                                      [binds paramLengths], 
                                      [binds paramFormats], 
                                      [binds resultFormat]);
    
    [binds release];
    
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
    
    CSPostgreSQLRow *row_ = [[CSPostgreSQLRow alloc] initWithStatement:self andRow:currentRow];
    
    if (currentRow == PQntuples(statement)) {
        canFetch = NO;
        return nil;
    }
    
    NSMutableDictionary *row = [NSMutableDictionary dictionaryWithCapacity:row_.numFields];
    for (int i = 0; i < row_.numFields; i++) {
        [row setObject:[row_ objectForColumn:i] forKey:[row_ nameForColumn:i]];
    }

    currentRow++;
    
    return row;
}

- (NSArray *)fetchRowAsArray:(NSError **)error
{
    if (!canFetch)
        return nil;
 
    CSPostgreSQLRow *row_ = [[CSPostgreSQLRow alloc] initWithStatement:self andRow:currentRow];

    if (currentRow == PQntuples(statement)) {
        canFetch = NO;
        return nil;
    }
    
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:row_.numFields];
    
    for (int i = 0; i < row_.numFields; i++) {
        [row addObject:[row_ objectForColumn:i]];
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
