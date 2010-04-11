//
//  CSMySQLPreparedStatement.h
//  CocoaSQL
//
//  Created by xant on 4/6/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CocoaSQL.h"

@interface CSMySQLPreparedStatement : CSQLPreparedStatement {
    voidPtr statement;
    id resultBinds;
}

@property (readwrite,assign) voidPtr statement;

- (int)affectedRows;

@end
