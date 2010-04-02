//
//  CSSQLitePreparedStatement.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/26/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSSQLitePreparedStatement.h"


@interface CSSQLitePreparedStatement (Private)

/**
 
 Prepares the underlying sqlite3 prepared statement for the next fetch 
 operation, if any.
 
 */
- (void)prepareNextFetch;

@end


@implementation CSSQLitePreparedStatement


+ (id)preparedStatementWithDatabase:(id)aDatabase 
                             andSQL:(NSString *)sql
                              error:(NSError **)error
{
    CSSQLitePreparedStatement *preparedStatement;
    preparedStatement = [[CSSQLitePreparedStatement alloc] initWithDatabase:aDatabase 
                                                                     andSQL:sql 
                                                                      error:error];
    
    if (preparedStatement) {
        return [preparedStatement autorelease];
    }
    
    return nil;
}

- (id)initWithDatabase:(id)aDatabase 
                andSQL:(NSString *)sql
                 error:(NSError **)error
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    CSSQLiteDatabase *database = aDatabase;

    int errorCode = sqlite3_prepare_v2([database sqliteDatabase], 
                                       [sql UTF8String], 
                                       [sql length], 
                                       &sqlitePreparedStatement, 
                                       NULL);
    
    if (errorCode != SQLITE_OK) {
        NSMutableDictionary *errorDetail;
        errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setObject:[NSString stringWithFormat:@"%s",
                                sqlite3_errmsg([database sqliteDatabase])]
                        forKey:@"errorMessage"];

        *error = [NSError errorWithDomain:@"CSSQLite"
                                     code:errorCode
                                 userInfo:errorDetail];
        return nil;
    }
    
    return self;
}

- (NSUInteger)executeWithValues:(NSArray *)values 
                          error:(NSError **)error
{
    int bindParameterCount = sqlite3_bind_parameter_count(sqlitePreparedStatement);

    if (bindParameterCount > 0) {

        if (!values || [values count] < bindParameterCount) {
            NSMutableDictionary *errorDetail;
            errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSString stringWithFormat:
                            @"Expected %i value(s), %i provided", 
                            bindParameterCount, [values count]],
                           @"errorMessage",
                           nil];
            *error = [NSError errorWithDomain:@"CSSQLite" code:100 
                                     userInfo:errorDetail];
            return NO;
        }
        
        for (int i = 1; i <= bindParameterCount; i++) {
            CSQLBindValue *value = [values objectAtIndex:i-1];
            
            int success;
            
            switch ([value type]) {
                case CSQLInteger:
                    success = sqlite3_bind_int(sqlitePreparedStatement, i, [value intValue]);
                    break;
                case CSQLDouble:
                    success = sqlite3_bind_double(sqlitePreparedStatement, i, [value doubleValue]);
                    break;
                case CSQLNull:
                    success = sqlite3_bind_null(sqlitePreparedStatement, i);
                    break;
                default:
                    break;
            }
            
            if (success != SQLITE_OK) {
                // FIXME: Check error and populate NSError.
            }
        }
    }

    int errorCode = sqlite3_step(sqlitePreparedStatement);
    
    if (errorCode == SQLITE_ERROR) {
        *error = [NSError errorWithDomain:@"CSSQLite" code:102 userInfo:nil];
        return NO;
    }

    canFetch = NO;
    
    if (errorCode == SQLITE_ROW) {
        canFetch = YES;
    }

    return YES;
}

- (NSUInteger)execute:(NSError **)error
{
    return [self executeWithValues:nil error:error];
}

- (NSArray *)fetchRowAsArray:(NSError **)error
{
    if (!canFetch) 
        return nil;
    
    int columnCount = sqlite3_column_count(sqlitePreparedStatement);
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:columnCount];
    for (int i = 0; i < columnCount; i++) {
        [row addObject:translate(sqlitePreparedStatement, i)];
    }

    [self prepareNextFetch];
    
    return row;
}

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error
{
    if (!canFetch)
        return nil;

    int columnCount = sqlite3_column_count(sqlitePreparedStatement);
    NSMutableDictionary *row = [NSMutableDictionary dictionaryWithCapacity:columnCount];
    for (int i = 0; i < columnCount; i++) {
        id value = translate(sqlitePreparedStatement, i);
        NSString *columnName = [NSString stringWithFormat:@"%s", sqlite3_column_name(sqlitePreparedStatement, i)];
        [row setObject:value forKey:columnName];
    }

    [self prepareNextFetch];
    
    return row;
}

- (void)dealloc
{
    [super dealloc];
}

@end

@implementation CSSQLitePreparedStatement (Private)

- (void)prepareNextFetch
{
    int errorCode = sqlite3_step(sqlitePreparedStatement);
    
    if (errorCode != SQLITE_ERROR) {
        if (errorCode == SQLITE_ROW) {
            canFetch = YES;
        }
        else if (errorCode == SQLITE_DONE) {
            canFetch = NO;
            
        }
    }    
}

@end

id translate(sqlite3_stmt *preparedStatement, int column)
{
    int columnType = sqlite3_column_type(preparedStatement, column);
    int rawValueLength = sqlite3_column_bytes(preparedStatement, column);
    sqlite3_value *rawValue = sqlite3_column_value(preparedStatement, column);
    
    id value;
    
    switch (columnType) {
        case SQLITE_FLOAT:
            value = [NSNumber numberWithDouble:sqlite3_value_double(rawValue)];
            break;
        case SQLITE_INTEGER:
            value = [NSNumber numberWithInt:sqlite3_value_int(rawValue)];
            break;
        case SQLITE_TEXT:
            value = [NSString stringWithFormat:@"%s", sqlite3_value_text(rawValue)];
            break;
        case SQLITE_BLOB:
            value = [NSData dataWithBytes:sqlite3_value_blob(rawValue) length:rawValueLength];
            break;
        case SQLITE_NULL:
            value = @"NULL";
            break;
        default:
            break;
    }

    return value;
}
