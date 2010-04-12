//
//  CSSQLiteDatabaseTests.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/31/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSSQLiteDatabaseTests.h"
#import "CocoaSQL.h"

@implementation CSSQLiteDatabaseTests

#define TEST_DRIVER @"SQLite"
#define TEST_DB @"test.db"
#define TEST_DSN @"SQLite:path=test.db"

- (void)setUp
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:[TEST_DB stringByExpandingTildeInPath]]) {
        [fm removeItemAtPath:[TEST_DB stringByExpandingTildeInPath] error:nil];
    }
}

- (void)tearDown
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:[TEST_DB stringByExpandingTildeInPath]]) {
        [fm removeItemAtPath:[TEST_DB stringByExpandingTildeInPath] error:nil];
    }    
}

- (void)testDatabaseWithDriver
{
    NSError *error = nil;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:TEST_DB, @"path", nil];
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:TEST_DRIVER options:options error:&error];
    
    STAssertNil(error, @"We got an error.");
    STAssertNotNil(database, @"Database should not be nil.");
    
}

- (void)testDatabaseWithDSN
{
    NSError *error = nil;
    CSQLDatabase *database = [CSQLDatabase databaseWithDSN:TEST_DSN error:&error];
    
    STAssertNil(error, @"We got an error");
    STAssertNotNil(database, @"Database should not be nil.");    
}

- (id) createDatabase:(NSError **)error
{
    CSQLDatabase *database = [CSQLDatabase databaseWithDSN:TEST_DSN error:error];
    return database;
}

- (BOOL)createTable:(id)database 
{
    NSError *error = nil;
    int affectedRows = [database executeSQL:@"CREATE TABLE t (i INT, v VARCHAR(10))" error:&error];
    
    STAssertNil(error, @"Error.");
    // FIXME: In SQLite, CREATE and DROP commands return the number of rows affected whilst MySQL 
    //        returns 0.
    STAssertEquals(affectedRows, 1, @"CREATE TABLE.");
    
    return error ? NO : YES;
}

- (void)testFunctional
{
    NSError *error = nil;
    int affectedRows;
    
    CSQLDatabase *database = [self createDatabase:&error];
    
    [self createTable:database];
    
    //
    // executeSQL:withValues:error:
    //
    error = nil;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:2];
    for (int i = 1; i <= 2; i++) {
        [values addObject:[NSNumber numberWithInt:i]];
        [values addObject:[NSString stringWithFormat:@"test%i", i]];
        [database executeSQL:@"INSERT INTO t (i, v) VALUES (?, ?)" withValues:values error:&error];
        [values removeAllObjects];
        if (error) STFail([error description]);
    }
    values = nil;
    
    //
    // fetchRowAsArrayWithSQL:error: returns the first row from the result set.
    //
    error = nil;
    NSArray *expectedArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:2], @"test2", nil];
    NSArray *resultArray = [database fetchRowAsArrayWithSQL:@"SELECT i, v FROM t ORDER BY i DESC" error:&error];
    
    if (error) STFail(@"%@", error);
    STAssertEquals((int)[resultArray count], 2, @"fetchRowAsArrayWithSQL:error: number of elements in array match.");
    STAssertEqualObjects(resultArray, expectedArray, @"fetchRowAsArrayWithSQL:error: rows match.");

    //
    // fetchRowAsDictionaryWithSQL:error: returns the first row from the result set.
    //
    error = nil;
    NSDictionary *expectedDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:1], @"i", 
                                        @"test1", @"v", 
                                        nil];
    NSDictionary *resultDictionary = [database fetchRowAsDictionaryWithSQL:@"SELECT i, v FROM t ORDER BY i" error:&error];

    if (error) STFail(@"%@", error);
    STAssertEquals((int)[resultDictionary count], 2, @"fetchRowAsDictionaryWithSQL:error: number of keys in dictionary match.");
    STAssertEqualObjects(resultDictionary, expectedDictionary, @"fetchRowAsDictionaryWithSQL:error: rows match.");
    
    //
    // fetchRowsAsArraysWithSQL:error: returns all the rows as arrays.
    //
    error = nil;
    expectedArray = [NSArray arrayWithObjects:
                     [NSArray arrayWithObjects:[NSNumber numberWithInt:1], @"test1", nil],
                     [NSArray arrayWithObjects:[NSNumber numberWithInt:2], @"test2", nil],
                     nil];
    resultArray = [database fetchRowsAsArraysWithSQL:@"SELECT i, v FROM t ORDER BY i" error:&error];
    
    if (error) STFail([error description]);
    STAssertEquals([resultArray count], [expectedArray count], @"fetchRowsAsArraysWithSQL:error: number of rows returned match.");
    STAssertEqualObjects(resultArray, expectedArray, @"fetchRowsAsArraysWithSQL:error: rows match.");
    
    //
    // fetchRowsAsDictionariesWithSQL:error: returns all the rows as dictionaries.
    //
    error = nil;
    expectedArray = [NSArray arrayWithObjects:
                     [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"i", @"test2", @"v", nil],
                     [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"i", @"test1", @"v", nil],
                     nil];
    resultArray = [database fetchRowsAsDictionariesWithSQL:@"SELECT i, v FROM t ORDER BY i DESC" error:&error];
    
    if (error) STFail([error description]);
    STAssertEquals([resultArray count], [expectedArray count], @"fetchRowsAsDictionariesWithSQL:error: number of rows returned match.");
    STAssertEqualObjects(resultArray, expectedArray, @"fetchRowsAsDictionariesWithSQL:error: rows match.");
    
    //
    // executeSQL:withValues:error:
    //
    error = nil;
    values = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:1], nil];
    affectedRows = [database executeSQL:@"DELETE FROM t WHERE i = ?" withValues:values error:&error];

    if (error) STFail(@"%@", error);
    STAssertEquals(affectedRows, 1, @"DELETE with bind values.");
}

