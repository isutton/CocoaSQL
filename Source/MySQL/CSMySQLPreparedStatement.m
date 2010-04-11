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

#pragma mark -
#pragma mark Internal Binds storage management

static id translate(MYSQL_BIND *bind)
{
    id value = nil;
    MYSQL_TIME *dateTime = NULL;
    time_t time = 0;
    struct tm unixTime;

    // XXX - actual implementation uses only strings and blobs
    switch(bind->buffer_type)
    {
        case MYSQL_TYPE_FLOAT:
            value = [NSNumber numberWithFloat:*((float *)bind->buffer)];
            break;
        case MYSQL_TYPE_SHORT:
            if (bind->is_unsigned)
                value = [NSNumber numberWithUnsignedShort:*((short *)bind->buffer)];
            else
                value = [NSNumber numberWithShort:*((short *)bind->buffer)];
            break;
        case MYSQL_TYPE_LONG:
            if (bind->is_unsigned)
                value = [NSNumber numberWithUnsignedLong:*((long *)bind->buffer)];
            else
                value = [NSNumber numberWithLong:*((long *)bind->buffer)];
            break;
        case MYSQL_TYPE_INT24:
            if (bind->is_unsigned)
                value = [NSNumber numberWithUnsignedInt:*((int *)bind->buffer)];
            else
                value = [NSNumber numberWithInt:*((int *)bind->buffer)];
            break;
        case MYSQL_TYPE_LONGLONG:
            if (bind->is_unsigned)
                value = [NSNumber numberWithUnsignedLongLong:*((long long *)bind->buffer)];
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
        // all mysql date/time datatypes are mapped to the MYSQL_TIME structure
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
    }
    return value;
}

static MYSQL_BIND *createResultBinds(MYSQL_FIELD *fields, int numFields)
{
    MYSQL_BIND *resultBinds = calloc(numFields, sizeof(MYSQL_BIND));
    for (int i = 0; i < numFields; i++) {
#if 0
        // everything apart blobs will be stringified
        if (fields[i].type == MYSQL_TYPE_BLOB || fields[i].type == MYSQL_TYPE_LONG_BLOB
            || fields[i].type == MYSQL_TYPE_TINY_BLOB)
        {
            resultBinds[i].buffer_type = MYSQL_TYPE_BLOB;
            resultBinds[i].buffer = calloc(1, MAX_BLOB_WIDTH);
            resultBinds[i].buffer_length = MAX_BLOB_WIDTH;
        } else {
            resultBinds[i].buffer_type = MYSQL_TYPE_STRING;
            resultBinds[i].buffer = calloc(1, 1024); // XXX 
            resultBinds[i].buffer_length = 1024;
        }
#else
        // more strict datatype mapping
        resultBinds[i].buffer_type = fields[i].type;
        switch(fields[i].type) {
            case MYSQL_TYPE_SHORT:
                resultBinds[i].buffer = calloc(1, sizeof(short));
                if (fields[i].flags & UNSIGNED_FLAG)
                    resultBinds[i].is_unsigned = 1;
                break;
            case MYSQL_TYPE_LONG:
                resultBinds[i].buffer = calloc(1, sizeof(long));
                if (fields[i].flags & UNSIGNED_FLAG)
                    resultBinds[i].is_unsigned = 1;
                break;
            case MYSQL_TYPE_INT24:
                resultBinds[i].buffer = calloc(1, sizeof(int));
                if (fields[i].flags & UNSIGNED_FLAG)
                    resultBinds[i].is_unsigned = 1;
                break;
            case MYSQL_TYPE_LONGLONG:
                resultBinds[i].buffer = calloc(1, sizeof(long long));
                if (fields[i].flags & UNSIGNED_FLAG)
                    resultBinds[i].is_unsigned = 1;
                break;
            case MYSQL_TYPE_TINY:
                resultBinds[i].buffer = calloc(1, sizeof(char));
                if (fields[i].flags & UNSIGNED_FLAG)
                    resultBinds[i].is_unsigned = 1;
            case MYSQL_TYPE_DOUBLE:
                resultBinds[i].buffer = calloc(1, sizeof(double));
                break;
            case MYSQL_TYPE_FLOAT:
                resultBinds[i].buffer = calloc(1, sizeof(float));
                break;
            case MYSQL_TYPE_DECIMAL:
                /* TODO - convert mysql type decimal */
                break;
                // XXX - unsure if varchars are returned with a fixed-length of 3 bytes or as a string
            case MYSQL_TYPE_VARCHAR:
            case MYSQL_TYPE_VAR_STRING:
            case MYSQL_TYPE_STRING:
                resultBinds[i].buffer = calloc(1, 1024); // perhaps oversized (isn't 256 max_string_size?)
                resultBinds[i].buffer_length = 1024;
                break;
            case MYSQL_TYPE_BIT:
                resultBinds[i].buffer = calloc(1, 1);
                break;
            case MYSQL_TYPE_TINY_BLOB:
            case MYSQL_TYPE_BLOB:
            case MYSQL_TYPE_LONG_BLOB:
                resultBinds[i].buffer = calloc(1, MAX_BLOB_WIDTH);
                resultBinds[i].buffer_length = MAX_BLOB_WIDTH;
                break;
                
            case MYSQL_TYPE_TIMESTAMP:
            case MYSQL_TYPE_DATETIME:
            case MYSQL_TYPE_DATE:
            case MYSQL_TYPE_TIME:
            case MYSQL_TYPE_NEWDATE:
#if 1
                // handle datetime & friends using the MYSQL_TIME structure
                resultBinds[i].buffer = calloc(1, sizeof(MYSQL_TIME));
                resultBinds[i].buffer_length = sizeof(MYSQL_TIME);
#else
                // handle dates as strings (mysql will convert them for us if we provide
                // a MYSQL_TYPE_STRING as buffer_type
                resultBinds[i].buffer_type = MYSQL_TYPE_STRING; // override the type
                // 23 characters for datetime strings of the type YYYY-MM-DD hh:mm:ss.xxx 
                // (assuming that microseconds will be supported soon or later)
                resultBinds[i].buffer = calloc(1, 23);
                resultBinds[i].buffer_length = 23;
#endif
                break;
        }
#endif
    }
    return resultBinds;
    
}

