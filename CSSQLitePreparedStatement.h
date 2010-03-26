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
+ (id)preparedStatementWithDatabase:(id)database
                             andSQL:(NSString *)sql
                              error:(NSError **)error;

/**
 
 @param database
 @param sql
 
 @return <code>preparedStatement</code>
 
 */
- (id)initWithDatabase:(id)database
                andSQL:(NSString *)sql
                 error:(NSError **)error;


@end
