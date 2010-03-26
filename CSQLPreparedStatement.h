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
 
 @param values
 @param error
 
 @return <code>success</code>
 
 */
- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error;

/**
 
 @param error
 
 @return <code>success</code>
 
 */
- (BOOL)execute:(NSError **)error;

/**
 
 @param error
 
 @return <code>row</code> An <code>NSDictionary</code> instance containing the
 row contents, with the column names as keys.
 
 */

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error;

/**
 
 @param error
 
 @return <code>row</code> An <code>NSArray</code> instance containing the row
 contents.
 
 */
- (NSArray *)fetchRowAsArray:(NSError **)error;

@end

