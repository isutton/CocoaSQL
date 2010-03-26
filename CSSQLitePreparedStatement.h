//
//  CSSQLitePreparedStatement.h
//  CocoaSQL
//
//  Created by Igor Sutton on 3/26/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CSQLDatabase.h"
#import "CSQLPreparedStatement.h"

#include <sqlite3.h>

@interface CSSQLitePreparedStatement : NSObject <CSQLPreparedStatement>  {
    sqlite3_stmt *sqlitePreparedStatement;
}

/**
 
 @param database
 @param sql
 
 @return <code>preparedStatement</code>
 
 */
+ (id <CSQLPreparedStatement>)preparedStatementWithDatabase:(id <CSQLDatabase> *)database
                                                     andSQL:(NSString *)sql;

/**
 
 @param database
 @param sql
 
 @return <code>preparedStatement</code>
 
 */
- (id <CSQLPreparedStatement>)initWithDatabase:(id <CSQLDatabase> *)database
                                        andSQL:(NSString *)sql;

@end
