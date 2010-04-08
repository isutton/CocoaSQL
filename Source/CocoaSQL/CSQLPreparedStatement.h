/*
 *  CSQLPreparedStatement.h
 *  CocoaSQL
 *
 *  Created by Igor Sutton on 3/26/10.
 *  Copyright 2010 CocoaSQL.org. All rights reserved.
 *
 */

@class CSQLDatabase;

@protocol CSQLPreparedStatement

#pragma mark -
#pragma mark Execute messages

@optional

/**
 
 Executes the prepared statement with <code>values</code> as bind values. 
 Returns a <code>BOOL</code> value indicating if the operation was successful.
 If any error occurred, populates the <code>NSError</code> instance.
 
 @param values
 @param error
 
 @return 
 
 */
- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error;

/**
 
 Executes the prepared statement. Returns a <code>BOOL</code> value indicating
 if the operation was successful. If any error occurred, populates the 
 <code>NSError</code> instance.
 
 @param error
 
 @return 
 
 */
- (BOOL)execute:(NSError **)error;

#pragma mark -
#pragma mark Fetch messages

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

#pragma mark -
#pragma mark Bind messages

/**
 
 @param aValue
 @param column
 
 @return <code>YES</code> if the value could be properly binded, otherwise
 <code>NO</code>.
 
 */
- (BOOL)bindIntValue:(int)aValue forColumn:(int)column;

/**
 
 @param aValue
 @param column

 @return <code>YES</code> if the value could be properly binded, otherwise
 <code>NO</code>.

 */
- (BOOL)bindDoubleValue:(double)aValue forColumn:(int)column;

/**
 
 @param aValue
 @param column

 @return <code>YES</code> if the value could be properly binded, otherwise
 <code>NO</code>.

 */
- (BOOL)bindStringValue:(NSString *)aValue forColumn:(int)column;

/**
 
 @param aValue
 @param column

 @return <code>YES</code> if the value could be properly binded, otherwise
 <code>NO</code>.

 */
- (BOOL)bindDataValue:(NSData *)aValue forColumn:(int)column;

/**
 
 @param column

 @return <code>YES</code> if the value could be properly binded, otherwise
 <code>NO</code>.

 */
- (BOOL)bindNullValueForColumn:(int)column;

@end

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
- (id)initWithDatabase:(CSQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error;

@property (retain) CSQLDatabase *database;
@property (assign) BOOL canFetch;

@end
