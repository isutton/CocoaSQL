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
#include <mysql.h>

#pragma mark -
#pragma mark CSMysqlBindsStorage

@interface CSMysqlBindsStorage : NSObject {
    MYSQL_BIND *binds;
    int         numFields;
}

- (MYSQL_BIND *)binds;
- (id)getBoundColumn:(int)index;
- (id)initWithFields:(MYSQL_FIELD *)fields Count:(int)count;
- (id)initWithValues:(NSArray *)values;
- (BOOL)bindValue:(id)object toColumn:(int)index;
- (void)reset;
- (int)numFields;

@end

@implementation CSMysqlBindsStorage

- (void)dealloc
{
    [self reset];
    [super dealloc];
}

#pragma mark -
#pragma mark Internal Binds storage management

- (void)reset
{
    if (binds) {
        for (int i = 0; i < numFields; i++)
            if (binds[i].buffer)
                free(binds[i].buffer);
        free(binds);
        binds = NULL;
    }
    numFields = 0;
}

- (MYSQL_BIND *)binds
{
    return binds;
}

- (id)initWithValues:(NSArray *)values
{
    for (int i = 0; i < [values count]; i++) {
        if (![self bindValue:[values objectAtIndex:i] toColumn:i]) {
            [self reset];
            return nil; // XXX
        }
    }
    return self;
}

- (id)initWithFields:(MYSQL_FIELD *)fields Count:(int)count;
{
    if (binds)
        [self reset];
    numFields = count;
    binds = calloc(numFields, sizeof(MYSQL_BIND));
    for (int i = 0; i < numFields; i++) {
#if 0
        // everything apart blobs will be stringified
        if (fields[i].type == MYSQL_TYPE_BLOB || fields[i].type == MYSQL_TYPE_LONG_BLOB
            || fields[i].type == MYSQL_TYPE_TINY_BLOB)
        {
            binds[i].buffer_type = MYSQL_TYPE_BLOB;
            binds[i].buffer = calloc(1, MAX_BLOB_WIDTH);
            binds[i].buffer_length = MAX_BLOB_WIDTH;
        } else {
            binds[i].buffer_type = MYSQL_TYPE_STRING;
            binds[i].buffer = calloc(1, 1024); // XXX 
            binds[i].buffer_length = 1024;
        }
#else
        // more strict datatype mapping
        binds[i].buffer_type = fields[i].type;
        switch(fields[i].type) {
            case MYSQL_TYPE_NULL:
                binds[i].buffer = NULL;
                break;
            case MYSQL_TYPE_SHORT:
                binds[i].buffer = calloc(1, sizeof(short));
                if (fields[i].flags & UNSIGNED_FLAG)
                    binds[i].is_unsigned = 1;
                break;
            case MYSQL_TYPE_LONG:
                binds[i].buffer = calloc(1, sizeof(long));
                if (fields[i].flags & UNSIGNED_FLAG)
                    binds[i].is_unsigned = 1;
                break;
            case MYSQL_TYPE_INT24:
                binds[i].buffer = calloc(1, sizeof(int));
                if (fields[i].flags & UNSIGNED_FLAG)
                    binds[i].is_unsigned = 1;
                break;
            case MYSQL_TYPE_LONGLONG:
                binds[i].buffer = calloc(1, sizeof(long long));
                if (fields[i].flags & UNSIGNED_FLAG)
                    binds[i].is_unsigned = 1;
                break;
            case MYSQL_TYPE_TINY:
                binds[i].buffer = calloc(1, sizeof(char));
                if (fields[i].flags & UNSIGNED_FLAG)
                    binds[i].is_unsigned = 1;
            case MYSQL_TYPE_DOUBLE:
                binds[i].buffer = calloc(1, sizeof(double));
                break;
            case MYSQL_TYPE_FLOAT:
                binds[i].buffer = calloc(1, sizeof(float));
                break;
            case MYSQL_TYPE_DECIMAL:
                /* TODO - convert mysql type decimal */
                break;
                // XXX - unsure if varchars are returned with a fixed-length of 3 bytes or as a string
            case MYSQL_TYPE_VARCHAR:
            case MYSQL_TYPE_VAR_STRING:
            case MYSQL_TYPE_STRING:
                binds[i].buffer = calloc(1, 1024); // perhaps oversized (isn't 256 max_string_size?)
                binds[i].buffer_length = 1024;
                break;
            case MYSQL_TYPE_BIT:
                binds[i].buffer = calloc(1, 1);
                break;
            case MYSQL_TYPE_TINY_BLOB:
            case MYSQL_TYPE_BLOB:
            case MYSQL_TYPE_LONG_BLOB:
                binds[i].buffer = calloc(1, MAX_BLOB_WIDTH);
                binds[i].buffer_length = MAX_BLOB_WIDTH;
                break;
                
            case MYSQL_TYPE_TIMESTAMP:
            case MYSQL_TYPE_DATETIME:
            case MYSQL_TYPE_DATE:
            case MYSQL_TYPE_TIME:
            case MYSQL_TYPE_NEWDATE:
#if 1
                // handle datetime & friends using the MYSQL_TIME structure
                binds[i].buffer = calloc(1, sizeof(MYSQL_TIME));
                binds[i].buffer_length = sizeof(MYSQL_TIME);
#else
                // handle dates as strings (mysql will convert them for us if we provide
                // a MYSQL_TYPE_STRING as buffer_type
                binds[i].buffer_type = MYSQL_TYPE_STRING; // override the type
                // 23 characters for datetime strings of the type YYYY-MM-DD hh:mm:ss.xxx 
                // (assuming that microseconds will be supported soon or later)
                binds[i].buffer = calloc(1, 23);
                binds[i].buffer_length = 23;
#endif
                break;
        }
#endif
    }
    return self;
}

