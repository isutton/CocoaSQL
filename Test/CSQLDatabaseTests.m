//
//  CSQLDatabaseTests.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/31/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSQLDatabaseTests.h"

@implementation CSQLDatabaseTests

#define TEST_DB @"test.db"

- (void)setUp
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:[TEST_DB stringByExpandingTildeInPath]]) {
        [fm removeItemAtPath:[TEST_DB stringByExpandingTildeInPath] error:nil];
    }
}

- (void)tearDown
{
    
}

- (void)testDatabaseWithDriver
{
    CSQLDatabase *database_;
    NSError *error;
    
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    [options setObject:TEST_DB forKey:@"path"];
    
    database_ = [[CSQLDatabase databaseWithDriver:@"SQLite" options:options error:&error] retain];
    
    STAssertNil(error, @"We shouldn't have an error here: %@", error);
    STAssertNotNil(database_, @"Database should not be nil.");    
}

- (void)testDatabaseWithDSN
{
    CSQLDatabase *database_;
    NSError *error;
    
    NSString *DSN = [NSString stringWithFormat:@"SQLite:path=%@", TEST_DB];
    database_ = [CSQLDatabase databaseWithDSN:DSN error:&error];

    STAssertNil(error, @"We shouldn't have an error here: %@", error);
    STAssertNotNil(database_, @"Database should not be nil.");    
}

- (id) createDatabase:(NSError **)error
{
    NSString *DSN = [NSString stringWithFormat:@"SQLite:path=%@", TEST_DB];
    CSQLDatabase *database = [CSQLDatabase databaseWithDSN:DSN error:&(*error)];
    return database;
}

- (BOOL)createTable:(id)database 
{
    NSError *error = nil;
    int affectedRows;
    
    affectedRows = [database executeSQL:@"CREATE TABLE t (i INT, v VARCHAR)" error:&error];
    
    STAssertNil(error, @"Error.");
    STAssertEquals(affectedRows, 0, @"CREATE TABLE.");
    
    if (error) {
        return NO;
    }

    return YES;
}

- (void)testExecuteSQL
{
    NSError *error = nil;
    int affectedRows;
    
    CSQLDatabase *database = [self createDatabase:&error];
    
    [self createTable:database];
    
    error = nil;
    affectedRows = [database executeSQL:@"INSERT INTO t (i, v) VALUES (1, 'test')" error:&error];
    
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals(affectedRows, 1, @"INSERT.");

    error = nil;
    affectedRows = [database executeSQL:@"INSERT INTO t (i, v) VALUES (2, 'test')" error:&error];
    
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals(affectedRows, 1, @"INSERT.");
    
    error = nil;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:1];
    [values bindIntValue:1];
    affectedRows = [database executeSQL:@"DELETE FROM t WHERE i = ?" withValues:values error:&error];

    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals(affectedRows, 1, @"DELETE with bind values.");
    
    error = nil;
    affectedRows = [database executeSQL:@"DELETE FROM t" error:&error];
    
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals(affectedRows, 1, @"DELETE.");
    
    error = nil;
    affectedRows = [database executeSQL:@"DROP TABLE t" error:&error];
    
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals(affectedRows, 1, @"DROP TABLE.");
}

- (void)testInsertionWithPreparedStatement
{
    NSError *error = nil;
    id database = [self createDatabase:&error];
    [self createTable:database];
    
    id statement = [database prepareStatement:@"INSERT INTO t (i, v) VALUES (?, ?)" error:&error];
 
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:2];
    for (int i = 1; i <= 100; i++) {
        [values bindIntValue:i];
        [values bindStringValue:[NSString stringWithFormat:@"v%i", i]];
        [statement executeWithValues:values error:&error];
        
        if (error) {
            break;
        }
        
        [values removeAllObjects];
    }
    
    STAssertNil(error, @"Insertion failed.");
}

@end
