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

#pragma mark -
#pragma mark Initialization and dealloc related messages

+ (id)databaseWithOptions:(NSDictionary *)options 
                                   error:(NSError **)error
{
    CSMySQLDatabase *database;
    NSString *dbName = (NSString *)[options objectForKey:@"db"];
    NSString *dbHost = (NSString *)[options objectForKey:@"host"];
    NSString *dbUser = (NSString *)[options objectForKey:@"user"];
    NSString *dbPass = (NSString *)[options objectForKey:@"password"];
    database = [CSMySQLDatabase databaseWithName:dbName
                                            User:dbUser
                                        Password:dbPass
                                            Host:dbHost ];
    return database;
}

+ (id)databaseWithName:(NSString *)dbName User:(NSString *)dbUser Password:(NSString *)dbPass Host:(NSString *)dbHost
{
    CSMySQLDatabase *database = [[CSMySQLDatabase alloc] initWithName:dbName
                                                                 Host:dbHost
                                                                 User:dbUser
                                                                 Pass:dbPass];

    return [database autorelease];
    
}

- (id)initWithName:(NSString *)dbName Host:(NSString *)dbHost User:(NSString *)dbUser Pass:(NSString *)dbPass
{

    mysql_init(&dbh);
    MYSQL *connected = mysql_real_connect(&dbh, 
                                          [dbHost UTF8String],
                                          [dbUser UTF8String],
                                          [dbPass UTF8String],
                                          [dbName UTF8String],
                                          0,
                                          NULL,
                                          0);
    if(!connected && mysql_ping(&dbh) != 0)
    {
        fprintf(stderr, "Error: Can't connect do mysql database: %s\n", mysql_error(&dbh));
        return nil;
    }
    return self;
}

- (void)dealloc
{
    mysql_close(&dbh);
    [super dealloc];
}

- (MYSQL *)mysqlDatabase
{
    return &dbh;
}

#pragma mark -
#pragma mark CSMySQLDatabase related messages

- (BOOL)executeSQL:(NSString *)sql
        withValues:(NSArray *)values
          callback:(CSMySQLCallback)callbackFunction 
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
            affectedRows = [statement affectedRows];
    }
    else {
        if (mysql_real_query(&dbh, [sql UTF8String], [sql length]) != 0) {
            // TODO - Error messages here
            return 0;
        }
        
        affectedRows = mysql_affected_rows(&dbh);

        res = mysql_use_result(&dbh);
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
                           callback:(CSMySQLCallback)mysqlRowAsArrayCallback 
                            context:row
                              error:error];
    
    if (!success) 
        return nil;
    
    return row;
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
                           callback:(CSMySQLCallback)mysqlRowAsDictionaryCallback 
                            context:row error:error];
    
    if (!success)
        return nil;
    
    return row;
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
                           callback:(CSMySQLCallback)mysqlRowsAsDictionariesCallback
                            context:rows
                              error:error];
    
    if (!success)
        return nil;
    
    return rows;
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
                           callback:(CSMySQLCallback)mysqlRowsAsArraysCallback
                            context:rows 
                              error:error];
    
    if (!success)
        return nil;
    
    return rows;
}

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                                error:(NSError **)error
{
    return [self fetchRowsAsArraysWithSQL:sql
                               withValues:nil
                                    error:error];
}

- (MYSQL *)MySQLDatabase
{
    return &dbh;
}

#pragma mark -
#pragma mark Prepared Statement messages

- (CSQLPreparedStatement *)prepareStatement:(NSString *)sql error:(NSError **)error
{
    return [CSMySQLPreparedStatement preparedStatementWithDatabase:self andSQL:sql error:error];
}

@end

#pragma mark -
#pragma mark MySQL callbacks

int mysqlRowAsArrayCallback(void *callbackContext,
                       int columnCount,
                       char **columnValues,
                       char **columnNames)
{
    NSMutableArray *row = callbackContext;
    
    for (int i = 0; i < columnCount; i++) {
        [row addObject:[NSString stringWithFormat:@"%s", columnValues[i]]];
    }
    
    return 0;
}

int mysqlRowAsDictionaryCallback(void *callbackContext,
                            int columnCount,
                            char **columnValues,
                            char **columnNames)
{
    NSMutableDictionary *row = callbackContext;
    
    for (int i = 0; i < columnCount; i++) {
        [row setObject:[NSString stringWithFormat:@"%s", columnValues[i]]
                forKey:[NSString stringWithFormat:@"%s", columnNames[i]]];
    }
    
    return 0;
}

int mysqlRowsAsDictionariesCallback(void *callbackContext,
                               int columnCount,
                               char **columnValues,
                               char **columnNames)
{
    NSMutableArray *rows = callbackContext;
    
    NSMutableDictionary *row = [NSMutableDictionary dictionaryWithCapacity:columnCount];
    
    for (int i = 0; i < columnCount; i++) {
        [row setObject:[NSString stringWithFormat:@"%s", columnValues[i]]
                forKey:[NSString stringWithFormat:@"%s", columnNames[i]]];
    }
    
    [rows addObject:row];
    
    return 0;
}

int mysqlRowsAsArraysCallback(void *callbackContext,
                         int columnCount,
                         char **columnValues,
                         char **columnNames)
{
    NSMutableArray *rows = callbackContext;
    
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:columnCount];
    
    for (int i = 0; i < columnCount; i++) {
        [row addObject:[NSString stringWithFormat:@"%s", columnValues[i]]];
    }
    
    [rows addObject:row];
    
    return 0;
}
