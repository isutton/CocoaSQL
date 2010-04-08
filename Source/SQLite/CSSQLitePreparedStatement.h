//
//  CSSQLitePreparedStatement.h
//  CocoaSQL
//
//  Created by Igor Sutton on 3/26/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CSSQLiteDatabase.h"
#import "CSQLDatabase.h"
#import "CSQLPreparedStatement.h"
#import "CSQLBindValue.h"

#include <sqlite3.h>

@class CSSQLiteDatabase;

@interface CSSQLitePreparedStatement : CSQLPreparedStatement  {
    sqlite3_stmt *sqlitePreparedStatement;
}

@property (assign) sqlite3_stmt *sqlitePreparedStatement;

/**
 
 @param database
 @param sql
 
 @return <code>preparedStatement</code>
 
 */
- (CSQLPreparedStatement *)initWithDatabase:(CSQLDatabase *)database andSQL:(NSString *)sql error:(NSError **)error;

@end

/**
 
 @param preparedStatement
 @param column
 
 @return <code>id</code>
 
 */
id translate(sqlite3_stmt *preparedStatement, int column);
