//
//  CSMySQL.h
//  CocoaSQL
//
//  Created by xant on 4/2/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CSQLDatabase.h"
//#import "CSMySQLPreparedStatement.h"

#include <mysql.h>

typedef int (*CSMySQLCallback)(void *, int, char**, char**);

@interface CSMySQLDatabase : CSQLDatabase {
    MYSQL mysqlDatabase;
}

- (MYSQL *)MySQLDatabase;

#pragma mark -
#pragma mark Initialization related messages

+ (id)databaseWithOptions:(NSDictionary *)options 
                    error:(NSError **)error;

+ (id)databaseWithName:(NSString *)dbName
                  User:(NSString *)dbUser
              Password:(NSString *)dbPassword
                  Host:(NSString *)dbHost;

- (id)initWithName:(NSString *)dbName
              Host:(NSString *)dbHost
              User:(NSString *)dbUser 
              Pass:(NSString *)dbPass;

#pragma mark -
#pragma mark CSMySQLDatabase related messages

- (BOOL)executeSQL:(NSString *)sql
        withValues:(NSArray *)values
          callback:(CSMySQLCallback)callbackFunction 
           context:(void *)context
             error:(NSError **)error;

@end

#pragma mark -
#pragma mark MySQL callbacks

int mysqlRowAsArrayCallback(void *callbackContext,
                            int columnCount,
                            char **columnValues,
                            char **columnNames);

int mysqlRowAsDictionaryCallback(void *callbackContext,
                                 int columnCount,
                                 char **columnValues,
                                 char **columnNames);

int mysqlRowsAsDictionariesCallback(void *callbackContext,
                                    int columnCount,
                                    char **columnValues,
                                    char **columnNames);

int mysqlRowsAsArraysCallback(void *callbackContext,
                              int columnCount,
                              char **columnValues,
                              char **columnNames);
