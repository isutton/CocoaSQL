/*
 *  CSQLPreparedStatement.h
 *  CocoaSQL
 *
 *  Created by Igor Sutton on 3/26/10.
 *  Copyright 2010 CocoaSQL.org. All rights reserved.
 *
 */

#import "CSQLPreparedStatement+Protocol.h"

@class CSQLDatabase;

@interface CSQLPreparedStatement : NSObject <CSQLPreparedStatement>
{
    CSQLDatabase *database;
    BOOL canFetch;
}

@property (retain) CSQLDatabase *database;
@property (readonly) BOOL canFetch;

/**
 
 @param database
 @param sql
 
 @return <code>preparedStatement</code>
 
 */
+ (id)preparedStatementWithDatabase:(CSQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error;

/**
 
 @param aDatabase
 @param sql
 @param error
 
 @return 
 
 */
- (id)initWithDatabase:(CSQLDatabase *)aDatabase;
- (id)initWithDatabase:(CSQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error;
- (id)initWithDatabase:(CSQLDatabase *)aDatabase error:(NSError **)error;
- (BOOL)setSQL:(NSString *)sql;
- (BOOL)setSQL:(NSString *)sql error:(NSError **)error;
- (BOOL)isActive;
- (BOOL)isActive:(NSError **)error;
- (BOOL)finish;
- (BOOL)finish:(NSError **)error;

- (BOOL)bindIntValue:(int)aValue forColumn:(int)column;
- (BOOL)bindDoubleValue:(double)aValue forColumn:(int)column;
- (BOOL)bindStringValue:(NSString *)aValue forColumn:(int)column;
- (BOOL)bindDataValue:(NSData *)aValue forColumn:(int)column;
- (BOOL)bindNullValueForColumn:(int)column;

@end
