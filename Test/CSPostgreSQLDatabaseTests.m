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
//  CSPostgreDatabaseSQLTests.m by Igor Sutton on 4/13/10.
//

#import "CocoaSQL.h"
#import "CSPostgreSQLDatabase.h"
#import "CSPostgreSQLPreparedStatement.h"
#import "CSPostgreSQLDatabaseTests.h"

@implementation CSPostgreSQLDatabaseTests

- (void)test1DatabaseWithDSN 
{
    NSError *error = nil;
    CSQLDatabase *database = [CSQLDatabase databaseWithDSN:@"PostgreSQL:" error:&error];
    
    STAssertNotNil(database, @"Database was not created.");
    STAssertTrue([database isKindOfClass:[CSPostgreSQLDatabase class]], @"Got object of wrong kind.");
    STAssertNotNil(database.databaseHandle, @"Database connection was not opened.");    
}

- (void)test2DatabaseWithDriver
{
    NSError *error = nil;
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"PostgreSQL" options:[NSDictionary dictionary] error:&error];
    
    STAssertNotNil(database, @"Database was not created.");
    STAssertTrue([database isKindOfClass:[CSPostgreSQLDatabase class]], @"Got object of wrong kind.");
    STAssertNotNil(database.databaseHandle, @"Database connection was not opened.");    
}

- (void)test3PreparedStatement
{
    NSError *error = nil;
    BOOL success;
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"PostgreSQL" options:[NSDictionary dictionary] error:&error];
    
    error = nil;
    CSQLPreparedStatement *statement = [database prepareStatement:@"CREATE TABLE t (i INT, v VARCHAR(255))" error:&error];
    // CSQLPreparedStatement *statement = [database prepareStatement:@"CREATE TABLE t (i INT)" error:&error];

    STAssertNotNil(statement, @"Statement was not created.");
    STAssertTrue([statement isKindOfClass:[CSPostgreSQLPreparedStatement class]], @"Got object of wrong kind.");

    error = nil;
    success = [statement execute:&error];
    STAssertTrue(success, @"Statement was not executed.");
    STAssertNil(error, @"An error occurred: %@", error);
    
#if 1
    error = nil;
    statement = [database prepareStatement:@"INSERT INTO t (i, v) VALUES ($1, $2)" error:&error];
    // statement = [database prepareStatement:@"INSERT INTO t (i) VALUES ($1)" error:&error];

    STAssertNotNil(statement, @"Statement was not created.");
    STAssertNil(error, [error description]);

    error = nil;
    
    NSArray *values = [NSArray arrayWithObjects:
                       [NSNumber numberWithInt:1],
                       @"v1",
                       nil];

    success = [statement executeWithValues:values error:&error];
    STAssertTrue(success, @"Statement was not executed.");
    STAssertNil(error, [error description]);
    STAssertFalse(statement.canFetch, @"Statement should return not rows.");
#endif
        
#if 1

    //
    // Clean up.
    //
    
    error = nil;

    statement = [database prepareStatement:@"DROP TABLE t" error:&error];
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, @"An error occurred. %@", error);
#endif
    
}

