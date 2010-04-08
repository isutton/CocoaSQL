//
//  CSMySQLPreparedStatement.h
//  CocoaSQL
//
//  Created by xant on 4/6/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSQLPreparedStatement.h"
#include <mysql.h>


@interface CSMySQLPreparedStatement : CSQLPreparedStatement {
    MYSQL_STMT *statement;
}

- (int)affectedRows;
- (BOOL)setSql:(NSString *)sql error:(NSError **)error;

@end
