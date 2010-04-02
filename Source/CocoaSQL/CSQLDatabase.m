//
//  CSQLDatabase.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/31/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSQLDatabase.h"

@implementation CSQLDatabase

+ (id <CSQLDatabase>)databaseWithDriver:(NSString *)aDriver 
                                options:(NSDictionary *)options
                                  error:(NSError **)error
{
    //
    // Build the class name. It will be like:
    //
    // * CSSQLiteDatabase
    // * CSMySQLDatabase
    // * CSPostgreSQLDatabase
    // * CSOracleDatabase
    //
    NSString *aClassName = [NSString stringWithFormat:@"CS%@Database", aDriver];
    Class <CSQLDatabase> class = NSClassFromString(aClassName);
    id <CSQLDatabase> database = [class databaseWithOptions:options error:error];
    return database;
}

+ (id <CSQLDatabase>)databaseWithDSN:(NSString *)aDSN 
                               error:(NSError **)error
{
    //
    // From the DSN we'll get:
    //
    // * Driver to be used
    // * Additional information to be passed to the Driver
    //
    // The additional information will be stored in a NSDictionary.
    //
    // After that, we'll return whatever comes out of  
    // databaseWithDriver:options:error: 
    //
    
    return nil;
}

@end
