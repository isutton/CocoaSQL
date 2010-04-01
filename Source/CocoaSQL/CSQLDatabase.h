//
//  CSQLDatabase.h
//  CocoaSQL
//
//  Created by Igor Sutton on 3/25/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSQLPreparedStatement.h"

@protocol CSQLDatabase <NSObject>

#pragma mark -
#pragma mark Class methods

+ (id)databaseWithOptions:(NSDictionary *)options 
                    error:(NSError **)error;

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
- (NSUInteger)executeSQL:(NSString *)sql 
              withValues:(NSArray *)values
                   error:(NSError **)error; 

/**
 
 Executes a SQL statement.
 
 @param sql The SQL statement to be executed.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return Number of rows affected by the SQL statement.
 
 */
- (NSUInteger)executeSQL:(NSString *)sql 
                   error:(NSError **)error;

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
- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql
                                   withValues:(NSArray *)values
                                        error:(NSError **)error; 

/**
 
 Returns an <code>NSDictionary</code> instance containing the first row of the
 given SQL statement.
 
 @param sql The SQL statement to be executed.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return <code>NSDictionary</code> The first row as a <code>NSDictionary</code>,
 with the columns as keys.
 
 */
- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql
                                        error:(NSError **)error;

/**
 
 Returns an <code>NSArray</code> instance containing the first row of the given
 SQL statement.
 
 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return <code>NSArray</code> The first row as a <code>NSArray</code>.
 
 */
- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql 
                         withValues:(NSArray *)values
                              error:(NSError **)error; 

/**
 
 Returns an <code>NSArray</code> instance containing the first row of the given
 SQL statement. 
 
 @param sql The SQL statement to be executed.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.
 
 @return <code>NSArray</code> The first row as a <code>NSArray</code>.
 
 */
- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql 
                              error:(NSError **)error;

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
- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql 
                                 withValues:(NSArray *)values
                                      error:(NSError **)error; 

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
- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql 
                                      error:(NSError **)error;

/**
 
 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.

 
 @return <code>rows</code>
 
 */
- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                           withValues:(NSArray *)values 
                                error:(NSError **)error;

/**
 
 @param sql The SQL statement to be executed.
 @param error If an error occurs, upon return contains an instance of 
 <code>NSError</code> that describes the problem.

 
 @return <code>rows</code>
 
 */
- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                                error:(NSError **)error;

- (id <CSQLPreparedStatement>)prepareStatement:(NSString *)sql 
                                         error:(NSError **)error;

@end

@interface CSQLDatabase : NSObject
{

}

+ (id <CSQLDatabase>)databaseWithDriver:(NSString *)aDriver 
                                options:(NSDictionary *)options
                                  error:(NSError **)error;

@end

