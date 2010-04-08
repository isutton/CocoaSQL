//
//  CSMySQLDatabase.m
//  CocoaSQL
//
//  Created by xant on 4/2/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSMySQLDatabase.h"
#import "CSMySQLPreparedStatement.h"

@implementation CSMySQLDatabase

@dynamic databaseHandle;

#pragma mark -
#pragma mark Initialization and dealloc related messages

+ (id)databaseWithOptions:(NSDictionary *)options 
                    error:(NSError **)error
{
    CSMySQLDatabase *database;
    NSString *databaseName = (NSString *)[options objectForKey:@"db"];
    NSString *hostname = (NSString *)[options objectForKey:@"host"];
    NSString *user = (NSString *)[options objectForKey:@"user"];
    NSString *password = (NSString *)[options objectForKey:@"password"];
    database = [CSMySQLDatabase databaseWithName:databaseName
                                            host:hostname
                                            user:user
                                        password:password
                                           error:error];
    return database;
}

+ (id)databaseWithName:(NSString *)databaseName host:(NSString *)host user:(NSString *)user password:(NSString *)password error:(NSError **)error
{
    CSMySQLDatabase *database = [[CSMySQLDatabase alloc] initWithName:databaseName
                                                                 host:host
                                                                 user:user
                                                             password:password
                                                                error:error];

    return [database autorelease];
    
}

- (id)initWithName:(NSString *)databaseName host:(NSString *)host user:(NSString *)user password:(NSString *)password error:(NSError **)error
{
    databaseHandle = calloc(1, sizeof(MYSQL));
    mysql_init((MYSQL *)databaseHandle);
    MYSQL *connected = mysql_real_connect((MYSQL *)databaseHandle, 
                                          [host UTF8String],
                                          [user UTF8String],
                                          [password UTF8String],
                                          [databaseName UTF8String],
                                          0,
                                          NULL,
                                          0);
    if (!connected && mysql_ping((MYSQL *)databaseHandle) != 0) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
        NSString *errorMessage = [NSString stringWithFormat:@"Can't connect to database: %s", 
                                                            mysql_error((MYSQL *)databaseHandle)];
        [errorDetail setObject:errorMessage forKey:@"errorMessage"];
        *error = [NSError errorWithDomain:@"CSMySQLDatabase" code:500 userInfo:errorDetail];
        // XXX - I'm unsure if returning nil here is safe, 
        //       since an instance has been already alloc'd
        //       so if used with the idiom [[class alloc] init]
        //       the alloc'd pointer will be leaked
        return nil;
    }
    return self;
}

- (void)dealloc
{
    if (databaseHandle) {
        mysql_close((MYSQL *)databaseHandle);
        free(databaseHandle);
    }
    [super dealloc];
}

#pragma mark -
#pragma mark CSMySQLDatabase related messages

- (BOOL)executeSQL:(NSString *)sql
        withValues:(NSArray *)values
          callback:(CSQLCallback)callbackFunction
           context:(void *)context
             error:(NSError **)error;
{
    int affectedRows = 0;
    //int errorCode;
    //char *errorMessage;
    MYSQL_RES *res = NULL;
    MYSQL_ROW row;

    if (values && [values count] > 0) {
        CSQLPreparedStatement *statement = [self prepareStatement:sql error:error];
        if (!statement)
            return 0;
        if ([statement executeWithValues:values error:error])
            affectedRows = [(CSMySQLPreparedStatement *)statement affectedRows];
    }
    else {
        if (mysql_real_query((MYSQL *)databaseHandle, [sql UTF8String], [sql length]) != 0) {
            // TODO - Error messages here
            return 0;
        }
        
        affectedRows = mysql_affected_rows((MYSQL *)databaseHandle);

        res = mysql_use_result((MYSQL *)databaseHandle);
        if (res && callbackFunction) {
            MYSQL_FIELD *fields = mysql_fetch_fields(res);
            int nFields = mysql_num_fields(res);
            char **fieldNames = malloc(sizeof(char *)*nFields);
            while (row = mysql_fetch_row(res)) {
                //unsigned long *fLengths = mysql_fetch_lengths(res);
                // create a char ** which points to field names 
                // (don't copy them... it's a waste of time)
                for (int i = 0; i < (int)nFields; i++)
                    fieldNames[i] = fields[i].name;
                callbackFunction(context, nFields, row, fieldNames);
            }
            free(fieldNames);
        }
    }
    return affectedRows;
}

#pragma mark -
#pragma mark CSQLDatabase related messages
- (NSUInteger)executeSQL:(NSString *)sql 
              withValues:(NSArray *)values
                   error:(NSError **)error 
{
    return [self executeSQL:sql
                 withValues:values
                   callback:nil
                    context:nil
                      error:error];
}

- (NSUInteger)executeSQL:(NSString *)sql 
            error:(NSError **)error
{
    return [self executeSQL:sql
                 withValues:nil
                      error:error];
}

#pragma mark -
#pragma mark Row as Array

- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql 
                         withValues:(NSArray *)values 
                              error:(NSError **)error
{
    NSMutableArray *row = [NSMutableArray array];
    
    BOOL success = [self executeSQL:sql
                         withValues:values
                           callback:rowAsArrayCallback 
                            context:row
                              error:error];
    
    return success ? row : nil;
}

- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql 
                              error:(NSError **)error
{
    return [self fetchRowAsArrayWithSQL:sql
                             withValues:nil
                                  error:error];
}

#pragma mark -
#pragma mark Row as Dictionary

- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql 
                                   withValues:(NSArray *)values 
                                        error:(NSError **)error
{
    NSMutableDictionary *row = [NSMutableDictionary dictionary];
    
    BOOL success = [self executeSQL:sql withValues:values 
                           callback:rowAsDictionaryCallback 
                            context:row error:error];
    
    return success ? row : nil;
}

- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql 
                                        error:(NSError **)error
{
    return [self fetchRowAsDictionaryWithSQL:sql withValues:nil error:error];
}

#pragma mark -
#pragma mark Rows as Dictionaries

- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql 
                                 withValues:(NSArray *)values 
                                      error:(NSError **)error
{
    NSMutableArray *rows = [NSMutableArray array];
    
    BOOL success = [self executeSQL:sql
                         withValues:values
                           callback:rowsAsDictionariesCallback
                            context:rows
                              error:error];
    
    return success ? rows : nil;
}

- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql 
                                      error:(NSError **)error
{
    return [self fetchRowsAsDictionariesWithSQL:sql
                                     withValues:nil
                                          error:error];
}

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                           withValues:(NSArray *)values 
                                error:(NSError **)error
{
    NSMutableArray *rows = [NSMutableArray array];
    
    BOOL success = [self executeSQL:sql
                         withValues:values
                           callback:rowsAsArraysCallback
                            context:rows 
                              error:error];
    
    return success ? rows : nil;
}

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                                error:(NSError **)error
{
    return [self fetchRowsAsArraysWithSQL:sql
                               withValues:nil
                                    error:error];
}

#pragma mark -
#pragma mark Prepared Statement messages

- (CSQLPreparedStatement *)prepareStatement:(NSString *)sql error:(NSError **)error
{
    return [CSMySQLPreparedStatement preparedStatementWithDatabase:self andSQL:sql error:error];
}

@end
