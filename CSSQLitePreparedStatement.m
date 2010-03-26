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
        // FIXME: Populate NSError.
        return nil;
    }
    
    return self;
}

- (BOOL)executeWithValues:(NSArray *)values 
                    error:(NSError **)error
{
    int errorCode = sqlite3_step(sqlitePreparedStatement);
    
    if (errorCode != SQLITE_ERROR) {
        if (errorCode == SQLITE_ROW) {
            canFetch = YES;
        }
        return YES;
    }

    return NO;
}

- (BOOL)execute:(NSError **)error
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
