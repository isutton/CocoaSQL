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
//  CSQLResultValue.m by xant on 4/13/10.
//

#import "CSQLResultValue.h"

// TODO - be more compliant to NSValue (implement missing methods, if necessary)

@implementation CSQLResultValue

#pragma mark -
#pragma Constructors

+ (id)valueWithObject:(id)aValue
{
    CSQLResultValue *result = [self alloc];
    return [[result initWithObject:aValue] autorelease];
}

+ (id)valueWithNumber:(NSNumber *)aValue
{
    CSQLResultValue *result = [self alloc];
    return [[result initWithNumber:aValue] autorelease];
}

+ (id)valueWithDecimalNumber:(NSDecimalNumber *)aValue
{
    CSQLResultValue *result = [self alloc];
    return [[result initWithDecimalNumber:aValue] autorelease];
}

+ (id)valueWithString:(NSString *)aValue
{
    CSQLResultValue *result = [self alloc];
    return [[result initWithString:aValue] autorelease];
}

+ (id)valueWithUTF8String:(char *)aValue
{
    CSQLResultValue *result = [self alloc];
    return [[result initWithUTF8String:aValue] autorelease];
}

+ (id)valueWithDate:(NSDate *)aValue
{
    CSQLResultValue *result = [self alloc];
    return [[result initWithDate:aValue] autorelease];
}

+ (id)valueWithData:(NSData *)aValue
{
    CSQLResultValue *result = [self alloc];
    return [[result initWithData:aValue] autorelease];
}

+ (id)valueWithBool:(BOOL)aValue
{
    CSQLResultValue *result = [self alloc];
    return [[result initWithBool:aValue] autorelease];
}

+ (id)valueWithNull
{
    CSQLResultValue *result = [self alloc];
    return [[result initWithNull] autorelease];
}

#pragma mark -
#pragma mark Initializers

- (id)init
{
    if (!value) // defaults to a null value
        value = [NSNull null];
    return [super init];
}

- (id)initWithObject:(id)aValue
{
    if ([[value class] isSubclassOfClass:[NSString class]])
        return [self initWithString:aValue];
    if ([[value class] isSubclassOfClass:[NSDecimalNumber class]])
        return [self initWithDecimalNumber:aValue];
    if ([[value class] isSubclassOfClass:[NSNumber class]])
        return [self initWithNumber:aValue];
    if ([[value class] isSubclassOfClass:[NSDate class]])
        return [self initWithDate:aValue];
    if ([[value class] isSubclassOfClass:[NSNull class]])
        return [self initWithNull];
    if ([[value class] isSubclassOfClass:[NSData class]])
        // returns the length of the string
        return [self initWithData:aValue];
    // TODO - output errors if here!!
    // will call super if no init has been defined in our class
    return [self init];
}

- (id)initWithNumber:(NSNumber *)aValue
{
    value = [aValue retain];
    // will call super if no init has been defined in our class
    return [self init];
}

- (id)initWithDecimalNumber:(NSDecimalNumber *)aValue
{
    value = [aValue retain];
    return [self init];
}

- (id)initWithString:(NSString *)aValue
{
    value = [aValue retain];
    return [self init];
}

- (id)initWithUTF8String:(char *)aValue
{
    value = [[NSString stringWithUTF8String:aValue] retain];
    return [self init];
}

- (id)initWithDate:(NSDate *)aValue
{
    value = [aValue retain];
    return [self init];
}

- (id)initWithData:(NSData *)aValue
{
    value = [aValue retain];
    return [self init];
}

- (id)initWithBool:(BOOL)aValue
{
    value = [NSNumber numberWithBool:aValue];
    return [self init];
}

- (id)initWithNull
{
    value = [NSNull null];
    return [self init];
}


#pragma mark -
#pragma Value Accessors

- (NSNumber *)numberValue
{
    if ([[value class] isSubclassOfClass:[NSNumber class]])
        return value;
    if ([[value class] isSubclassOfClass:[NSString class]]) {
        long long aNumber = strtol([value UTF8String], NULL, 0);
        return [NSNumber numberWithLongLong:aNumber];
    }
    if ([[value class] isSubclassOfClass:[NSDate class]]) {
        return [NSNumber numberWithDouble:[value timeIntervalSince1970]];
    }
    if ([[value class] isSubclassOfClass:[NSNull class]]) {
        return [NSNumber numberWithInt:0];
    }
    if ([[value class] isSubclassOfClass:[NSNull class]]) {
        // returns the length of the string
        return [NSNumber numberWithUnsignedInteger:[value length]];
    }
    return nil;
}

