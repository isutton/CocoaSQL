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
    
}

- (void)testDatabaseWithDriver
{
    CSQLDatabase *database_;
    NSError *error = nil;
    
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    [options setObject:TEST_DB forKey:@"path"];
    
    database_ = [[CSQLDatabase databaseWithDriver:TEST_DRIVER options:options error:&error] retain];
    
    STAssertNil(error, @"We got an error.");
    STAssertNotNil(database_, @"Database should not be nil.");    
}

- (void)testDatabaseWithDSN
{
    CSQLDatabase *database_;
    NSError *error = nil;
    
    NSString *DSN = [NSString stringWithFormat:TEST_DSN, TEST_DB];
    database_ = [CSQLDatabase databaseWithDSN:DSN error:&error];
    STAssertNil(error, @"We got an error");
    STAssertNotNil(database_, @"Database should not be nil.");    
}

- (id) createDatabase:(NSError **)error
{
    NSString *DSN = [NSString stringWithFormat:TEST_DSN, TEST_DB];
    CSQLDatabase *database = [CSQLDatabase databaseWithDSN:DSN error:&(*error)];
    return database;
}

- (BOOL)createTable:(id)database 
{
    NSError *error = nil;
    int affectedRows;
    
    affectedRows = [database executeSQL:@"CREATE TABLE t (i INT, v VARCHAR(10))" error:&error];
    
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
    affectedRows = [database executeSQL:@"INSERT INTO t (i, v) VALUES (2, 'test2')" error:&error];
    
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals(affectedRows, 1, @"INSERT.");
    
    // test fetchRowAsArrayWithSQL
    NSArray *resultArray = [database fetchRowAsArrayWithSQL:@"SELECT * FROM t WHERE i=2" error:&error];
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals((int)[resultArray count], 2, @"fetchRowAsArrayWithSQL : resultArrayCount");
    STAssertEqualObjects([resultArray objectAtIndex:0], @"2" , @"fetchRowAsArrayWithSQL : resultElement1");
    STAssertEqualObjects([resultArray objectAtIndex:1], @"test2" , @"fetchRowAsArrayWithSQL : resultElement2");
    
    // test fetchRowAsDictionaryWithSQL
    NSDictionary *resultDictionary = [database fetchRowAsDictionaryWithSQL:@"SELECT * FROM t WHERE i=1" error:&error];
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals((int)[resultDictionary count], 2, @"fetchRowAsArrayWithSQL : resultCount");
    STAssertEqualObjects([resultDictionary objectForKey:@"i"], @"1" , @"fetchRowAsArrayWithSQL : resultElement1");
    STAssertEqualObjects([resultDictionary objectForKey:@"v"], @"test" , @"fetchRowAsArrayWithSQL : resultElement2");
    
    error = nil;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:1];
    [values addObject:[NSNumber numberWithInt:1]];
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
    //STAssertEquals(affectedRows, 1, @"DROP TABLE."); // XXX - This doesn't seem to work with mysql connector, affectedRows is 0 when dropping a table :/
}

- (void)testPreparedStatement
{
    NSError *error = nil;
    CSQLDatabase *database = [self createDatabase:&error];
    [self createTable:database];
    
    CSQLPreparedStatement *statement = [database prepareStatement:@"INSERT INTO t (i, v) VALUES (?, ?)" error:&error];
    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:2];
    for (int i = 1; i <= 100 && !error; i++) {
        [values addObject:[NSNumber numberWithInt:i]];
        [values addObject:[NSString stringWithFormat:@"v%i", i]];
        [statement executeWithValues:values error:&error];
        [values removeAllObjects];
    }
    
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:1];
    CSQLPreparedStatement *selectStatement = [database prepareStatement:@"SELECT * FROM t WHERE v like ?" error:&error];
    [params addObject:@"v%"];
    [selectStatement executeWithValues:params error:&error];
    NSDictionary *resultDictionary;
    int cnt = 1;
    while (resultDictionary = [selectStatement fetchRowAsDictionary:nil]) {
        NSNumber *i = [NSNumber numberWithInt:cnt];
        NSString *v = [NSString stringWithFormat:@"v%d", cnt];
        STAssertEquals((int)[resultDictionary count], 2, @"fetchRowAsArrayWithSQL : resultCount");
        STAssertEqualObjects([resultDictionary objectForKey:@"i"], i , @"fetchRowAsArrayWithSQL : resultElement1");
        STAssertEqualObjects([resultDictionary objectForKey:@"v"], v, @"fetchRowAsArrayWithSQL : resultElement2");
        cnt++;
    }
    [database executeSQL:@"DROP TABLE t" error:&error];
    STAssertNil(error, @"preparedStatement failed.");
}

@end
