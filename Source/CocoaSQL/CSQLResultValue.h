//
//
//  This file is part of CocoaSQL
//
//  CocoaSQL is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with CocoaSQL.  If not, see <http://www.gnu.org/licenses/>.
//
//  CSQLResultValue.h by xant on 4/13/10.
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
