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

@class CSSQLiteDatabase;

@interface CSSQLitePreparedStatement : CSQLPreparedStatement  {
    voidPtr statement;
}

@property (readwrite,assign) voidPtr statement;

- (CSQLPreparedStatement *)initWithDatabase:(CSQLDatabase *)database andSQL:(NSString *)sql error:(NSError **)error;

- (BOOL)finish:(NSError **)error;
- (BOOL)isActive:(NSError **)error;

- (BOOL)bindValue:(id)aValue toColumn:(int)index;
- (BOOL)bindIntegerValue:(NSNumber *)aValue toColumn:(int)index;
- (BOOL)bindDecimalValue:(NSDecimalNumber *)aValue toColumn:(int)index;
- (BOOL)bindStringValue:(NSString *)aValue toColumn:(int)index;
- (BOOL)bindDataValue:(NSData *)aValue toColumn:(int)index;
- (BOOL)bindNullValueToColumn:(int)index;

@end
