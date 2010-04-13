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
    
    affectedRows = [database executeSQL:@"CREATE TABLE mysql_test (i MEDIUMINT, v VARCHAR(10), d DATETIME, t timestamp, bs BIGINT signed, bu BIGINT unsigned, f float, n INTEGER NULL)" error:&error];
    
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

    CSQLDatabase *database = [self createDatabase:&error];

    [database executeSQL:@"SET SQL_MODE='TRADITIONAL'" error:&error];
    if (error) STFail([[error userInfo] objectForKey:@"errorMessage"]);

    error = nil;

    [self createTable:database];
    
    // TODO - test if giving a wrong statement fails properly
    CSQLPreparedStatement *statement = [database prepareStatement:@"INSERT INTO mysql_test (i, v, d, t, bs, bu, f, n) VALUES (?, ?, now(), now(), -9223372036854775808, 18446744073709551615, 0.123456789, NULL)" error:&error];
    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:2];
    for (int i = 1; i <= 100 && !error; i++) {
        [values bindIntValue:i];
        [values bindStringValue:[NSString stringWithFormat:@"v%i", i]];
        [statement executeWithValues:values error:&error];
        [values removeAllObjects];
    }

    
    error = nil;
    CSQLPreparedStatement *selectStatement = [database prepareStatement:@"SELECT * FROM mysql_test WHERE v like ?" error:&error];
    NSArray *params = [NSArray arrayWithObject:@"v%"];
    [selectStatement executeWithValues:params error:&error];
    NSDictionary *resultDictionary;
    int cnt = 0;
    while (resultDictionary = [selectStatement fetchRowAsDictionary:&error]) {
        cnt++;
        NSNumber *i = [NSNumber numberWithInt:cnt];
        NSString *v = [NSString stringWithFormat:@"v%d", cnt];
        STAssertEquals((int)[resultDictionary count], 8, @"fetchRowAsDictionaryWithSQL : resultCount");
        STAssertEqualObjects([[resultDictionary objectForKey:@"i"] numberValue],
                             i,
                             @"fetchRowAsArrayWithSQL : resultElement1");
        STAssertEqualObjects([[resultDictionary objectForKey:@"v"] stringValue],
                             v,
                             @"fetchRowAsArrayWithSQL : resultElement2");
        //TODO - find a proper way to test dates
        //STAssertTrue([[[resultDictionary objectForKey:@"d"] class] isSubclassOfClass:[NSDate class]], @"fetchRowAsArrayWithSQL : resultElement3");
        STAssertEqualObjects([[resultDictionary objectForKey:@"bs"] numberValue],
                             [NSNumber numberWithLongLong:-9223372036854775808UL], 
                             @"fetchRowAsDictionaryWithSQL : bigint signed");
        STAssertEqualObjects([[resultDictionary objectForKey:@"bu"] numberValue],
                             [NSNumber numberWithUnsignedLongLong:18446744073709551615UL],
                             @"fetchRowAsDictionaryWithSQL : bigint unsigned");
        STAssertEqualObjects([[resultDictionary objectForKey:@"f"] numberValue],
                             [NSNumber numberWithFloat:0.123456789],
                             @"fetchRowAsDictionaryWithSQL : float");
        STAssertTrue([[resultDictionary objectForKey:@"n"] isNull], @"fetchRowAsDictionaryWithSQL : NULL");

        NSLog(@"Row %d: %@\n",cnt, resultDictionary);
    }
    if (error)
        NSLog(@"%@\n", error);
    STAssertEquals(cnt, 100, @"Number of retreived rows)"); // ensure we got all rows
    // test fetchRowAsArray
    [selectStatement executeWithValues:params error:&error];
    NSArray *resultArray;
    cnt = 0;
    while (resultArray = [selectStatement fetchRowAsArray:nil]) {
        cnt++;
        NSNumber *i = [NSNumber numberWithInt:cnt];
        NSString *v = [NSString stringWithFormat:@"v%d", cnt];
        STAssertEquals((int)[resultArray count], 8, @"fetchRowAsArrayWithSQL : resultCount");
        STAssertEqualObjects([[resultArray objectAtIndex:0] numberValue],
                             i,
                             @"fetchRowAsArrayWithSQL : resultElement1");
        STAssertEqualObjects([[resultArray objectAtIndex:1] stringValue],
                             v,
                             @"fetchRowAsArrayWithSQL : resultElement2");
        //TODO - find a proper way to test dates
        //STAssertTrue([[[resultDictionary objectForKey:@"d"] class] isSubclassOfClass:[NSDate class]], @"fetchRowAsArrayWithSQL : resultElement3");
        STAssertEqualObjects([[resultArray objectAtIndex:4] numberValue],
                             [NSNumber numberWithLongLong:-9223372036854775808UL], 
                             @"fetchRowAsDictionaryWithSQL : bigint signed");
        STAssertEqualObjects([[resultArray objectAtIndex:5] numberValue],
                             [NSNumber numberWithUnsignedLongLong:18446744073709551615UL],
                             @"fetchRowAsDictionaryWithSQL : bigint unsigned");
        STAssertEqualObjects([[resultArray objectAtIndex:6] numberValue],
                             [NSNumber numberWithFloat:0.123456789],
                             @"fetchRowAsDictionaryWithSQL : float");
        STAssertTrue([[resultArray objectAtIndex:7] isNull], @"fetchRowAsArray : NULL");
        //NSLog(@"Row: %@\n", resultDictionary);
    }
    if (error)
        NSLog(@"%@\n", error);
    STAssertEquals(cnt, 100, @"Number of retreived rows)"); // ensure we got all rows
    
    [database executeSQL:@"DROP TABLE mysql_test" error:&error];
    if (error)
        NSLog(@"%@\n", error);
}

@end
