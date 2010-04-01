/*
 *  CSQLPreparedStatement.h
 *  CocoaSQL
 *
 *  Created by Igor Sutton on 3/26/10.
 *  Copyright 2010 CocoaSQL.org. All rights reserved.
 *
 */

@protocol CSQLPreparedStatement

/**
 
 Executes the prepared statement with <code>values</code> as bind values. 
 Returns a <code>BOOL</code> value indicating if the operation was successful.
 If any error occurred, populates the <code>NSError</code> instance.
 
 @param values
 @param error
 
 @return <code>success</code>
 
 */
- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error;

/**
 
 Executes the prepared statement. Returns a <code>BOOL</code> value indicating
 if the operation was successful. If any error occurred, populates the 
 <code>NSError</code> instance.
 
 @param error
 
 @return <code>success</code>
 
 */
- (BOOL)execute:(NSError **)error;

/**
 
 If the executed prepared statement returns data, fetches the next pending row
 as an <code>NSDictionary</code> instance. If any error occurred, populates the
 <code>NSError</code> instance.
 
 @param error
 
 @return <code>row</code> An <code>NSDictionary</code> instance containing the
 row contents, with the column names as keys.
 
 */

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error;

/**
 
 If the executed prepared statement returns data, fetches the next pending row
 as an <code>NSArray</code> instance. Returns <code>nil</code> if there's no
 more rows to be fetched, or if any error occurred. In case of an error, also
 populates the <code>NSError</code> instance.
 
 @param error
 
 @return <code>row</code> An <code>NSArray</code> instance containing the row
 contents.
 
 */
- (NSArray *)fetchRowAsArray:(NSError **)error;

@end

