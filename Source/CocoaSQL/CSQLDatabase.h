//
//
//  This file is part of CocoaSQL
//
//  CocoaSQL is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with CocoaSQL.  If not, see <http://www.gnu.org/licenses/>.
//
//  CSQLDatabase.h by Igor Sutton on 3/25/10.
//

#import "CSQLPreparedStatement.h"

@class CSQLDatabase;

@interface CSQLDatabase : NSObject
{
    voidPtr databaseHandle;
	NSNumber *affectedRows;
}

@property (readonly,assign) voidPtr databaseHandle;
@property (readonly,assign) NSNumber *affectedRows;

+ (CSQLDatabase *)databaseWithDSN:(NSString *)aDSN error:(NSError **)error;
+ (CSQLDatabase *)databaseWithDriver:(NSString *)aDriver options:(NSDictionary *)options error:(NSError **)error;

- (NSNumber *)lastInsertID;
- (BOOL)disconnect;
- (BOOL)disconnect:(NSError **)error;
- (BOOL)isActive;
- (BOOL)isActive:(NSError **)error;


#pragma mark -
#pragma mark Class methods

/**
 
 Creates a CSQLDatabase object with the given driver and options.
 
 The driver class is built from the following format: "CS%@Database".
 
 @param aDriver
 @param options
 @param error
 
 @return The CSQLDatabase object.
 
 */
+ (CSQLDatabase *)databaseWithDriver:(NSString *)aDriver options:(NSDictionary *)options error:(NSError **)error;

/**
 
 Creates a CSQLDatabase object with the given DSN. The DSN has the following
 syntax:
 
 <code>DRIVER:OPT1=VAL1;OPT2=VAL2</code>
 
 The options are parsed and stored in a NSDictionary. Both driver and options
 are then used with databaseWithDriver:options:error:.
 
 @param aDSN
 @param error
 
 @return The CSQLDatabase object.
 
 */
+ (CSQLDatabase *)databaseWithDSN:(NSString *)aDSN error:(NSError **)error;

- (BOOL)disconnect;

- (BOOL)isActive;

/**
 
 This method should be implemented by subclasses.
 
 @param options
 @param error
 
 @return The CSQLDatabase object.
 
 */
+ (CSQLDatabase *)databaseWithOptions:(NSDictionary *)options error:(NSError **)error;

#pragma mark -
#pragma mark Instance methods

/**
 
 Executes a SQL statement with bind values.
 
 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return Number of rows affected by the SQL statement.
 
 */
- (BOOL)executeSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error; 

/**
 
 Executes a SQL statement.
 
 @param sql The SQL statement to be executed.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return Number of rows affected by the SQL statement.
 
 */
- (BOOL)executeSQL:(NSString *)sql error:(NSError **)error;

/**
 
 Returns a NSDictionary instance containing the first row of the given SQL 
 statement.
 
 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return <code>NSDictionary</code> The first row as a <code>NSDictionary</code>, 
 with the columns as keys.
 
 */
- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql andValues:(NSArray *)values error:(NSError **)error; 

/**
 
 Returns an <code>NSDictionary</code> instance containing the first row of the
 given SQL statement.
 
 @param sql The SQL statement to be executed.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return <code>NSDictionary</code> The first row as a <code>NSDictionary</code>,
 with the columns as keys.
 
 */
- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql error:(NSError **)error;

/**
 
 Returns an <code>NSArray</code> instance containing the first row of the given
 SQL statement.
 
 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return <code>NSArray</code> The first row as a <code>NSArray</code>.
 
 */
- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql andValues:(NSArray *)values error:(NSError **)error; 

/**
 
 Returns an <code>NSArray</code> instance containing the first row of the given
 SQL statement. 
 
 @param sql The SQL statement to be executed.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return <code>NSArray</code> The first row as a <code>NSArray</code>.
 
 */
- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql error:(NSError **)error;

/**
 
 Returns an <code>NSArray</code> instance containing all the rows returned by
 the SQL statement as <code>NSDictionary</code>.
 
 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return <code>NSArray</code> <code>NSArray</code> containing all the rows 
 returned by the statement as <code>NSDictionary</code>, with the column names
 as keys.
 
 */
- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql andValues:(NSArray *)values error:(NSError **)error; 

/**
 
 Returns an <code>NSArray</code> instance containing all the rows returned by
 the SQL statement as <code>NSDictionary</code>.
 
 @param sql The SQL statement to be executed.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 
 @return <code>NSArray</code> <code>NSArray</code> containing all the rows 
 returned by the statement as <code>NSDictionary</code>, with the column names
 as keys.
 
 */
- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql error:(NSError **)error;

/**
 
 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 
 @return <code>rows</code>
 
 */
- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql andValues:(NSArray *)values error:(NSError **)error;

/**
 
 @param sql The SQL statement to be executed.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 
 @return <code>rows</code>
 
 */
- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql error:(NSError **)error;

/**
 
 @param sql
 @param error
 
 @return statement
 
 */
- (CSQLPreparedStatement *)prepareStatement:(NSString *)sql error:(NSError **)error;

- (BOOL)isActive:(NSError **)error;

- (BOOL)disconnect:(NSError **)error;

@end