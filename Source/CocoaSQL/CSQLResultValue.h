//
//  CSQLResultValue.h
//  CocoaSQL
//
//  Created by xant on 4/13/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CSQLResultValue : NSValue {
    id value;
}

+ (id)valueWithObject:(id)aValue;
+ (id)valueWithNumber:(NSNumber *)aValue;
+ (id)valueWithDecimalNumber:(NSDecimalNumber *)aValue;
+ (id)valueWithString:(NSString *)aValue;
+ (id)valueWithDate:(NSDate *)aValue;
+ (id)valueWithData:(NSData *)aValue;
+ (id)valueWithBool:(BOOL)aValue;
+ (id)valueWithNull;

- (id)initWithObject:(id)aValue;
- (id)initWithNumber:(NSNumber *)aValue;
- (id)initWithDecimalNumber:(NSDecimalNumber *)aValue;
- (id)initWithString:(NSString *)aValue;
- (id)initWithDate:(NSDate *)aValue;
- (id)initWithData:(NSData *)aValue;
- (id)initWithBool:(BOOL)aValue;
- (id)initWithNull;


- (NSNumber *)numberValue;
- (NSDecimalNumber *)decimalNumberValue;
- (NSString *)stringValue;
- (NSDate *)dateValue;
- (NSData *)dataValue;
- (BOOL)boolValue;
- (BOOL)isNull;
- (id)value;
- (NSString *)type;

@end