- (id)getBoundColumn:(int)index
{
    id value = nil;
    MYSQL_TIME *dateTime = NULL;
    time_t time = 0;
    struct tm unixTime;
    
    if (index >= numFields) { // safety belts
        // TODO - Erorr messages
        return nil;
    }
    MYSQL_BIND *bind = &binds[index];
    if (bind->is_null_value) { // mysql returned a NULL value
        value = [NSNull null];
    } else {
        switch(bind->buffer_type)
        {
            case MYSQL_TYPE_FLOAT:
                value = [NSNumber numberWithFloat:*((float *)bind->buffer)];
                break;
            case MYSQL_TYPE_SHORT:
                if (bind->is_unsigned)
                    value = [NSNumber numberWithUnsignedShort:*((unsigned short *)bind->buffer)];
                else
                    value = [NSNumber numberWithShort:*((short *)bind->buffer)];
                break;
            case MYSQL_TYPE_LONG:
                if (bind->is_unsigned)
                    value = [NSNumber numberWithUnsignedLong:*((unsigned long *)bind->buffer)];
                else
                    value = [NSNumber numberWithLong:*((long *)bind->buffer)];
                break;
            case MYSQL_TYPE_INT24:
                if (bind->is_unsigned)
                    value = [NSNumber numberWithUnsignedInt:*((unsigned int *)bind->buffer)];
                else
                    value = [NSNumber numberWithInt:*((int *)bind->buffer)];
                break;
            case MYSQL_TYPE_LONGLONG:
                if (bind->is_unsigned)
                    value = [NSNumber numberWithUnsignedLongLong:*((unsigned long long *)bind->buffer)];
                else
                    value = [NSNumber numberWithLongLong:*((long long *)bind->buffer)];
                break;
            case MYSQL_TYPE_DOUBLE:
                value = [NSNumber numberWithDouble:*((double *)bind->buffer)];
            case MYSQL_TYPE_TINY:
                value = [NSNumber numberWithChar:*((char *)bind->buffer)];
                break;
            case MYSQL_TYPE_DECIMAL:
                // XXX - decimals are actually bound to either float or double
                // so we will never hit this case
                break;
                // all mysql date/time datatypes are stored in a MYSQL_TIME structure
            case MYSQL_TYPE_TIMESTAMP:
            case MYSQL_TYPE_DATETIME:
            case MYSQL_TYPE_DATE:
            case MYSQL_TYPE_TIME:
            case MYSQL_TYPE_YEAR:
            case MYSQL_TYPE_NEWDATE:
                // convert the MYSQL_TIME structure to epoch
                // so that we can than build an NSDate object on top of it
                dateTime = (MYSQL_TIME *)bind->buffer;
                memset(&unixTime, 0, sizeof(unixTime));
                unixTime.tm_year = dateTime->year-1900;
                unixTime.tm_mon = dateTime->month-1;
                unixTime.tm_mday = dateTime->day;
                unixTime.tm_hour = dateTime->hour;
                unixTime.tm_min = dateTime->minute;
                unixTime.tm_sec = dateTime->second;
                // mktime is not re-entrant ... but anyway, we don't neeed to be thread-safe (yet) :)
                time = mktime(&unixTime); 
                value = [NSDate dateWithTimeIntervalSince1970:time];
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
            case MYSQL_TYPE_NULL:
            default: // unknown datatype will be null-ed
                value = [NSNull null];
                break;
        }
    }
    return value;    
}

