//
//  CSQLDatabase.h
//  CocoaSQL
//
//  Created by Igor Sutton on 3/25/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

@protocol CSQLDatabase

#pragma mark -
#pragma mark Class methods

#pragma mark -
#pragma mark Instance methods

/**
 
 Executes a SQL statement with bind values. If any error happened during the
 statement's execution, this method populates <code>error</code> and returns 
 <code>NO</code>.

 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error An <code>NSError</code> instance.
 
 @return BOOL <code>YES</code> if the statement was successfully executed, 
 <code>NO</code> otherwise.
 
 */
- (BOOL)executeSQL:(NSString *)sql 
        withValues:(NSArray *)values
             error:(NSError **)error; 

/**
 
 Executes a SQL statement. If any error happened during the statement's 
 execution, this method populates <code>error</code> and returns 
 <code>NO</code>.
 
 @param sql The SQL statement to be executed.
 @param error An <code>NSError</code> instance.
 
 @returns BOOL <code>YES</code> if the statement was successfully executed,
 <code>NO</code> otherwise.
 
 */
- (BOOL)executeSQL:(NSString *)sql 
             error:(NSError **)error;

/**
 
 Returns a NSDictionary instance containing the first row of the given SQL 
 statement. If any error occurred during the statement's execution, 
 <code>nil</code> is returned and <code>error</code> is populated.
 
 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error An <code>NSError</code> instance.
 
 @return <code>NSDictionary</code> The first row as a <code>NSDictionary</code>, 
 with the columns as keys.
 
 */
- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql
                                   withValues:(NSArray *)values
                                        error:(NSError **)error; 

/**
 
 Returns an <code>NSDictionary</code> instance containing the first row of the
 given SQL statement. If any error occurred during the statement's execution,
 <code>nil</code> is returned and <code>error</code> is populated.
 
 @param sql The SQL statement to be executed.
 @param error An <code>NSError</code> instance.
 
 @return <code>NSDictionary</code> The first row as a <code>NSDictionary</code>,
 with the columns as keys.
 
 */
- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql
                                        error:(NSError **)error;

/**
 
 Returns an <code>NSArray</code> instance containing the first row of the given
 SQL statement. If any error occurred during the statement's execution,
 <code>nil</code> is returned and <code>error</code> is populated.
 
 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error An <code>NSError</code> instance.
 
 @return <code>NSArray</code> The first row as a <code>NSArray</code>.
 
 */
- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql 
                         withValues:(NSArray *)values
                              error:(NSError **)error; 

/**
 
 Returns an <code>NSArray</code> instance containing the first row of the given
 SQL statement. If any error occurred during the statement's execution,
 <code>nil</code> is returned and <code>error</code> is populated.
 
 @param sql The SQL statement to be executed.
 @param error An <code>NSError</code> instance.
 
 @return <code>NSArray</code> The first row as a <code>NSArray</code>.
 
 */
- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql 
                              error:(NSError **)error;

/**
 
 Returns an <code>NSArray</code> instance containing all the rows returned by
 the SQL statement as <code>NSDictionary</code>. If any error occurred during 
 the statement's execution, <code>nil</code> is returned and <code>error</code>
 is populated.
 
 @param sql The SQL statement to be executed.
 @param values An <code>NSArray</code> instance with values.
 @param error An <code>NSError</code> instance.
 
 @return <code>NSArray</code> <code>NSArray</code> containing all the rows 
 returned by the statement as <code>NSDictionary</code>, with the column names
 as keys.
 
 */
- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql 
                                 withValues:(NSArray *)values
                                      error:(NSError **)error; 

/**
 
 Returns an <code>NSArray</code> instance containing all the rows returned by
 the SQL statement as <code>NSDictionary</code>. If any error occurred during 
 the statement's execution, <code>nil</code> is returned and <code>error</code>
 is populated.
 
 @param sql The SQL statement to be executed.
 @param error An <code>NSError</code> instance.
 
 @return <code>NSArray</code> <code>NSArray</code> containing all the rows 
 returned by the statement as <code>NSDictionary</code>, with the column names
 as keys.
 
 */
- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql 
                                      error:(NSError **)error;

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                           withValues:(NSArray *)values 
                                error:(NSError **)error;

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                                error:(NSError **)error;

@end
