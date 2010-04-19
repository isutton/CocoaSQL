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

#define DATA_TYPE @"dataType"
#define SELECTOR @"selector"
#define BIND_VALUE  @"bindValue"
#define BLOB "some blob data"

- (void)test4DataTypes2
{
    NSError *error = nil;
    
    NSArray *tests = [NSArray arrayWithObjects:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithShort:32767], BIND_VALUE,
                       @"SMALLINT", DATA_TYPE,
                       @"numberValue", SELECTOR,
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:2147483647], BIND_VALUE,
                       @"INTEGER", DATA_TYPE,
                       @"numberValue", SELECTOR,
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithLong:92233720368547758L], BIND_VALUE,
                       @"BIGINT", DATA_TYPE,
                       @"numberValue", SELECTOR,
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithDouble:1.66666666666666], BIND_VALUE,
                       @"DOUBLE PRECISION", DATA_TYPE,
                       @"numberValue", SELECTOR,
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"v1", BIND_VALUE,
                       @"VARCHAR(255)", DATA_TYPE,
                       @"stringValue", SELECTOR,
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSDate dateWithString:@"2001-03-24 00:00:00 +0100"], BIND_VALUE,
                       @"DATE", DATA_TYPE,
                       @"dateValue", SELECTOR,
                       nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSData dataWithBytes:BLOB length:strlen(BLOB)], BIND_VALUE,
                       @"BYTEA", DATA_TYPE,
                       @"dataValue", SELECTOR,
                       nil],
                      nil];
    
    CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"PostgreSQL" options:[NSDictionary dictionary] error:&error];
    
    for (NSDictionary *test in tests) {

        [database executeSQL:[NSString stringWithFormat:@"CREATE TABLE t (c %@)", [test objectForKey:DATA_TYPE]] 
                       error:&error];
        STAssertNil(error, [error description]);
        
        error = nil;
        CSQLPreparedStatement *statement = [database prepareStatement:@"INSERT INTO t (c) VALUES ($1)" error:&error];
        STAssertNotNil(statement, [error description]);

        NSArray *values = [NSArray arrayWithObject:[test objectForKey:BIND_VALUE]];
        
        error = nil;
        BOOL success = [statement executeWithValues:values error:&error];
        STAssertTrue(success, [error description]);

        [statement finish];
        
        error = nil;
        statement = [database prepareStatement:@"SELECT c FROM t" error:&error];
        STAssertNotNil(statement, [error description]);
        
        error = nil;
        success = [statement execute:&error];
        STAssertTrue(success, [error description]);
        
        //
        // fetchRowAsArray:
        //
        if (statement) {
            error = nil;
            NSArray *row = [statement fetchRowAsArray:&error];
            STAssertNotNil(row, [error description]);
            STAssertEqualObjects([[row objectAtIndex:0] performSelector:NSSelectorFromString([test objectForKey:SELECTOR])], [test objectForKey:BIND_VALUE], @"");

            [statement finish];
        }
        
        error = nil;
        statement = [database prepareStatement:@"SELECT c FROM t" error:&error];
        STAssertNotNil(statement, [error description]);
        
        error = nil;
        success = [statement execute:&error];
        STAssertTrue(success, [error description]);
        
        //
        // fetchRowAsDictionary
        //
        if (statement) {
            error = nil;
            NSDictionary *row = [statement fetchRowAsDictionary:&error];
            STAssertNotNil(row, [error description]);
            STAssertEqualObjects([[row objectForKey:@"c"] performSelector:NSSelectorFromString([test objectForKey:SELECTOR])], [test objectForKey:BIND_VALUE], @"");
            
            [statement finish];
        }
        
        
        [database executeSQL:@"DROP TABLE t" error:&error];       
        STAssertNil(error, [error description]);
    }
}

@end
