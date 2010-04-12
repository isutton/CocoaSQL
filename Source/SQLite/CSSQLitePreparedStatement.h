//
//  CSSQLitePreparedStatement.h
//  CocoaSQL
//
//  Created by Igor Sutton on 3/26/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CocoaSQL.h"
#import "CSSQLiteDatabase.h"
#import "CSQLDatabase.h"
#import "CSQLPreparedStatement.h"
#import "CSQLBindValue.h"

@class CSSQLiteDatabase;

@interface CSSQLitePreparedStatement : CSQLPreparedStatement  {
    voidPtr statement;
}

@property (readwrite,assign) voidPtr statement;

- (CSQLPreparedStatement *)initWithDatabase:(CSQLDatabase *)database andSQL:(NSString *)sql error:(NSError **)error;

- (BOOL)bindValue:(id)aValue forColumn:(int)column;
- (BOOL)bindIntegerValue:(NSNumber *)aValue forColumn:(int)column;
- (BOOL)bindDecimalValue:(NSDecimalNumber *)aValue forColumn:(int)column;
- (BOOL)bindStringValue:(NSString *)aValue forColumn:(int)column;
- (BOOL)bindDataValue:(NSData *)aValue forColumn:(int)column;
- (BOOL)bindNullValueForColumn:(int)column;

@end
