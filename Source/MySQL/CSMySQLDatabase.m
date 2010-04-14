//
//
//  This file is part of CocoaSQL
//
//  CocoaSQL is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with CocoaSQL.  If not, see <http://www.gnu.org/licenses/>.
//
//  CSMySQLDatabase.m by xant on 4/2/10.
//

#import "CSMySQLDatabase.h"
#import "CSMySQLPreparedStatement.h"
#include <mysql.h>

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
    mysql_init(databaseHandle);
    MYSQL *connected = mysql_real_connect(databaseHandle, 
                                          [host UTF8String],
                                          [user UTF8String],
                                          [password UTF8String],
                                          [databaseName UTF8String],
                                          0,
                                          NULL,
                                          0);

    if (!connected && mysql_ping(databaseHandle) != 0) {
        if (error) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
            NSString *errorMessage = [NSString stringWithFormat:@"Can't connect to database: %s", 
                                      mysql_error(databaseHandle)];
            [errorDetail setObject:errorMessage forKey:@"errorMessage"];
            *error = [NSError errorWithDomain:@"CSMySQLDatabase" code:500 userInfo:errorDetail];
            // XXX - I'm unsure if returning nil here is safe, 
            //       since an instance has been already alloc'd
            //       so if used with the idiom [[class alloc] init]
            //       the alloc'd pointer will be leaked
            return nil;            
        }
    }
    return self;
}

- (void)dealloc
{
    if (databaseHandle) {
        mysql_close(databaseHandle);
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
        if (!statement) {
            return -1;
        }
        if ([statement executeWithValues:values error:error])
            affectedRows = [(CSMySQLPreparedStatement *)statement affectedRows];
    }
    else {
        if (mysql_real_query(databaseHandle, [sql UTF8String], [sql length]) != 0) {
            if (error) {
                NSMutableDictionary *errorDetail;
                errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               [NSString stringWithFormat:@"%s", mysql_error(databaseHandle)], 
                               @"errorMessage", nil];
                *error = [NSError errorWithDomain:@"CSMySQL" code:99 userInfo:errorDetail];
            }
            return -1;
        }
        
        affectedRows = mysql_affected_rows(databaseHandle);

        if (callbackFunction) {
            res = mysql_use_result(databaseHandle);
            if (res) {
                MYSQL_FIELD *fields = mysql_fetch_fields(res);
                int nFields = mysql_num_fields(res);
                char **fieldNames = malloc(sizeof(char *)*nFields);
                while (row = mysql_fetch_row(res)) {
                    //unsigned long *fLengths = mysql_fetch_lengths(res);
                    // create a char ** which points to field names 
                    for (int i = 0; i < (int)nFields; i++)
                        fieldNames[i] = fields[i].name; // (don't copy them... it's a waste of time)

                    callbackFunction(context, nFields, row, fieldNames);
                }
                free(fieldNames);
                mysql_free_result(res);
            }
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

- (NSNumber *)lastInsertID
{
    my_ulonglong last_id = mysql_insert_id(databaseHandle);
    return [NSNumber numberWithLongLong:last_id];
}

- (NSNumber *)affectedRows
{
    my_ulonglong numRows = mysql_affected_rows(databaseHandle);
    return [NSNumber numberWithLongLong:numRows];
}

- (BOOL)isActive:(NSError **)error
{
    // TODO - return an error message
    // XXX - being not active is a perfectly valid condition ...
    //       so I don't really know what should be considered an error here
    if (databaseHandle)
        return (mysql_ping(databaseHandle) == 0) ? YES : NO;
    return NO;
}

- (BOOL)disconnect:(NSError **)error
{
    // TODO - return an error message
    // XXX - also here I can't see any error condition 
    //       which requires an explanatory message
    mysql_close(databaseHandle);
    databaseHandle = nil;
    return YES;
}

#pragma mark -
#pragma mark Prepared Statement messages

- (CSQLPreparedStatement *)prepareStatement:(NSString *)sql error:(NSError **)error
{
    return [CSMySQLPreparedStatement preparedStatementWithDatabase:self andSQL:sql error:error];
}

@end
