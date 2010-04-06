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

#pragma mark -

@implementation CSSQLitePreparedStatement

@synthesize sqlitePreparedStatement;

+ (id)preparedStatementWithDatabase:(id)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    CSSQLitePreparedStatement *preparedStatement;
    preparedStatement = (CSSQLitePreparedStatement *) [[CSSQLitePreparedStatement alloc] initWithDatabase:aDatabase andSQL:sql error:error];
    if (preparedStatement) {
        return [preparedStatement autorelease];
    }
    return nil;
}

- (id)initWithDatabase:(CSSQLiteDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    if (self = [super init]) {
        self.database = aDatabase;
        sqlite3_stmt *preparedStatement_;
        int errorCode = sqlite3_prepare_v2(aDatabase.sqliteDatabase, [sql UTF8String], [sql length], &preparedStatement_, NULL);
        if (errorCode != SQLITE_OK) {
            NSMutableDictionary *errorDetail;
            errorDetail = [NSMutableDictionary dictionary];
            NSString *errorMessage = [NSString stringWithFormat:@"%s", sqlite3_errmsg([aDatabase sqliteDatabase])];
            [errorDetail setObject:errorMessage forKey:@"errorMessage"];
            *error = [NSError errorWithDomain:@"CSSQLite" code:errorCode userInfo:errorDetail];
            return nil;
        }
        self.sqlitePreparedStatement = preparedStatement_;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark -
#pragma mark Bind messages

- (BOOL)bindIntValue:(int)aValue forColumn:(int)column
{
    return sqlite3_bind_int(sqlitePreparedStatement, column, aValue) == SQLITE_OK;
}

- (BOOL)bindDoubleValue:(double)aValue forColumn:(int)column
{
    return sqlite3_bind_double(sqlitePreparedStatement, column, aValue) == SQLITE_OK;
}

- (BOOL)bindStringValue:(NSString *)aValue forColumn:(int)column
{
    return SQLITE_OK == sqlite3_bind_text(sqlitePreparedStatement, column, [aValue cStringUsingEncoding:NSUTF8StringEncoding], [aValue length], SQLITE_STATIC);
}

- (BOOL)bindDataValue:(NSData *)aValue forColumn:(int)column
{
    return SQLITE_OK == sqlite3_bind_blob(sqlitePreparedStatement, column, [aValue bytes], [aValue length], SQLITE_STATIC);
}

- (BOOL)bindNullValueForColumn:(int)column
{
    return SQLITE_OK == sqlite3_bind_null(sqlitePreparedStatement, column);
}

#pragma mark -
#pragma mark Execute messages

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
    int bindParameterCount = sqlite3_bind_parameter_count(sqlitePreparedStatement);

    if (bindParameterCount > 0) {

        if (!values || [values count] < bindParameterCount) {
            NSMutableDictionary *errorDetail;
            errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Expected %i value(s), %i provided", bindParameterCount, [values count]], @"errorMessage", nil];
            *error = [NSError errorWithDomain:@"CSSQLite" code:100 userInfo:errorDetail];
            return NO;
        }
        
        for (int i = 1; i <= bindParameterCount; i++) {
            CSQLBindValue *value = [values objectAtIndex:i-1];
            BOOL success;
            switch ([value type]) {
                case CSQLInteger:
                    success = [self bindIntValue:[value intValue] forColumn:i];
                    break;
                case CSQLDouble:
                    success = [self bindDoubleValue:[value doubleValue] forColumn:i];
                    break;
                case CSQLText:
                    success = [self bindStringValue:[value stringValue] forColumn:i];
                    break;
                case CSQLBlob:
                    success = [self bindDataValue:[value dataValue] forColumn:i];
                    break;
                case CSQLNull:
                    success = [self bindNullValueForColumn:i];
                    break;
                default:
                    break;
            }
            
            if (!success) {
                CSSQLiteDatabase *database_ = (CSSQLiteDatabase *)self.database;
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
                NSString *errorMessage = [NSString stringWithFormat:@"%s", sqlite3_errmsg(database_.sqliteDatabase)];
                [errorDetail setObject:errorMessage forKey:@"errorMessage"];
                *error = [NSError errorWithDomain:@"CSQLite" code:101 userInfo:errorDetail];
                return NO;
            }
        }
    }

    int errorCode = sqlite3_step(self.sqlitePreparedStatement);
    
    if (errorCode == SQLITE_ERROR) {
        *error = [NSError errorWithDomain:@"CSSQLite" code:102 userInfo:nil];
        return NO;
    }

    if (errorCode == SQLITE_ROW) {
        canFetch = YES;
    }
    else {
        canFetch = NO;
    }

    if (errorCode == SQLITE_DONE) {
        sqlite3_reset(self.sqlitePreparedStatement);
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
    int columnCount;
    const char *columnName;
    id value;
    NSMutableDictionary *row;
    
    if (canFetch == NO) {
        return nil;
    }

    columnCount = sqlite3_column_count(sqlitePreparedStatement);
    row = [NSMutableDictionary dictionaryWithCapacity:columnCount];
    
    for (int i = 0; i < columnCount; i++) {
        value = translate(sqlitePreparedStatement, i);
        columnName = sqlite3_column_name(sqlitePreparedStatement, i);
        [row setObject:value forKey:[NSString stringWithFormat:@"%s", columnName]];
    }

    [self prepareNextFetch];
    
    return row;
}

@end

#pragma mark -

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
