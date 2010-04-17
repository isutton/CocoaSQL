//
//
//  This file is part of CocoaSQL
//
//  CocoaSQL is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  CocoaSQL is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with CocoaSQL.  If not, see <http://www.gnu.org/licenses/>.
//
//  CSSQLiteDatabaseTests.m by Igor Sutton on 3/31/10.
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
    NSArray *expectedArray = [NSArray arrayWithObjects:
                              [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:2]], 
                              [CSQLResultValue valueWithString:@"test2"],
                               nil
                             ];
    NSArray *resultArray = [database fetchRowAsArrayWithSQL:@"SELECT i, v FROM t ORDER BY i DESC" error:&error];
    
    if (error) STFail(@"%@", error);
    STAssertEquals((int)[resultArray count], 2, @"fetchRowAsArrayWithSQL:error: number of elements in array match.");
    STAssertEqualObjects(resultArray, expectedArray, @"fetchRowAsArrayWithSQL:error: rows match.");
    NSLog(@"%@ \n--\n%@\n", [[resultArray objectAtIndex:0] numberValue], [[expectedArray objectAtIndex:0] numberValue]);
    //
    // fetchRowAsDictionaryWithSQL:error: returns the first row from the result set.
    //
    error = nil;
    NSDictionary *expectedDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:1]], @"i", 
                                        [CSQLResultValue valueWithString:@"test1"], @"v", 
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
                     [NSArray arrayWithObjects:
                      [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:1]],
                      [CSQLResultValue valueWithString:@"test1"], 
                       nil
                     ],
                     [NSArray arrayWithObjects:
                      [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:2]],
                      [CSQLResultValue valueWithString:@"test2"],
                       nil
                     ],
                     nil
                    ];
    resultArray = [database fetchRowsAsArraysWithSQL:@"SELECT i, v FROM t ORDER BY i" error:&error];
    
    if (error) STFail([error description]);
    STAssertEquals([resultArray count], [expectedArray count], @"fetchRowsAsArraysWithSQL:error: number of rows returned match.");
    STAssertEqualObjects(resultArray, expectedArray, @"fetchRowsAsArraysWithSQL:error: rows match.");
    
    //
    // fetchRowsAsDictionariesWithSQL:error: returns all the rows as dictionaries.
    //
    error = nil;
    expectedArray = [NSArray arrayWithObjects:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:2]], @"i",
                      [CSQLResultValue valueWithString:@"test2"], @"v",
                      nil
                     ],
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:1]], @"i",
                      [CSQLResultValue valueWithString:@"test1"], @"v",
                      nil
                     ],
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
                              [NSDictionary dictionaryWithObjectsAndKeys:
                               [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:1]], @"i",
                               [CSQLResultValue valueWithString:@"v1"], @"v",
                                nil
                              ],
                              [NSDictionary dictionaryWithObjectsAndKeys:
                               [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:2]], @"i",
                               [CSQLResultValue valueWithString:@"v2"], @"v",
                                nil
                              ],
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
        
        success = [statement bindValue:[NSNumber numberWithInt:i] toColumn:1];
        STAssertTrue(success, @"bindValue:forColumn:");
        
        success = [statement bindValue:[NSString stringWithFormat:@"v%i", i] toColumn:2];
        STAssertTrue(success, @"bindValue:forColumn:");
        
        [statement execute:&error];
        if (error)
            STFail(@"Couldn't insert row > %@", error);
    }
    
    error = nil;
    CSQLPreparedStatement *selectStatement = [database prepareStatement:@"SELECT i, v FROM t WHERE v like ? ORDER BY i" error:&error];
    
    if (error)
        STFail(@"Couldn't create prepared statement: %@.", error);

    [selectStatement bindValue:@"v%" toColumn:1];
    [selectStatement execute:&error];
    
    NSDictionary *resultDictionary;
    int count = 1;
    while (resultDictionary = [selectStatement fetchRowAsDictionary:nil]) {
        NSNumber *i = [NSNumber numberWithInt:count];
        NSString *v = [NSString stringWithFormat:@"v%d", count];
        STAssertEquals((int)[resultDictionary count], 2, @"fetchRowAsArrayWithSQL : resultCount");
        STAssertEqualObjects([[resultDictionary objectForKey:@"i"] numberValue], i , @"fetchRowAsArrayWithSQL : resultElement1");
        STAssertEqualObjects([[resultDictionary objectForKey:@"v"] stringValue], v, @"fetchRowAsArrayWithSQL : resultElement2");
        count++;
    }
    
    [database executeSQL:@"DROP TABLE t" error:nil];
}

- (void)testDatatypes
{
    NSError *error = nil;
    CSQLDatabase *database = (CSQLDatabase *)[self createDatabase:nil];
    
    [database executeSQL:@"CREATE TABLE CocoaSQL_test_datatypes (i INTEGER, t TEXT, b BLOB, r REAL, nb BIGINT, nnbu BIGINT, nbu BIGINT, nu INTEGER)" error:&error];
    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:5];
    [values addObject:[NSNumber numberWithInt:65535]];
    [values addObject:@"some text here and there"];
    [values addObject:[NSData dataWithData:[@"this is a blob" dataUsingEncoding:NSUTF8StringEncoding]]];
    [values addObject:[NSDecimalNumber numberWithFloat:0.123456789]];
    [values addObject:[NSNumber numberWithLongLong:92233720368547758L]];
    [values addObject:[NSNumber numberWithLongLong:-92233720368547758L]];
    [values addObject:[NSNumber numberWithUnsignedLongLong:18446744073709551615UL]];
    [values addObject:[NSNull null]];
    
    [database executeSQL:@"INSERT INTO CocoaSQL_test_datatypes VALUES (?, ?, ?, ?, ?, ?, ?, ?)" withValues:values error:&error];
    
    if (error) STFail(@"%@", error);
    
    NSArray *row = [database fetchRowAsArrayWithSQL:@"SELECT i, t, b, r, nb, nnbu, nbu, nu FROM CocoaSQL_test_datatypes LIMIT 1" error:&error];

    if (error) STFail(@"%@", error);

    STAssertEquals([[[row objectAtIndex:0] numberValue] intValue],
                   [[values objectAtIndex:0] intValue],
                   @"int");
    STAssertEqualObjects([[row objectAtIndex:1] stringValue],
                         [values objectAtIndex:1],
                         @"NSString");
    STAssertEqualObjects([[row objectAtIndex:2] dataValue],
                         [values objectAtIndex:2],
                         @"NSData");
    STAssertEquals([[[row objectAtIndex:3] decimalNumberValue] floatValue],
                   [[values objectAtIndex:3] floatValue],
                   @"float");
    STAssertEquals([[[row objectAtIndex:4] numberValue] longLongValue],
                   [[values objectAtIndex:4] longLongValue],
                   @"signed long long - positive");
    STAssertEquals([[[row objectAtIndex:5] numberValue] longLongValue],
                   [[values objectAtIndex:5] longLongValue],
                   @"signed long long - negative");
    STAssertEquals([[[row objectAtIndex:6] numberValue] unsignedLongLongValue],
                   [[values objectAtIndex:6] unsignedLongLongValue],
                   @"unsigned long long");
    STAssertTrue([[row objectAtIndex:7] isNull], @"NSNull");
    
    // Clean up.
    [database executeSQL:@"DROP TABLE CocoaSQL_test_datatypes" error:nil];
}

@end
