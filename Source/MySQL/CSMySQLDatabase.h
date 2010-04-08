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

@interface CSMySQLDatabase : CSQLDatabase {
}

@property (readwrite,assign) voidPtr databaseHandle;

#pragma mark -
#pragma mark Initialization related messages

+ (id)databaseWithName:(NSString *)dbName
                  Host:(NSString *)dbHost
                  User:(NSString *)dbUser
              Password:(NSString *)dbPassword
                 error:(NSError **)error;

- (id)initWithName:(NSString *)dbName
              Host:(NSString *)dbHost
              User:(NSString *)dbUser 
          Password:(NSString *)dbPass
             error:(NSError **)error;

@end