static void destroyResultBinds(MYSQL_BIND *resultBinds, int numFields)
{
    for (int i = 0; i < numFields; i++)
        free(resultBinds[i].buffer);
    free(resultBinds);
}

@implementation CSMySQLPreparedStatement

@synthesize statement;

#pragma mark -
#pragma mark Initializers

- (id)initWithDatabase:(CSMySQLDatabase *)aDatabase error:(NSError **)error
{
    [super init];
    resultBinds = nil;
    numFields = 0;
    self.database = aDatabase;
    self.statement = mysql_stmt_init(database.databaseHandle);
    if (!self.statement) {
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
    if (self.statement)
        mysql_stmt_close(statement);
    if (resultBinds)
        destroyResultBinds(resultBinds, numFields);
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
            if (error) {
                NSMutableDictionary *errorDetail;
                errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Expected %i value(s), %i provided", bindParameterCount, [values count]], @"errorMessage", nil];
                *error = [NSError errorWithDomain:@"CSMySQL" code:100 userInfo:errorDetail];
            }
            return NO;
        }
        
        // allocate memory to use as binding-storage for parameters.
        // worst case is when all parameters are of a certain type, 
        // so we allocate space to store enough items of each type 
        // (which means 'bindParameterCount' elements of each possible type)
        // possible types are actually 'long long', 'double' and 'MYSQL_TIME', 
        // so we are not going to waste that much memory. (considering also 
        // that the number of parameters will never be so huge)
        
        // integers will be stored as long long [ XXX - perhaps double is a better choice? ]
        long *lStorage = calloc(bindParameterCount, sizeof(long long));
        int  lStorageCount = 0;
        // doubles and floats will be both stored in a double
        double *dStorage = calloc(bindParameterCount, sizeof(double));
        int  dStorageCount = 0;
        // all date/time types will be stored in a MYSQL_TIME
        MYSQL_TIME *tStorage = calloc(bindParameterCount, sizeof(MYSQL_TIME));
        int  tStorageCount = 0;
        
        BOOL success = NO;
        for (int i = 0; i < bindParameterCount; i++) {
            id encapsulatedValue = [values objectAtIndex:i];
            Class valueClass = [encapsulatedValue class];
            if ([valueClass isSubclassOfClass:[CSQLBindValue class]]) {
                CSQLBindValue *value = (CSQLBindValue *)encapsulatedValue;
                switch ([value type]) {
                    case CSQLInteger:
                        lStorage[lStorageCount] = [value longValue];
                        params[i].buffer_type = MYSQL_TYPE_LONGLONG;
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
            else if ([valueClass isSubclassOfClass:[NSNumber class]])
            {
                NSNumber *value = (NSNumber *)encapsulatedValue;
                // get number as double so we will always have enough storage
                dStorage[lStorageCount] = [value doubleValue];
                params[i].buffer_type = MYSQL_TYPE_DOUBLE;
                params[i].buffer = &dStorage[dStorageCount];
                params[i].param_number = i;
                dStorageCount++;
            } 
            else if ([valueClass isSubclassOfClass:[NSString class]])
            {
                NSString *value = (NSString *)encapsulatedValue;
                params[i].buffer_type = MYSQL_TYPE_STRING;
                params[i].buffer = (void *)[value UTF8String]; // XXX
                params[i].buffer_length = [value length];  // XXX
            } 
            else if ([valueClass isSubclassOfClass:[NSDate class]])
            {
                NSDate *value = (NSDate *)encapsulatedValue;
                params[i].buffer_type = MYSQL_TYPE_DATETIME;
                time_t epoch = [value timeIntervalSince1970];
                struct tm *time = localtime(&epoch);
                tStorage[tStorageCount].year = time->tm_year+1900;
                tStorage[tStorageCount].month = time->tm_mon+1;
                tStorage[tStorageCount].day = time->tm_mday;
                tStorage[tStorageCount].hour = time->tm_hour;
                tStorage[tStorageCount].minute = time->tm_min;
                tStorage[tStorageCount].second = time->tm_sec;
                params[i].buffer = &tStorage[tStorageCount];
                params[i].param_number = i;
                tStorageCount++;
            }
            else if ([valueClass isSubclassOfClass:[NSData class]])
            {
                NSData *value = (NSData *)encapsulatedValue;
                params[i].buffer_type = MYSQL_TYPE_BLOB;
                params[i].buffer = (void *)[value bytes];
                params[i].buffer_length = [value length];
            }
            else // UNKNOWN DATATYPE
            {
                if (error) {
                    NSMutableDictionary *errorDetail;
                    errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Unknown datatatype %@", [valueClass className]], @"errorMessage", nil];
                    *error = [NSError errorWithDomain:@"CSMySQL" code:666 userInfo:errorDetail];
                }
                free(lStorage);
                free(dStorage);
                free(tStorage);
                free(params);                
                return NO;
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
        free(tStorage);
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

- (void)fetchRowWithBinds:(MYSQL_BIND *)binds error:(NSError **)error
{
    if (mysql_stmt_bind_result(statement, binds) != 0) {
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

    MYSQL_FIELD *fields = mysql_fetch_fields(mysql_stmt_result_metadata(statement));
    if (!resultBinds) {
        numFields = mysql_stmt_field_count(statement);
        resultBinds = createResultBinds(fields, numFields);
    }
    [self fetchRowWithBinds:resultBinds error:error];
    if (!canFetch) { // end of rows or error occurred
        // we can release the row-storage now
        [self finish];
        return nil;
    }
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:numFields];
    for (int i = 0; i < numFields; i++) 
        [row addObject:translate(&resultBinds[i])];
    
    return row;
}

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error
{
    int i;
    NSMutableDictionary *row = nil;
    
    if (canFetch == NO)
        return nil;
    
    numFields = mysql_stmt_field_count(statement);
    MYSQL_FIELD *fields = mysql_fetch_fields(mysql_stmt_result_metadata(statement));
    if (!resultBinds) {
        numFields = mysql_stmt_field_count(statement);
        resultBinds = createResultBinds(fields, numFields);
    }
    [self fetchRowWithBinds:resultBinds error:error];
    if (canFetch) {
        row = [NSMutableDictionary dictionaryWithCapacity:numFields];
        for (i = 0; i < numFields; i++) 
            [row setObject:translate(&resultBinds[i]) 
                    forKey:[NSString stringWithFormat:@"%s", fields[i].name]];
    } else { // end of rows or error occurred
        // we can release the row-storage now
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
        destroyResultBinds(resultBinds, numFields);
        resultBinds = nil;
        numFields = 0;
    }
    return YES;
}

@end
