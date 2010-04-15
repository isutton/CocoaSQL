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
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"PostgreSQL" options:[NSDictionary dictionary] error:&error];
    
    error = nil;
    CSQLPreparedStatement *statement = [database prepareStatement:@"CREATE TABLE t (i NUMERIC, v VARCHAR(255))" error:&error];

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
                       [NSNumber numberWithUnsignedLongLong:18446744073709551615UL],
                       @"v1",
                       nil];
    
    STAssertTrue([statement executeWithValues:values error:&error], @"Statement was not executed.");
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

    NSString *createTableQuery = @"CREATE TABLE t (i NUMERIC, v VARCHAR(255), b BYTEA)";
    
    error = nil;
    CSQLPreparedStatement *statement = [database prepareStatement:createTableQuery error:&error];

    STAssertNotNil(statement, @"Statement was not created.");
    STAssertTrue([statement isKindOfClass:[CSPostgreSQLPreparedStatement class]], @"Got object of wrong kind.");
    
    error = nil;
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, @"An error occurred: %@", error);
    
    [statement release];
    statement = nil;
    
    error = nil;
    statement = [database prepareStatement:@"INSERT INTO t (i, v, b) VALUES ($1, $2, $3)" error:&error];

    STAssertNotNil(statement, @"Statement was not created.");
    STAssertTrue([statement isKindOfClass:[CSPostgreSQLPreparedStatement class]], @"Got object of wrong kind.");

    NSArray *values = [NSArray arrayWithObjects:
                       [NSNumber numberWithInt:1],
                       @"v1",
                       [@"something here and there" dataUsingEncoding:NSUTF8StringEncoding],
                       nil];
    
    error = nil;
    STAssertTrue([statement executeWithValues:values error:&error], @"Statement was not executed.");
    STAssertNil(error, [error description]);
    STAssertFalse(statement.canFetch, @"Statement should not return rows.");
    
    [statement release];
    statement = nil;
    
    error = nil;
    statement = [database prepareStatement:@"SELECT i, v, t FROM t" error:&error];

    STAssertNotNil(statement, @"Statement was not created.");
    STAssertTrue([statement isKindOfClass:[CSPostgreSQLPreparedStatement class]], @"Got object of wrong kind.");
    
    error = nil;
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, [error description]);
    STAssertTrue(statement.canFetch, @"Statement should return rows.");
    
    error = nil;
    NSArray *array = [statement fetchRowAsArray:&error];

    STAssertNotNil(array, @"Row shouldn't be nil.");
    STAssertEqualObjects([[array objectAtIndex:0] numberValue], [values objectAtIndex:0], @"");
    STAssertEqualObjects([[array objectAtIndex:1] stringValue], [values objectAtIndex:1], @"");
    STAssertEqualObjects([[array objectAtIndex:2] dataValue], [values objectAtIndex:2], @"");

    [statement release];
    statement = nil;
    
    error = nil;
    statement = [database prepareStatement:@"SELECT i, v, t FROM t" error:&error];
    
    STAssertNotNil(statement, @"Statement was not created.");
    STAssertTrue([statement isKindOfClass:[CSPostgreSQLPreparedStatement class]], @"Got object of wrong kind.");
    
    error = nil;
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, [error description]);
    STAssertTrue(statement.canFetch, @"Statement should return rows.");
    
    error = nil;
    NSDictionary *dictionary = [statement fetchRowAsDictionary:&error];
    
    STAssertNotNil(dictionary, @"Row shouldn't be nil.");
    STAssertEqualObjects([[dictionary objectForKey:@"i"] numberValue], [values objectAtIndex:0], @"");
    STAssertEqualObjects([[dictionary objectForKey:@"v"] stringValue], [values objectAtIndex:1], @"");
    STAssertEqualObjects([[dictionary objectForKey:@"v"] dataValue], [values objectAtIndex:2], @"");

    [statement release];
    statement = nil;
    
#if 1
    
    //
    // Clean up.
    //
    
    error = nil;
    
    statement = [database prepareStatement:@"DROP TABLE t" error:&error];
    STAssertTrue([statement execute:&error], @"Statement was not executed.");
    STAssertNil(error, @"An error occurred. %@", error);
    
    [statement release];
    statement = nil;
    
#endif    
    
}
@end
