//
//  CMySQLDatabaseTests.m
//  CocoaSQL
//
//  Created by xant on 4/9/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CMySQLDatabaseTests.h"


#define TEST_DRIVER @"MySQL"
#define TEST_DSN @"MySQL:db=test;host=localhost;user=root"

@implementation CMySQLDatabaseTests

- (id) createDatabase:(NSError **)error
{
    NSString *DSN = TEST_DSN;
    CSQLDatabase *database = [CSQLDatabase databaseWithDSN:DSN error:&(*error)];
    return database;
}

- (BOOL)createTable:(id)database 
{
    NSError *error = nil;
    int affectedRows;
    
    affectedRows = [database executeSQL:@"CREATE TABLE mysql_test (i INT, v VARCHAR(10), d DATETIME)" error:&error];
    
    STAssertNil(error, @"Error.");
    STAssertEquals(affectedRows, 0, @"CREATE TABLE.");
    
    if (error) {
        return NO;
    }
    
    return YES;
}

- (void)testMysqlDatatypes
{
    NSError *error = nil;
    id database = [self createDatabase:&error];
    [self createTable:database];
    
    id statement = [database prepareStatement:@"INSERT INTO mysql_test (i, v, d) VALUES (?, ?, now())" error:&error];
    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:2];
    for (int i = 1; i <= 100 && !error; i++) {
        [values bindIntValue:i];
        [values bindStringValue:[NSString stringWithFormat:@"v%i", i]];
        [statement executeWithValues:values error:&error];
        [values removeAllObjects];
    }
    
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:1];
    id selectStatement = [database prepareStatement:@"SELECT * FROM mysql_test WHERE v like ?" error:&error];
    [params bindStringValue:@"v%"];
    [selectStatement executeWithValues:params error:&error];
    NSDictionary *resultDictionary;
    int cnt = 1;
    while (resultDictionary = [selectStatement fetchRowAsDictionary:nil]) {
        NSNumber *i = [NSNumber numberWithInt:cnt];
        NSString *v = [NSString stringWithFormat:@"v%d", cnt];
        STAssertEquals((int)[resultDictionary count], 3, @"fetchRowAsArrayWithSQL : resultCount");
        STAssertEqualObjects([resultDictionary objectForKey:@"i"], i , @"fetchRowAsArrayWithSQL : resultElement1");
        STAssertEqualObjects([resultDictionary objectForKey:@"v"], v, @"fetchRowAsArrayWithSQL : resultElement2");
        //STAssertEqualObjects([[resultDictionary objectForKey:@"d"] className], @"NSDate", @"fetchRowAsArrayWithSQL : resultElement3");
        cnt++;
    }
    [database executeSQL:@"DROP TABLE mysql_test" error:&error];
}

@end
