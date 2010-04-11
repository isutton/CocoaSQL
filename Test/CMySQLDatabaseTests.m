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
    
    affectedRows = [database executeSQL:@"CREATE TABLE mysql_test (i MEDIUMINT, v VARCHAR(10), d DATETIME, t timestamp, bs BIGINT signed, bu BIGINT unsigned )" error:&error];
    
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
    [self createTable:database];
    
    
    // TODO - test if giving a wrong statement fails properly
    CSQLPreparedStatement *statement = [database prepareStatement:@"INSERT INTO mysql_test (i, v, d, t, bs, bu) VALUES (?, ?, now(), now(), -9223372036854775808, 18446744073709551615)" error:&error];
    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:2];
    for (int i = 1; i <= 100 && !error; i++) {
        [values bindIntValue:i];
        [values bindStringValue:[NSString stringWithFormat:@"v%i", i]];
        [statement executeWithValues:values error:&error];
        [values removeAllObjects];
    }
    
    CSQLPreparedStatement *selectStatement = [database prepareStatement:@"SELECT * FROM mysql_test WHERE v like ?" error:&error];
    NSArray *params = [NSArray arrayWithObject:[CSQLBindValue bindValueWithString:@"v%"]];
    [selectStatement executeWithValues:params error:&error];
    NSDictionary *resultDictionary;
    int cnt = 0;
    while (resultDictionary = [selectStatement fetchRowAsDictionary:&error]) {
        cnt++;
        NSNumber *i = [NSNumber numberWithInt:cnt];
        NSString *v = [NSString stringWithFormat:@"v%d", cnt];
        STAssertEquals((int)[resultDictionary count], 6, @"fetchRowAsDictionaryWithSQL : resultCount");
        STAssertEqualObjects([resultDictionary objectForKey:@"i"], i , @"fetchRowAsDictionaryWithSQL : resultElement1");
        STAssertEqualObjects([resultDictionary objectForKey:@"v"], v, @"fetchRowAsDictionaryWithSQL : resultElement2");
        STAssertTrue([[[resultDictionary objectForKey:@"d"] class] isSubclassOfClass:[NSDate class]], @"fetchRowAsDictionaryWithSQL : resultElement3");
        STAssertEqualObjects([resultDictionary objectForKey:@"bs"], [NSNumber numberWithLongLong:-9223372036854775808UL], @"fetchRowAsDictionaryWithSQL : bigint signed");
        STAssertEqualObjects([resultDictionary objectForKey:@"bu"], [NSNumber numberWithUnsignedLongLong:18446744073709551615UL], @"fetchRowAsDictionaryWithSQL : bigint unsigned");
        NSLog(@"Row: %@\n", resultDictionary);
    }
    if (error)
        NSLog(@"%@\n", error);
    STAssertEquals(cnt, 100, @"Number of retreived rows)");
    // test fetchRowAsArray
    [selectStatement executeWithValues:params error:&error];
    NSArray *resultArray;
    cnt = 0;
    while (resultArray = [selectStatement fetchRowAsArray:nil]) {
        cnt++;
        NSNumber *i = [NSNumber numberWithInt:cnt];
        NSString *v = [NSString stringWithFormat:@"v%d", cnt];
        STAssertEquals((int)[resultArray count], 6, @"fetchRowAsArrayWithSQL : resultCount");
        STAssertEqualObjects([resultArray objectAtIndex:0], i , @"fetchRowAsArrayWithSQL : resultElement1");
        STAssertEqualObjects([resultArray objectAtIndex:1], v, @"fetchRowAsArrayWithSQL : resultElement2");
        STAssertTrue([[[resultArray objectAtIndex:2] class] isSubclassOfClass:[NSDate class]], @"fetchRowAsArrayWithSQL : resultElement3");
        STAssertEqualObjects([resultArray objectAtIndex:4], [NSNumber numberWithLongLong:-9223372036854775808UL], @"fetchRowAsDictionaryWithSQL : bigint signed");
        STAssertEqualObjects([resultArray objectAtIndex:5], [NSNumber numberWithUnsignedLongLong:18446744073709551615UL], @"fetchRowAsDictionaryWithSQL : bigint unsigned");
        //NSLog(@"Row: %@\n", resultDictionary);
    }
    if (error)
        NSLog(@"%@\n", error);
    STAssertEquals(cnt, 100, @"Number of retreived rows)");
    
    [database executeSQL:@"DROP TABLE mysql_test" error:&error];
    if (error)
        NSLog(@"%@\n", error);
}
/*
- (void)testMysqlNoCSQLBindValue
{
    NSError *error = nil;
    CSQLDatabase *database = [self createDatabase:&error];
    [self createTable:database];
    
    CSQLPreparedStatement *statement = [database prepareStatement:@"INSERT INTO mysql_test (i, v, d) VALUES (?, ?, now())" 
                                                            error:&error];
    
    for (int i = 1; i <= 100 && !error; i++) {
        [statement executeWithValues:[NSArray arrayWithObjects:
                                      [NSNumber numberWithInt:i],
                                      [NSString stringWithFormat:@"v%d", i],
                                      nil
                                      ]
                               error:&error];
    }
    
    CSQLPreparedStatement *selectStatement = [database prepareStatement:@"SELECT * FROM mysql_test WHERE v like ?" error:&error];
    NSArray *params = [NSArray arrayWithObject:@"v%"];
    [selectStatement executeWithValues:params error:&error];
    NSDictionary *resultDictionary;
    int cnt = 1;
    while (resultDictionary = [selectStatement fetchRowAsDictionary:&error]) {
        NSNumber *i = [NSNumber numberWithInt:cnt];
        NSString *v = [NSString stringWithFormat:@"v%d", cnt];
        STAssertEquals((int)[resultDictionary count], 3, @"fetchRowAsArrayWithSQL : resultCount");
        STAssertEqualObjects([resultDictionary objectForKey:@"i"], i , @"fetchRowAsArrayWithSQL : resultElement1");
        STAssertEqualObjects([resultDictionary objectForKey:@"v"], v, @"fetchRowAsArrayWithSQL : resultElement2");
        STAssertTrue([[[resultDictionary objectForKey:@"d"] class] isSubclassOfClass:[NSDate class]], @"fetchRowAsArrayWithSQL : resultElement3");
        //NSLog(@"Row: %@\n", resultDictionary);
        NSNumber *a = [NSNumber numberWithInt:324];
        NSNumber *b = [NSNumber numberWithFloat:4.5];
        NSLog(@"a: %@ - b: %@\n", [a className], [b className]);

        cnt++;
    }
    [database executeSQL:@"DROP TABLE mysql_test" error:&error];
}*/
@end
