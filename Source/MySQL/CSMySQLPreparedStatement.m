//
//  CSMySQLPreparedStatement.m
//  CocoaSQL
//
//  Created by xant on 4/6/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSMySQLPreparedStatement.h"
#import "CSMySQLDatabase.h"
#import "CSQLBindValue.h"

static id translate(MYSQL_BIND *bind)
{
    id value;
    // XXX - actual implementation uses only strings and blobs
    switch(bind->buffer_type)
    {
        case MYSQL_TYPE_FLOAT:
            value = [NSNumber numberWithFloat:*((float *)bind->buffer)];
            break;
        case MYSQL_TYPE_SHORT:
            value = [NSNumber numberWithShort:*((short *)bind->buffer)];
            break;
        case MYSQL_TYPE_LONG:
            value = [NSNumber numberWithLong:*((long *)bind->buffer)];
            break;
        case MYSQL_TYPE_INT24:
            value = [NSNumber numberWithLongLong:*((long long *)bind->buffer)<<8];
            break;
        case MYSQL_TYPE_LONGLONG:
            value = [NSNumber numberWithLongLong:*((long long *)bind->buffer)];
            break;
        case MYSQL_TYPE_DOUBLE:
            value = [NSNumber numberWithDouble:*((double *)bind->buffer)];
        case MYSQL_TYPE_TINY:
            value = [NSNumber numberWithChar:*((char *)bind->buffer)];
            break;
        case MYSQL_TYPE_DECIMAL:
            /* TODO - convert mysql type decimal */
             break;
        case MYSQL_TYPE_TIMESTAMP:
            break;
        case MYSQL_TYPE_DATETIME:
            break;
        case MYSQL_TYPE_DATE:
            break;
        case MYSQL_TYPE_TIME:
            break;
        case MYSQL_TYPE_YEAR:
            break;
        case MYSQL_TYPE_NEWDATE:
            break;
        // XXX - unsure if varchars are returned with a fixed-length of 3 bytes or as a string
        case MYSQL_TYPE_VARCHAR:
        case MYSQL_TYPE_VAR_STRING:
        case MYSQL_TYPE_STRING:
            value = [NSString stringWithUTF8String:(char *)bind->buffer];
            break;
        case MYSQL_TYPE_BIT:
            value = [NSNumber numberWithChar:*((char *)bind->buffer) & 0x01];
            break;
        case MYSQL_TYPE_TINY_BLOB:
        case MYSQL_TYPE_BLOB:
        case MYSQL_TYPE_LONG_BLOB:
            value = [NSData dataWithBytes:bind->buffer length:bind->buffer_length];
            break;
    }
    return value;
}

@implementation CSMySQLPreparedStatement

@synthesize statement;

- (id)initWithDatabase:(CSMySQLDatabase *)aDatabase error:(NSError **)error
{
    [super init];
    self.database = aDatabase;
    self.statement = mysql_stmt_init((MYSQL *)aDatabase.databaseHandle);
    if (!self.statement) {
        if (error) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
            [errorDetail setObject:[NSString stringWithFormat:@"%s", mysql_error((MYSQL *)database.databaseHandle)] 
                            forKey:@"errorMessage"];
            // XXX - which errorcode should be used here?
            *error = [NSError errorWithDomain:@"CSQLPreparedStatement" code:501 userInfo:errorDetail];
        }
        // XXX - I'm unsure if returning nil here is safe, 
        //       since an instance has been already alloc'd
        //       so if used with the idiom [[class alloc] init]
        //       the alloc'd pointer will be leaked
        return nil;
    }
    return self;
}

- (id)initWithDatabase:(CSMySQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    if ([self initWithDatabase:aDatabase]) {
        if (![self setSQL:sql error:error]) {
            mysql_stmt_close(statement);
            statement = nil;
            // XXX - I'm unsure if returning nil here is safe, 
            //       since an instance has been already alloc'd
            //       so if used with the idiom [[class alloc] init]
            //       the alloc'd pointer will be leaked
            return nil;
        }
        return self;
    }
    // same here
    return nil;
}

- (BOOL)setSQL:(NSString *)sql error:(NSError **)error
{
    int errorCode = mysql_stmt_prepare(statement, [sql UTF8String], [sql length]);
    if (errorCode != 0) {
        if (error) {
            NSMutableDictionary *errorDetail;
            errorDetail = [NSMutableDictionary dictionary];
            NSString *errorMessage = [NSString stringWithFormat:@"%s", 
                                      mysql_error((MYSQL *)database.databaseHandle)];
            [errorDetail setObject:errorMessage forKey:@"errorMessage"];
            *error = [NSError errorWithDomain:@"CSMySQL" code:errorCode userInfo:errorDetail];
        }
        return NO;
    }
    return YES;
}

- (void)dealloc
{
    if (self.statement) {
        mysql_stmt_close(statement);
    }
    [super dealloc];
}

