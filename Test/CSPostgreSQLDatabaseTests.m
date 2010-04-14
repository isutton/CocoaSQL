//
//  CSPostgreSQLDatabaseTests.m
//  CocoaSQL
//
//  Created by Igor Sutton on 4/13/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CocoaSQL.h"
#import "CSPostgreSQLDatabase.h"
#import "CSPostgreSQLPreparedStatement.h"
#import "CSPostgreSQLDatabaseTests.h"


@implementation CSPostgreSQLDatabaseTests

- (void)testDatabaseWithDSN 
{
    NSError *error = nil;
    CSQLDatabase *database = [CSQLDatabase databaseWithDSN:@"PostgreSQL:" error:&error];
    
    STAssertNotNil(database, @"Database was not created.");
    STAssertTrue([database isKindOfClass:[CSPostgreSQLDatabase class]], @"Got object of wrong kind.");
    STAssertNotNil(database.databaseHandle, @"Database connection was not opened.");    
}

- (void)testDatabaseWithDriver
{
    NSError *error = nil;
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"PostgreSQL" options:[NSDictionary dictionary] error:&error];
    
    STAssertNotNil(database, @"Database was not created.");
    STAssertTrue([database isKindOfClass:[CSPostgreSQLDatabase class]], @"Got object of wrong kind.");
    STAssertNotNil(database.databaseHandle, @"Database connection was not opened.");    
}

- (void)testPreparedStatement
{
    NSError *error = nil;
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"PostgreSQL" options:[NSDictionary dictionary] error:&error];
    
    error = nil;
    CSQLPreparedStatement *statement = [database prepareStatement:@"CREATE TABLE t (i INT, v VARCHAR(255))" error:&error];

    STAssertNotNil(statement, @"Statement was not created.");
    STAssertTrue([statement isKindOfClass:[CSPostgreSQLPreparedStatement class]], @"Got object of wrong kind.");

    error = nil;
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, @"An error occurred: %@", error);

#if 1
    error = nil;
    statement = [database prepareStatement:@"INSERT INTO t (i, v) VALUES ($1, $2)" error:&error];

    STAssertNotNil(statement, @"Statement was not created.");
    STAssertNil(error, [error description]);

    error = nil;
    
    NSArray *values = [NSArray arrayWithObjects:
                       [NSNumber numberWithInt:1],
                       @"v1",
                       nil];
    
    STAssertTrue([statement executeWithValues:values error:&error], @"Statement was not executed.");
    STAssertNil(error, [error description]);
    STAssertFalse(statement.canFetch, @"Statement should return rows.");
#endif
    
    //
    // Clean up.
    //

#if 1
    error = nil;

    statement = [database prepareStatement:@"DROP TABLE t" error:&error];
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, @"An error occurred. %@", error);
#endif
    
}

@end
