//
//  CSQLDatabase+Protocol.h
//  CocoaSQL
//
//  Created by Igor Sutton on 4/8/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

@protocol CSQLDatabase

#pragma mark -
#pragma mark Class methods

/**
 
 Creates a CSQLDatabase object with the given driver and options.
 
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

@optional

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
- (NSUInteger)executeSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error; 

/**
 
 Executes a SQL statement.
 
 @param sql The SQL statement to be executed.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return Number of rows affected by the SQL statement.
 
 */
- (NSUInteger)executeSQL:(NSString *)sql error:(NSError **)error;

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
- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error; 

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
- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error; 

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
- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error; 

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
- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error;

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

@end