- (void)test4DataTypes
{
    NSError *error = nil;
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"PostgreSQL" options:[NSDictionary dictionary] error:&error];

    error = nil;
    CSQLPreparedStatement *statement = [database prepareStatement:@"CREATE TABLE t (i2 SMALLINT, i4 INTEGER, i8 BIGINT, r DOUBLE PRECISION, v VARCHAR(255), d DATE, b BYTEA)" error:&error];

    STAssertNotNil(statement, @"Statement was not created.");
    STAssertTrue([statement isKindOfClass:[CSPostgreSQLPreparedStatement class]], @"Got object of wrong kind.");
    STAssertNil(error, @"An error occurred: %@", error);
    
    error = nil;
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, @"An error occurred: %@", error);
    
    //[statement release]; // XXX - that's already in the autorelease pool , we don't need to release it esplicitly
    statement = nil;
    
    error = nil;
    statement = [database prepareStatement:@"INSERT INTO t (i2, i4, i8, r, v, d, b) VALUES ($1, $2, $3, $4, $5, $6, $7)" error:&error];

    STAssertNotNil(statement, @"Statement was not created.");
    STAssertTrue([statement isKindOfClass:[CSPostgreSQLPreparedStatement class]], @"Got object of wrong kind.");

	char *data = "something here and there"; // TODO - find a better way to load some blob data
    NSArray *values = [NSArray arrayWithObjects:
                       [NSNumber numberWithShort:32767],
                       [NSNumber numberWithInt:2147483647],
                       [NSNumber numberWithLong:92233720368547758L],
                       [NSNumber numberWithDouble:1.66666666666666],
                       @"v1",
                       [NSDate dateWithString:@"2001-03-24 00:00:00 +0100"],  
                       [NSData dataWithBytes:data length:strlen(data)],
                       nil];
    
    error = nil;
    STAssertTrue([statement executeWithValues:values error:&error], @"Statement was not executed.");
    STAssertNil(error, [error description]);
    STAssertFalse(statement.canFetch, @"Statement should not return rows.");
    
    //[statement release]; // XXX - that's already in the autorelease pool , we don't need to release it esplicitly
    statement = nil;
    
    error = nil;
    statement = [database prepareStatement:@"SELECT i2, i4, i8, r, v, d, b FROM t" error:&error];

    STAssertNotNil(statement, @"Statement was not created.");
    STAssertTrue([statement isKindOfClass:[CSPostgreSQLPreparedStatement class]], @"Got object of wrong kind.");
    
    error = nil;
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, [error description]);
    STAssertTrue(statement.canFetch, @"Statement should return rows.");
    
    error = nil;
    NSArray *array = [statement fetchRowAsArray:&error];

    int i = 0;
    STAssertNotNil(array, @"Row shouldn't be nil.");
    STAssertEquals([[[array objectAtIndex:i] numberValue] shortValue], [[values objectAtIndex:i++] shortValue], @"");
    STAssertEqualObjects([[array objectAtIndex:i] numberValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[array objectAtIndex:i] numberValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[array objectAtIndex:i] numberValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[array objectAtIndex:i] stringValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[array objectAtIndex:i] dateValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[array objectAtIndex:i] dataValue], [values objectAtIndex:i++], @"");
    // NSLog(@"%@ %@", [values objectAtIndex:2], [[array objectAtIndex:2] dataValue]);

    //[statement release]; // XXX - that's already in the autorelease pool , we don't need to release it esplicitly
    statement = nil;
    
    error = nil;
    statement = [database prepareStatement:@"SELECT i2, i4, i8, r, d, v, b FROM t" error:&error];
    
    STAssertNotNil(statement, @"Statement was not created.");
    STAssertTrue([statement isKindOfClass:[CSPostgreSQLPreparedStatement class]], @"Got object of wrong kind.");
    
    error = nil;
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, [error description]);
    STAssertTrue(statement.canFetch, @"Statement should return rows.");
    
    error = nil;
    NSDictionary *dictionary = [statement fetchRowAsDictionary:&error];
    
    i = 0;
    STAssertNotNil(dictionary, @"Row shouldn't be nil.");
    STAssertEqualObjects([[dictionary objectForKey:@"i2"] numberValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[dictionary objectForKey:@"i4"] numberValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[dictionary objectForKey:@"i8"] numberValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[dictionary objectForKey:@"r"] numberValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[dictionary objectForKey:@"v"] stringValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[dictionary objectForKey:@"d"] dateValue], [values objectAtIndex:i++], @"");
    STAssertEqualObjects([[dictionary objectForKey:@"b"] dataValue], [values objectAtIndex:i++], @"");
    // NSLog(@"%@ %@", [values objectAtIndex:2], [[dictionary objectForKey:@"b"] dataValue]);

    //[statement release]; // XXX - that's already in the autorelease pool , we don't need to release it esplicitly
    statement = nil;
    
#if 1
    
    //
    // Clean up.
    //
    
    error = nil;
    
    statement = [database prepareStatement:@"DROP TABLE t" error:&error];
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, @"An error occurred. %@", error);
    
    //[statement release]; // XXX - that's already in the autorelease pool , we don't need to release it esplicitly
    statement = nil;
    
#endif    
    
}

@end
