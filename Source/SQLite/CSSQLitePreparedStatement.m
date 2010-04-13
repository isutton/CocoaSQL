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
    
    sqlite3_int64 signedValue;
    id value;
    
    switch (columnType) {
        case SQLITE_FLOAT:
            value = [CSQLResultValue valueWithNumber:[NSNumber numberWithDouble:sqlite3_value_double(rawValue)]];
            break;
        case SQLITE_INTEGER:
            //
            // Maybe this can be done differently, but I don't know how. The idea
            // is to get both signed and unsigned values, and use one or another
            // depending on its values.
            //
            signedValue = sqlite3_value_int64(rawValue);
            value = [CSQLResultValue valueWithNumber:[NSNumber numberWithLongLong:signedValue]];
            break;
        case SQLITE_TEXT:
            value = [CSQLResultValue valueWithString:[NSString stringWithFormat:@"%s", sqlite3_value_text(rawValue)]];
            break;
        case SQLITE_BLOB:
            value = [CSQLResultValue valueWithData:[NSData dataWithBytes:sqlite3_value_blob(rawValue) length:rawValueLength]];
            break;
        case SQLITE_NULL:
            value = [CSQLResultValue valueWithNull];
            break;
        default:
            break;
    }
    
    return value;
}

@interface CSSQLitePreparedStatement (Private)

- (void)prepareNextFetch;

@end

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

- (BOOL)bindIntegerValue:(NSNumber *)aValue toColumn:(int)index
{
    return sqlite3_bind_int64(statement, index, (sqlite3_int64)[aValue longLongValue]) == SQLITE_OK;
}

- (BOOL)bindDecimalValue:(NSDecimalNumber *)aValue toColumn:(int)index
{
    return sqlite3_bind_double(statement, index, [aValue doubleValue]) == SQLITE_OK;
}

- (BOOL)bindStringValue:(NSString *)aValue toColumn:(int)index
{
    return SQLITE_OK == sqlite3_bind_text(statement, index, [aValue cStringUsingEncoding:NSUTF8StringEncoding], [aValue length], SQLITE_STATIC);
}

- (BOOL)bindDataValue:(NSData *)aValue toColumn:(int)index
{
    return SQLITE_OK == sqlite3_bind_blob(statement, index, [aValue bytes], [aValue length], SQLITE_STATIC);
}

- (BOOL)bindNullValueToColumn:(int)index
{
    return SQLITE_OK == sqlite3_bind_null(statement, index);
}

- (BOOL)bindValue:(id)aValue toColumn:(int)index
{
    BOOL success = NO;
    Class valueClass = [aValue class];
    
    if ([valueClass isSubclassOfClass:[NSDecimalNumber class]]) {
        success = [self bindDecimalValue:(NSDecimalNumber *)aValue toColumn:index];
    }
    else if ([valueClass isSubclassOfClass:[NSNumber class]]) {
        success = [self bindIntegerValue:(NSNumber *)aValue toColumn:index];
    }
    else if ([valueClass isSubclassOfClass:[NSString class]]) {
        success = [self bindStringValue:(NSString *)aValue toColumn:index];
    }
    else if ([valueClass isSubclassOfClass:[NSData class]]) {
        success = [self bindDataValue:(NSData *)aValue toColumn:index];
    }
    else if ([valueClass isSubclassOfClass:[NSNull class]]) {
        success = [self bindNullValueToColumn:index];
    }
    
    return success;
    
}

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
    int bindParameterCount = sqlite3_bind_parameter_count(statement);

    if (bindParameterCount > 0 && values && [values count] > 0) {
        for (int i = 1; i <= bindParameterCount; i++) {
            id value = [values objectAtIndex:i-1];
            if (![self bindValue:value toColumn:i]) {
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
        statement = nil;
    }
    return YES;
}

- (BOOL)isActive:(NSError **)error
{
    return YES;
}

@end

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
