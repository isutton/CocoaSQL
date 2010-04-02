//
//  NSMutableArray+CocoaSQL.h
//  CocoaSQL
//
//  Created by Igor Sutton on 3/31/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSQLBindValue.h"

@interface NSMutableArray (CocoaSQL) 

- (void)bindDoubleValue:(double)aValue;
- (void)bindIntValue:(int)aValue;
- (void)bindStringValue:(NSString *)aValue;
- (void)bindDataValue:(NSData *)aValue;

@end