- (NSDecimalNumber *)decimalNumberValue
{
    if ([[value class] isSubclassOfClass:[NSDecimalNumber class]])
        return value;
    if ([[value class] isSubclassOfClass:[NSNumber class]])
        return [NSDecimalNumber decimalNumberWithDecimal:[(NSNumber *)value decimalValue]];
    
    if ([[value class] isSubclassOfClass:[NSString class]]) {
        // returns the number represented by the string
        return [NSDecimalNumber decimalNumberWithString:value]; // XXX - test
    }
    if ([[value class] isSubclassOfClass:[NSDate class]]) {
        // XXX - ugly and definitely unconvenient (but at least returns a valid value)
        //       we must find a better way to do this conversion
        [NSDecimalNumber decimalNumberWithDecimal:
            [[NSNumber numberWithDouble:[value timeIntervalSince1970]] decimalValue]];
    }
    if ([[value class] isSubclassOfClass:[NSNull class]]) {
        return [NSDecimalNumber decimalNumberWithString:@"0.0"];
    }
    if ([[value class] isSubclassOfClass:[NSData class]]) {
        // returns the length of the data
        return (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:[value length]];
    }
    return nil;
}

- (NSString *)stringValue
{
    if ([[value class] isSubclassOfClass:[NSString class]])
        return value;
    if ([[value class] isSubclassOfClass:[NSDecimalNumber class]])
        return [value stringValue];
    if ([[value class] isSubclassOfClass:[NSNumber class]])
        return [value stringValue];
    if ([[value class] isSubclassOfClass:[NSDate class]])
        return [value description];
    if ([[value class] isSubclassOfClass:[NSNull class]]) {
        return [NSString stringWithString:@""];
    }
    if ([[value class] isSubclassOfClass:[NSData class]]) {
        // returns the length of the string
        return [NSString stringWithUTF8String:[value bytes]];
    }
    return nil;
}

- (NSDate *)dateValue
{
    if ([[value class] isSubclassOfClass:[NSDate class]])
        return value;
    if ([[value class] isSubclassOfClass:[NSString class]])
        return [NSDate dateWithString:value];
    if ([[value class] isSubclassOfClass:[NSNumber class]])
    {
        return [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
    }
    if ([[value class] isSubclassOfClass:[NSNull class]]) {
        // XXX - is this date 0 ? .. perhaps I should create the date from an epoch == 0?
        return [NSDate alloc];
    }
    if ([[value class] isSubclassOfClass:[NSString class]]) {
        // if the data contains a date string ... a correct NSDate will be returned
        // XXX - what would happen if that's not the case ?  (tests needed)
        return [NSDate dateWithString:[NSString stringWithUTF8String:[value bytes]]];
    }
    return nil;
}

- (NSData *)dataValue
{
    if ([[value class] isSubclassOfClass:[NSData class]])
        return value;
    if ([[value class] isSubclassOfClass:[NSString class]]) {
		// TODO - find a way to avoid copying the buffer (refcnt++ ?)
        return [NSData dataWithBytes:(void *)[value UTF8String] length:[value length]];
	}
    if ([[value class] isSubclassOfClass:[NSNull class]])
        return [NSData alloc]; // empty data
    if ([[value class] isSubclassOfClass:[NSNumber class]]) {
        const char *objCType = [value objCType];
        int length = 0;
        // we care only about the first character, which is enough to tell us the size
        switch (*objCType) {
            case 'c':
                length = 1;
                break;
            case 'h':
            case 'C':
                length = 2;
                break;
            case 'd':
            case 'D':
            case 'i':
            case 'o':
            case 'O':
                length = 4;
                break;
            case 'q':
            case 'f':
            case 'F':
            case 'e':
            case 'E':
            case 'g':
            case 'G':
            case 'a':
            case 'A':
                length = 8;
                break;
            // but when length-modifiers have been used ...
            // we need to look at following characters as well
            case 'l':
                if (*(objCType+1) == 'l')
                    length = sizeof(long long);
                else
                    length = sizeof(long);
                break;
            case 'L':
                switch (*(objCType+1)) {
                    case 'a':
                    case 'A':
                    case 'e':
                    case 'E':
                    case 'f':
                    case 'F':
                    case 'g':
                    case 'G':
                        length = sizeof(long double);
                        break;
                    default:
                        // TODO - Error Message
                        break;
                }
                break;
        }
        return [NSData dataWithBytesNoCopy:[value pointerValue] length:length];
    }
    return nil;
}

- (BOOL)isNull
{
    if ([[value class] isSubclassOfClass:[NSNull class]])
        return YES;
    return NO;
}

- (BOOL)boolValue
{
    if ([[value class] isSubclassOfClass:[NSNumber class]] && strcmp([value objCType], "c") == 0) 
        return YES;
    if (value)
        return YES;
    return NO;
}


- (BOOL)isEqual:(id)anObject
{
    if ([[self class] isEqual:[anObject class]])
        return ([value isEqual:[anObject value]]);
    return NO;
}

- (BOOL)isEqualToValue:(NSValue *)aValue
{
    return ([value isEqualToValue:[aValue value]]);
}

- (NSString *)description
{
    return [value description];
}

// return the objCType of the value we hold
- (const char *)objCType
{
    const char *val = "";
    if ([[value class] isSubclassOfClass:[NSValue class]])
        val = [value objCType];
    else if ([[value class] isSubclassOfClass:[NSString class]] ||
             [[value class] isSubclassOfClass:[NSData class]])
        val = "%s";
    return val;
}

- (void)getValue:(void *)buffer
{
    return [value getValue:buffer];
}

- (NSString *)type
{
    return [value className];
}

- (id)value
{
    return value;
}

@end