- (void)testPreparedStatementWithValuesAsArray
{
    NSError *error = nil;
    CSQLDatabase *database = [self createDatabase:&error];
    [self createTable:database];

    CSQLPreparedStatement *statement = [database prepareStatement:@"INSERT INTO t (i, v) VALUES (?, ?)" error:&error];

    if (error)
        STFail(@"Couldn't create prepared statement: %@.", error);

    NSMutableArray *values = [NSMutableArray arrayWithCapacity:2];
    for (int i = 1; i <= 100 && !error; i++) {
        [values addObject:[NSNumber numberWithInt:i]];
        [values addObject:[NSString stringWithFormat:@"v%i", i]];
        [statement executeWithValues:values error:&error];
        [values removeAllObjects];
    }
        
    CSQLPreparedStatement *selectStatement = [database prepareStatement:@"SELECT i, v FROM t WHERE v LIKE ? AND i < ? ORDER BY i" error:&error];
    
    if (error)
        STFail(@"Couldn't create prepared statement: %@.", error);

    values = [NSMutableArray arrayWithCapacity:1];
    [values addObject:@"v%"];
    [values addObject:[NSNumber numberWithInt:3]];
    [selectStatement executeWithValues:values error:&error];
    
    NSArray *expectedArray = [NSArray arrayWithObjects:
                              [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"i", @"v1", @"v", nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"i", @"v2", @"v", nil],
                              nil];
    NSDictionary *resultDictionary;
    int count = 1;
    while (resultDictionary = [selectStatement fetchRowAsDictionary:nil]) {
        NSDictionary *expectedDictionary = [expectedArray objectAtIndex:count-1];
        STAssertEquals([resultDictionary count], [expectedDictionary count], @"fetchRowAsArrayWithSQL: number of keys match.");
        STAssertEqualObjects(resultDictionary, expectedDictionary, @"fetchRowAsDictionary: rows match.");
        count++;
    }
    
    [database executeSQL:@"DROP TABLE t" error:nil];
}


- (void)testPreparedStatementBindingToStatement
{
    NSError *error = nil;
    CSQLDatabase *database = [self createDatabase:&error];
    [self createTable:database];
    
    error = nil;
    CSQLPreparedStatement *statement = [database prepareStatement:@"INSERT INTO t (i, v) VALUES (?, ?)" error:&error];
    
    if (error)
        STFail(@"Couldn't create prepared statement: %@.", error);
    
    BOOL success = NO;
    for (int i = 1; i <= 100 && !error; i++) {
        
        success = [statement bindValue:[NSNumber numberWithInt:i] forColumn:1];
        STAssertTrue(success, @"bindValue:forColumn:");
        
        success = [statement bindValue:[NSString stringWithFormat:@"v%i", i] forColumn:2];
        STAssertTrue(success, @"bindValue:forColumn:");
        
        [statement execute:&error];
        if (error)
            STFail(@"Couldn't insert row > %@", error);
    }
    
    error = nil;
    CSQLPreparedStatement *selectStatement = [database prepareStatement:@"SELECT i, v FROM t WHERE v like ? ORDER BY i" error:&error];
    
    if (error)
        STFail(@"Couldn't create prepared statement: %@.", error);

    [selectStatement bindValue:@"v%" forColumn:1];
    [selectStatement execute:&error];
    
    NSDictionary *resultDictionary;
    int count = 1;
    while (resultDictionary = [selectStatement fetchRowAsDictionary:nil]) {
        NSNumber *i = [NSNumber numberWithInt:count];
        NSString *v = [NSString stringWithFormat:@"v%d", count];
        STAssertEquals((int)[resultDictionary count], 2, @"fetchRowAsArrayWithSQL : resultCount");
        STAssertEqualObjects([resultDictionary objectForKey:@"i"], i , @"fetchRowAsArrayWithSQL : resultElement1");
        STAssertEqualObjects([resultDictionary objectForKey:@"v"], v, @"fetchRowAsArrayWithSQL : resultElement2");
        count++;
    }
    
    [database executeSQL:@"DROP TABLE t" error:nil];
}

- (void)testDatatypes
{
    NSError *error = nil;
    CSQLDatabase *database = (CSQLDatabase *)[self createDatabase:nil];
    
    [database executeSQL:@"CREATE TABLE CocoaSQL_test_datatypes (i INTEGER, t TEXT, b BLOB, r REAL, n NUMERIC, nu INTEGER)" error:nil];
    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:5];
    [values addObject:[NSNumber numberWithInt:65535]];
    [values addObject:@"some text here and there"];
    [values addObject:[NSData dataWithData:[@"this is a blob" dataUsingEncoding:NSUTF8StringEncoding]]];
    [values addObject:[NSNumber numberWithFloat:2.0]];
    [values addObject:[NSDecimalNumber numberWithInt:128]];
    [values addObject:[NSNull null]];
    
    [database executeSQL:@"INSERT INTO CocoaSQL_test_datatypes VALUES (?, ?, ?, ?, ?, ?)" withValues:values error:&error];
    
    if (error) STFail(@"%@", error);
    
    NSArray *row = [database fetchRowAsArrayWithSQL:@"SELECT i, t, b, r, n, nu FROM CocoaSQL_test_datatypes LIMIT 1" error:&error];

    if (error) STFail(@"%@", error);

    STAssertTrue([values isEqualToArray:row], @"Got the same we inserted.");
    
    // Clean up.
    [database executeSQL:@"DROP TABLE CocoaSQL_test_datatypes" error:nil];
}

@end