#pragma mark -
#pragma mark Execute messages

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
    unsigned long bindParameterCount = mysql_stmt_param_count(self.statement);

    if (bindParameterCount > 0) {
        MYSQL_BIND *params = calloc(bindParameterCount, sizeof(MYSQL_BIND));

        if (!values || [values count] < bindParameterCount) {
            NSMutableDictionary *errorDetail;
            errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Expected %i value(s), %i provided", bindParameterCount, [values count]], @"errorMessage", nil];
            *error = [NSError errorWithDomain:@"CSMySQL" code:100 userInfo:errorDetail];
            return NO;
        }
        
        long *lStorage = calloc(bindParameterCount, sizeof(long));
        int  lStorageCount = 0;
        double *dStorage = calloc(bindParameterCount, sizeof(double));
        int  dStorageCount = 0;
        BOOL success = NO;

        for (int i = 0; i < bindParameterCount; i++) {
            CSQLBindValue *value = [values objectAtIndex:i];
            switch ([value type]) {
                case CSQLInteger:
                    lStorage[lStorageCount] = [value longValue];
                    params[i].buffer_type = MYSQL_TYPE_LONG;
                    params[i].buffer = &lStorage[lStorageCount];
                    params[i].param_number = i;
                    lStorageCount++;
                    break;
                case CSQLDouble:
                    dStorage[lStorageCount] = [value doubleValue];
                    params[i].buffer_type = MYSQL_TYPE_DOUBLE;
                    params[i].buffer = &dStorage[dStorageCount];
                    dStorageCount++;
                    break;
                case CSQLText:
                    params[i].buffer_type = MYSQL_TYPE_STRING;
                    params[i].buffer = (void *)[[value stringValue] UTF8String]; // XXX
                    params[i].buffer_length = [[value stringValue] length];  // XXX
                    break;
                case CSQLBlob:
                    params[i].buffer_type = MYSQL_TYPE_BLOB;
                    params[i].buffer = (void *)[[value dataValue] bytes];
                    params[i].buffer_length = [[value dataValue] length];
                    break;
                case CSQLNull:
                    params[i].buffer_type = MYSQL_TYPE_NULL;
                    break;
                default:
                    break;
            }
        }

        if (mysql_stmt_bind_param(self.statement, params) == 0) {
            if (mysql_stmt_execute(self.statement) == 0) {
                canFetch = YES;
                success = YES;
            }
        }
        free(lStorage);
        free(dStorage);
        free(params);
        if (!success) {
            if (error) {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
                NSString *errorMessage = [NSString stringWithFormat:@"%s", mysql_error(database.databaseHandle)];
                [errorDetail setObject:errorMessage forKey:@"errorMessage"];
                *error = [NSError errorWithDomain:@"CSMySQL" code:101 userInfo:errorDetail];
            }
            return NO;
        }
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
    int columnCount = mysql_stmt_field_count(statement);
    MYSQL_BIND *resultBindings = calloc(columnCount, sizeof(MYSQL_BIND));
    mysql_stmt_bind_result(statement, resultBindings);
    mysql_stmt_fetch(statement);
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:columnCount];
    for (int i = 0; i < columnCount; i++) {
        [row addObject:translate(&resultBindings[i])];
    }
    free(resultBindings);
    return row;
}

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error
{
    int columnCount;
    int i;
    id value;
    NSMutableDictionary *row = nil;
    
    if (canFetch == NO)
        return nil;
    
    columnCount = mysql_stmt_field_count(statement);
    MYSQL_FIELD *fields = mysql_fetch_fields(mysql_stmt_result_metadata(statement));
    MYSQL_BIND *resultBindings = calloc(columnCount, sizeof(MYSQL_BIND));
    for (i = 0; i < columnCount; i++) {
#if 0
        if (fields[i].type == MYSQL_TYPE_BLOB || fields[i].type == MYSQL_TYPE_LONG_BLOB
            || fields[i].type == MYSQL_TYPE_TINY_BLOB)
        {
            resultBindings[i].buffer_type = MYSQL_TYPE_BLOB;
            resultBindings[i].buffer = calloc(1, MAX_BLOB_WIDTH);
            resultBindings[i].buffer_length = MAX_BLOB_WIDTH;
        } else {
            resultBindings[i].buffer_type = MYSQL_TYPE_STRING;
            resultBindings[i].buffer = calloc(1, 1024); // XXX 
            resultBindings[i].buffer_length = 1024;
        }
#else
        resultBindings[i].buffer_type = fields[i].type;
        resultBindings[i].buffer = calloc(1, fields[i].db_length);
        resultBindings[i].buffer_length = fields[i].db_length;
#endif
    }
    if (mysql_stmt_bind_result(statement, resultBindings) != 0) {
        canFetch = NO;
        if (error) {
            NSMutableDictionary *errorDetail;
            errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%s", mysql_error(database.databaseHandle)], 
                            @"errorMessage", nil];
            *error = [NSError errorWithDomain:@"CSMySQL" code:101 userInfo:errorDetail];
        }
    }
    int ret = mysql_stmt_fetch(statement);
    if (ret != 0){
        canFetch = NO;
        // find a way to notify that data truncation happened
        if (error && ret != MYSQL_NO_DATA && ret != MYSQL_DATA_TRUNCATED) {  
            NSMutableDictionary *errorDetail;
            errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSString stringWithFormat:@"%s", mysql_error(database.databaseHandle)], 
                           @"errorMessage", nil];
            *error = [NSError errorWithDomain:@"CSMySQL" code:102 userInfo:errorDetail];
        }
    }
    
    if (canFetch) {
        row = [NSMutableDictionary dictionaryWithCapacity:columnCount];
        for (i = 0; i < columnCount; i++) {
            value = translate(&resultBindings[i]);
            [row setObject:value forKey:[NSString stringWithFormat:@"%s", fields[i].name]];
            free(resultBindings[i].buffer);
        }
    } else {
        for (i = 0; i < columnCount; i++)
            free(resultBindings[i].buffer);
    }
    free(resultBindings);
    return row;
}

- (int)affectedRows
{
    return mysql_stmt_affected_rows(statement);
}

@end
