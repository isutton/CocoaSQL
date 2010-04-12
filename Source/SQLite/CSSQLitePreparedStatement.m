//
//  CSSQLitePreparedStatement.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/26/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSSQLitePreparedStatement.h"
#include <sqlite3.h>

static id translate(sqlite3_stmt *preparedStatement, int column)
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
            value = [NSNull null];
            break;
        default:
            break;
    }
    
    return value;
}

@interface CSSQLitePreparedStatement (Private)

/**
 
 Prepares the underlying sqlite3 prepared statement for the next fetch 
 operation, if any.
 
 */
- (void)prepareNextFetch;

@end

#pragma mark -

@implementation CSSQLitePreparedStatement

@synthesize statement;

- (id)initWithDatabase:(CSSQLiteDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    if (self = [super init]) {
        database = [aDatabase retain];
        sqlite3_stmt *statement_;
        int errorCode = sqlite3_prepare_v2(aDatabase.databaseHandle, [sql UTF8String], [sql length], &statement_, NULL);
        if (errorCode != SQLITE_OK) {
            if (error) {
                *error = [NSError errorWithMessage:[NSString stringWithFormat:@"%s", 
                                                    sqlite3_errmsg(aDatabase.databaseHandle)] 
                                           andCode:500];
            }
            return nil;
        }
        statement = statement_;
    }
    return self;
}

- (void)dealloc
{
    [self finish];
    [database release];
    [super dealloc];
}

#pragma mark -
#pragma mark Bind messages

- (BOOL)bindIntegerValue:(NSNumber *)aValue forColumn:(int)column
{
    return sqlite3_bind_int(statement, column, [aValue intValue]) == SQLITE_OK;
}

- (BOOL)bindDecimalValue:(NSDecimalNumber *)aValue forColumn:(int)column
{
    return sqlite3_bind_double(statement, column, [aValue doubleValue]) == SQLITE_OK;
}

- (BOOL)bindStringValue:(NSString *)aValue forColumn:(int)column
{
    return SQLITE_OK == sqlite3_bind_text(statement, column, [aValue cStringUsingEncoding:NSUTF8StringEncoding], [aValue length], SQLITE_STATIC);
}

- (BOOL)bindDataValue:(NSData *)aValue forColumn:(int)column
{
    return SQLITE_OK == sqlite3_bind_blob(statement, column, [aValue bytes], [aValue length], SQLITE_STATIC);
}

- (BOOL)bindNullValueForColumn:(int)column
{
    return SQLITE_OK == sqlite3_bind_null(statement, column);
}

- (BOOL)bindValue:(id)aValue forColumn:(int)column
{
    BOOL success = NO;
    Class valueClass = [aValue class];
    
    if ([valueClass isSubclassOfClass:[NSDecimalNumber class]]) {
        success = [self bindDecimalValue:(NSDecimalNumber *)aValue forColumn:column];
    }
    else if ([valueClass isSubclassOfClass:[NSNumber class]]) {
        success = [self bindIntegerValue:(NSNumber *)aValue forColumn:column];
    }
    else if ([valueClass isSubclassOfClass:[NSString class]]) {
        success = [self bindStringValue:(NSString *)aValue forColumn:column];
    }
    else if ([valueClass isSubclassOfClass:[NSData class]]) {
        success = [self bindDataValue:(NSData *)aValue forColumn:column];
    }
    else if ([valueClass isSubclassOfClass:[NSNull class]]) {
        success = [self bindNullValueForColumn:column];
    }
    
    return success;
    
}

#pragma mark -
#pragma mark Execute messages

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
    int bindParameterCount = sqlite3_bind_parameter_count(statement);

    if (bindParameterCount > 0 && values && [values count] > 0) {
        for (int i = 1; i <= bindParameterCount; i++) {
            id value = [values objectAtIndex:i-1];
            if (![self bindValue:value forColumn:i]) {
                *error = [NSError errorWithMessage:[NSString stringWithFormat:@"%s", 
                                                    sqlite3_errmsg(database.databaseHandle)]
                                           andCode:500];
                return NO;
            }
        }
    }

    int errorCode = sqlite3_step(statement);
    
    if (errorCode == SQLITE_ERROR) {
        if (error) {
            *error = [NSError errorWithMessage:[NSString stringWithFormat:@"%s", 
                                                sqlite3_errmsg(database.databaseHandle)]
                                       andCode:500];
        }
        return NO;
    }

    if (errorCode == SQLITE_ROW) {
        canFetch = YES;
    }
    else {
        canFetch = NO;
    }

    if (errorCode == SQLITE_DONE) {
        sqlite3_reset(statement);
    }
    
    return YES;
}

- (BOOL)execute:(NSError **)error
{
    return [self executeWithValues:nil error:error];
}

#pragma mark -
#pragma mark Fetch messages

- (NSArray *)fetchRowAsArray:(NSError **)error
{
    if (canFetch == NO) {
        return nil;
    }
    
    int columnCount = sqlite3_column_count(statement);
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:columnCount];
    for (int i = 0; i < columnCount; i++) {
        [row addObject:translate(statement, i)];
    }

    [self prepareNextFetch];
    
    return row;
}

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error
{
    int columnCount;
    const char *columnName;
    id value;
    NSMutableDictionary *row;
    
    if (canFetch == NO) {
        return nil;
    }

    columnCount = sqlite3_column_count(statement);
    row = [NSMutableDictionary dictionaryWithCapacity:columnCount];
    
    for (int i = 0; i < columnCount; i++) {
        value = translate(statement, i);
        columnName = sqlite3_column_name(statement, i);
        [row setObject:value forKey:[NSString stringWithFormat:@"%s", columnName]];
    }

    [self prepareNextFetch];
    
    return row;
}

- (BOOL)finish:(NSError **)error
{
    if (statement) {
        int errorCode = sqlite3_finalize(statement);
        
        if (errorCode != SQLITE_OK) {
            if (error) {
                *error = [NSError errorWithMessage:[NSString stringWithFormat:@"%s", 
                                                    sqlite3_errmsg(database.databaseHandle)]
                                           andCode:500];
            }
            return NO;
        }
        statement = NULL;
    }
    return YES;
}

- (BOOL)isActive:(NSError **)error
{
    return YES;
}

@end

#pragma mark -

@implementation CSSQLitePreparedStatement (Private)

- (void)prepareNextFetch
{
    int errorCode = sqlite3_step(statement);
    
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
