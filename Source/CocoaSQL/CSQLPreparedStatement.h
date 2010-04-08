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
- (BOOL)setSql:(NSString *)sql;
- (BOOL)setSql:(NSString *)sql error:(NSError **)error;

@property (retain) CSQLDatabase *database;
@property (assign) BOOL canFetch;

@end
