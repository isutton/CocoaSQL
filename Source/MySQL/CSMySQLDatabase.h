//
//  CSMySQL.h
//  CocoaSQL
//
//  Created by xant on 4/2/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CocoaSQL.h"

#include <mysql.h>

@interface CSMySQLDatabase : CSQLDatabase {
}

@property (readwrite,assign) voidPtr databaseHandle;

#pragma mark -
#pragma mark Initialization related messages

+ (id)databaseWithOptions:(NSDictionary *)options 
                    error:(NSError **)error;

+ (id)databaseWithName:(NSString *)databaseName
                  host:(NSString *)host
                  user:(NSString *)user
              password:(NSString *)password
                 error:(NSError **)error;

- (id)initWithName:(NSString *)databaseName
              host:(NSString *)host
              user:(NSString *)user
          password:(NSString *)password
             error:(NSError **)error;

@end