- (BOOL)bindValue:(id)aValue toColumn:(int)index
{
    if (index >= numFields) {
        binds = realloc(binds, sizeof(MYSQL_BIND) * (index+1));
        // ensure zero-ing just allocated storage
        memset(binds+numFields, 0, sizeof(MYSQL_BIND) * (index - numFields +1));
        numFields = index+1;
    }

    binds[index].param_number = index;
    Class valueClass = [aValue class];
    if ([valueClass isSubclassOfClass:[CSQLBindValue class]]) {
        CSQLBindValue *value = (CSQLBindValue *)aValue;
        switch ([value type]) {
            case CSQLInteger:
                binds[index].buffer = malloc(sizeof(long long));
                *((long long *)binds[index].buffer) = [value longValue];
                binds[index].buffer_type = MYSQL_TYPE_LONGLONG;
                break;
            case CSQLDouble:
                binds[index].buffer = malloc(sizeof(double));
                *((double *)binds[index].buffer) = [value doubleValue];
                binds[index].buffer_type = MYSQL_TYPE_DOUBLE;
                break;
            case CSQLText:
                binds[index].buffer_type = MYSQL_TYPE_STRING;
                // XXX - we are copying the string :(
                binds[index].buffer = (void *)strdup([[value stringValue] UTF8String]);
                binds[index].buffer_length = [[value stringValue] length];  // XXX
                break;
            case CSQLBlob:
                binds[index].buffer_type = MYSQL_TYPE_BLOB;
                // XXX - we are copying the buffer :(
                binds[index].buffer = (void *)[[value dataValue] copy];
                binds[index].buffer_length = [[value dataValue] length];
                break;
            case CSQLNull:
                binds[index].buffer_type = MYSQL_TYPE_NULL;
                break;
            default:
                break;
        }
    }
    else if ([valueClass isSubclassOfClass:[NSNumber class]])
    {
        NSNumber *value = (NSNumber *)aValue;
        binds[index].buffer = malloc(sizeof(double));
        // get number as double so we will always have enough storage
        *((double *)binds[index].buffer) = [value doubleValue];
        binds[index].buffer_type = MYSQL_TYPE_DOUBLE;
    }
    else if ([valueClass isSubclassOfClass:[NSString class]])
    {
        NSString *value = (NSString *)aValue;
        binds[index].buffer_type = MYSQL_TYPE_STRING;
        // XXX - we are copying the string :(
        binds[index].buffer = (void *)strdup([value UTF8String]);
        binds[index].buffer_length = [value length]; // XXX - does length return 
                                                     // the bytelength of the buffer?
    }
    else if ([valueClass isSubclassOfClass:[NSDate class]])
    {
        NSDate *value = (NSDate *)aValue;
        binds[index].buffer_type = MYSQL_TYPE_DATETIME;
        time_t epoch = [value timeIntervalSince1970];
        struct tm *time = localtime(&epoch);
        binds[index].buffer = malloc(sizeof(MYSQL_TIME));
        ((MYSQL_TIME *)binds[index].buffer)->year = time->tm_year+1900;
        ((MYSQL_TIME *)binds[index].buffer)->month = time->tm_mon+1;
        ((MYSQL_TIME *)binds[index].buffer)->day = time->tm_mday;
        ((MYSQL_TIME *)binds[index].buffer)->hour = time->tm_hour;
        ((MYSQL_TIME *)binds[index].buffer)->minute = time->tm_min;
        ((MYSQL_TIME *)binds[index].buffer)->second = time->tm_sec;
        binds[index].buffer = binds[index].buffer;
    }
    else if ([valueClass isSubclassOfClass:[NSData class]])
    {
        NSData *value = (NSData *)aValue;
        binds[index].buffer_type = MYSQL_TYPE_BLOB;
        // XXX - we are copying the buffer :(
        binds[index].buffer = (void *)[value copy];
        binds[index].buffer_length = [value length];
    } else if ([valueClass isSubclassOfClass:[NSNull class]])
    {
        // null value
        binds[index].buffer_type = MYSQL_TYPE_NULL;
        binds[index].buffer = NULL; // XXX - not necessary since it has been calloc'd
    }
    else // UNKNOWN DATATYPE
    {
        return NO;
    }
    return YES;
}

