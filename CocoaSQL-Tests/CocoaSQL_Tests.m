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
//  CSQLDatabaseTests.m by Igor Sutton on 3/31/10.
//

#import "CocoaSQL_Tests.h"

@implementation CocoaSQL_Tests

#define TEST_DB @"test.db"

#define TEST_DRIVER @"MySQL"
#define TEST_DSN @"MySQL:db=test;host=localhost;user=root"

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

- (void)testDatabaseWithDSN
{
    CSQLDatabase *database_;
    NSError *error = nil;
    
    NSString *DSN = [NSString stringWithFormat:TEST_DSN, TEST_DB];
    database_ = [CSQLDatabase databaseWithDSN:DSN error:&error];
    STAssertNil(error, @"We got an error");
    STAssertNotNil(database_, @"Database should not be nil.");    
}

- (BOOL)createTable:(id)database 
{
    NSError *error = nil;
    BOOL res;
    
    res = [database executeSQL:@"CREATE TABLE t (i INT, v VARCHAR(10))" error:&error];
    
    STAssertNil(error, @"Error.");
    STAssertEquals(res, YES, @"CREATE TABLE.");
    
    if (error) {
        return NO;
    }
    
    return YES;
}

- (void)_testExecuteSQL:(CSQLDatabase *)database
{
    [self createTable:database];

    int affectedRows;
    NSError *error = nil;

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
    STAssertEqualObjects([[resultArray objectAtIndex:0] stringValue], @"2" , @"fetchRowAsArrayWithSQL : resultElement1");
    STAssertEqualObjects([[resultArray objectAtIndex:1] stringValue], @"test2" , @"fetchRowAsArrayWithSQL : resultElement2");
    
    // test fetchRowAsDictionaryWithSQL
    NSDictionary *resultDictionary = [database fetchRowAsDictionaryWithSQL:@"SELECT * FROM t WHERE i=1" error:&error];
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals((int)[resultDictionary count], 2, @"fetchRowAsArrayWithSQL : resultCount");
    STAssertEqualObjects([[resultDictionary objectForKey:@"i"] stringValue], @"1" , @"fetchRowAsArrayWithSQL : resultElement1");
    STAssertEqualObjects([[resultDictionary objectForKey:@"v"] stringValue], @"test" , @"fetchRowAsArrayWithSQL : resultElement2");
    
    error = nil;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:1];
    [values bindIntValue:1];
    [database executeSQL:@"DELETE FROM t WHERE i = ?" withValues:values error:&error];
    
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals([[database affectedRows] intValue], 1, @"DELETE with bind values.");
    error = nil;
    affectedRows = [database executeSQL:@"DELETE FROM t" error:&error];
    
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    STAssertEquals(affectedRows, 1, @"DELETE.");
    
    error = nil;
    affectedRows = [database executeSQL:@"DROP TABLE t" error:&error];
    
    STAssertNil(error, [NSString stringWithFormat:@"We shouldn't have an error here: %@", [[error userInfo] objectForKey:@"errorMessage"]]);
    //STAssertEquals(affectedRows, 1, @"DROP TABLE."); // XXX - This doesn't seem to work with mysql connector, affectedRows is 0 when dropping a table :/
}

- (void)_testPreparedStatement:(CSQLDatabase *)database
{
    NSError *error = nil;

    [self createTable:database];
    
    CSQLPreparedStatement *statement = [database prepareStatement:@"INSERT INTO t (i, v) VALUES (?, ?)" error:&error];
    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:2];
    for (int i = 1; i <= 100 && !error; i++) {
        [values bindIntValue:i];
        [values bindStringValue:[NSString stringWithFormat:@"v%i", i]];
        [statement executeWithValues:values error:&error];
        [values removeAllObjects];
    }
    
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:1];
    CSQLPreparedStatement *selectStatement = [database prepareStatement:@"SELECT * FROM t WHERE v like ?" error:&error];
    [params bindStringValue:@"v%"];
    [selectStatement executeWithValues:params error:&error];
    NSDictionary *resultDictionary;
    int cnt = 1;
    while ((resultDictionary = [selectStatement fetchRowAsDictionary:nil])) {
        NSNumber *i = [NSNumber numberWithInt:cnt];
        NSString *v = [NSString stringWithFormat:@"v%d", cnt];
        STAssertEquals((int)[resultDictionary count], 2, @"fetchRowAsArrayWithSQL : resultCount");
        STAssertEqualObjects([[resultDictionary objectForKey:@"i"] numberValue], i , @"fetchRowAsArrayWithSQL : resultElement1");
        STAssertEqualObjects([[resultDictionary objectForKey:@"v"] stringValue], v, @"fetchRowAsArrayWithSQL : resultElement2");
        cnt++;
    }
    [database executeSQL:@"DROP TABLE t" error:&error];
    STAssertNil(error, @"preparedStatement failed.");
}

- (void)testSQLite
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"SQLite", @"driver",
                             @"test.db", @"path",
                             nil];

    NSError *error = nil;
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"SQLite" options:options error:&error];
    STAssertNotNil(database, @"Driver %@, %@", [options objectForKey:@"driver"], [error description]);
    
    [self _testExecuteSQL:database];
    [self _testPreparedStatement:database];
}

- (void)testMySQL
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"MySQL", @"driver",
                             @"test", @"db",
                             @"localhost", @"host",
                             @"root", @"user",
                             nil];
    NSError *error = nil;
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"MySQL" options:options error:&error];
    STAssertNotNil(database, @"Driver %@, %@", [options objectForKey:@"driver"], [error description]);
    
    [self _testExecuteSQL:database];
    [self _testPreparedStatement:database];
}

- (void)testPostgreSQL
{    
    NSError *error = nil;
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"PostgreSQL" options:[NSDictionary dictionary] error:&error];
    STAssertNotNil(database, @"Driver PostgreSQL, %@", [error description]);
        
    [self _testExecuteSQL:database];
    [self _testPreparedStatement:database];
}

@end
