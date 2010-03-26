/*
 *  CSQLPreparedStatement.h
 *  CocoaSQL
 *
 *  Created by Igor Sutton on 3/26/10.
 *  Copyright 2010 CocoaSQL.org. All rights reserved.
 *
 */

@protocol CSQLPreparedStatement

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error;

- (BOOL)execute:(NSError **)error;

- (NSDictionary *)fetchRowAsDictionary;

- (NSArray *)fetchRowAsArray;

@end