- (int)numFields
{
    return numFields;
}

@end

@implementation CSMySQLPreparedStatement

@synthesize statement;

#pragma mark -
#pragma mark Initializers

- (id)initWithDatabase:(CSMySQLDatabase *)aDatabase error:(NSError **)error
{
    [super init];
    resultBinds = nil;
    database = [aDatabase retain];
    statement = mysql_stmt_init(database.databaseHandle);
    if (!statement) {
        if (error) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
            [errorDetail setObject:[NSString stringWithFormat:@"%s", mysql_error(database.databaseHandle)] 
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
    // ensure resetting the old statement if the caller 
    // is reusing an our instance to execute another query
    [self finish];
    int errorCode = mysql_stmt_prepare(statement, [sql UTF8String], [sql length]);
    if (errorCode != 0) {
        if (error) {
            NSMutableDictionary *errorDetail;
            errorDetail = [NSMutableDictionary dictionary];
            NSString *errorMessage = [NSString stringWithFormat:@"%s", 
                                      mysql_error(database.databaseHandle)];
            [errorDetail setObject:errorMessage forKey:@"errorMessage"];
            *error = [NSError errorWithDomain:@"CSMySQL" code:errorCode userInfo:errorDetail];
        }
        return NO;
    }
    return YES;
}

- (void)dealloc
{
    if (statement)
        mysql_stmt_close(statement);
    if (resultBinds)
        [resultBinds release];
    if (paramBinds)
        [paramBinds release];
    [database release];
    [super dealloc];
}

#pragma mark -
#pragma mark Execute messages

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
    unsigned long bindParameterCount = mysql_stmt_param_count(statement);

    if (bindParameterCount > 0) {
        BOOL success = NO;

        if (values) {
            if (paramBinds) // release old paramBinds if any
                [paramBinds release];
            paramBinds = [CSMysqlBindsStorage alloc];
            for (int i = 0; i < bindParameterCount; i++) {
                if (![paramBinds bindValue:[values objectAtIndex:i] toColumn:i]) {
                    if (error) {
                        NSMutableDictionary *errorDetail;
                        errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [NSString stringWithFormat:@"Unknown datatatype %@",
                                            [[values objectAtIndex:i] className]], 
                                       @"errorMessage", 
                                       nil];
                        *error = [NSError errorWithDomain:@"CSMySQL" code:666 userInfo:errorDetail];
                    } 
                }
            }
            
        } 
        if (!paramBinds || [paramBinds numFields] < bindParameterCount) {
            if (error) {
                NSMutableDictionary *errorDetail;
                errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               [NSString stringWithFormat:@"Expected %i value(s), %i provided", 
                                    bindParameterCount, [values count]], 
                               @"errorMessage",
                               nil];
                *error = [NSError errorWithDomain:@"CSMySQL" code:100 userInfo:errorDetail];
            }
            if (paramBinds) {
                [paramBinds release];
                paramBinds = nil;
            }
            return NO;
        }

        if (mysql_stmt_bind_param(statement, [paramBinds binds]) == 0) {
            if (mysql_stmt_execute(statement) == 0) {
                canFetch = YES;
                success = YES;
            }
        }
        // we can already release storage for paramBinds since  we don't need it anymore
        // (it would have be freed anyway at [finish] or when dealloc'd ... 
        //  but why keeping that stuff in memory if we don't need it?)
        [paramBinds release];
        paramBinds = nil;
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

- (void)fetchRow:(NSError **)error
{
    if (mysql_stmt_bind_result(statement, [resultBinds binds]) != 0) {
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
}

- (NSArray *)fetchRowAsArray:(NSError **)error
{
    if (canFetch == NO)
        return nil;
    int numFields = mysql_stmt_field_count(statement);
    MYSQL_FIELD *fields = mysql_fetch_fields(mysql_stmt_result_metadata(statement));
    if (!resultBinds) {
        resultBinds = [[CSMysqlBindsStorage alloc] 
                       initWithFields:fields 
                       Count:numFields
                      ];
    }
    [self fetchRow:error];
    if (!canFetch) { // end of rows or error occurred
        // we can release the row-storage now
        [self finish];
        return nil;
    }
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:numFields];
    for (int i = 0; i < numFields; i++)
        [row insertObject:[resultBinds getBoundColumn:i] atIndex:i];
    
    return row;
}

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error
{
    int i;
    NSMutableDictionary *row = nil;
    
    if (canFetch == NO)
        return nil;
    
    int numFields = mysql_stmt_field_count(statement);
    MYSQL_FIELD *fields = mysql_fetch_fields(mysql_stmt_result_metadata(statement));
    if (!resultBinds) {
        resultBinds = [[CSMysqlBindsStorage alloc] 
                       initWithFields:fields 
                       Count:numFields
                       ];
    }
    [self fetchRow:error];
    if (canFetch) {
        row = [NSMutableDictionary dictionaryWithCapacity:numFields];
        for (i = 0; i < numFields; i++) {
            NSString *fieldName = [NSString stringWithFormat:@"%s", fields[i].name];
            [row setObject:[resultBinds getBoundColumn:i] forKey:fieldName];
        }
    } else { // end of rows or error occurred
        // we can release the row-storage now.
        // if an error occurred the 'error' pointer 
        // has been already set properly (by fetchRowWithBinds)
        [self finish];
        return nil;
    }
    return row;
}

- (int)affectedRows
{
    return mysql_stmt_affected_rows(statement);
}

- (BOOL)isActive:(NSError **)error
{
    // TODO - return an error message (XXX - but what?)
    return canFetch;
}

- (BOOL)finish:(NSError **)error
{
    // TODO - return an error message 
    // XXX - (also here...we will never have an error condition
    mysql_stmt_reset(statement);
    if (resultBinds) {
        [resultBinds release];
        resultBinds = nil;
    }
    return YES;
}

#pragma mark -
#pragma mark bindValue accessors

- (BOOL)bindIntegerValue:(NSNumber *)aValue toColumn:(int)index
{
    if (!paramBinds)
        paramBinds = [CSMysqlBindsStorage alloc];
    return [paramBinds bindValue:aValue toColumn:index];
}

- (BOOL)bindDecimalValue:(NSDecimalNumber *)aValue toColumn:(int)index
{
    if (!paramBinds)
        paramBinds = [CSMysqlBindsStorage alloc];
    return [paramBinds bindValue:aValue toColumn:index];
}

- (BOOL)bindStringValue:(NSString *)aValue toColumn:(int)index
{
    if (!paramBinds)
        paramBinds = [CSMysqlBindsStorage alloc];
    return [paramBinds bindValue:aValue toColumn:index];
}

- (BOOL)bindDataValue:(NSData *)aValue toColumn:(int)index
{
    if (!paramBinds)
        paramBinds = [CSMysqlBindsStorage alloc];
    return [paramBinds bindValue:aValue toColumn:index];
}

- (BOOL)bindNullValueForColumn:(int)index
{
    if (!paramBinds)
        paramBinds = [CSMysqlBindsStorage alloc];
    return [paramBinds bindValue:[NSNull null] toColumn:index];
}

- (BOOL)bindValue:(id)aValue toColumn:(int)index;
{
    if (!paramBinds)
        paramBinds = [CSMysqlBindsStorage alloc];
    return [paramBinds bindValue:aValue toColumn:index];
}

@end
