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
//  CSQLPreparedStatement.m by Igor Sutton on 3/26/10.
//

#import "CocoaSQL.h"

@implementation CSQLPreparedStatement

@synthesize canFetch;
@synthesize database;
@synthesize statement;

+ (id)preparedStatementWithDatabase:(id)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    id preparedStatement;
    preparedStatement = [[[[aDatabase class] preparedStatementClass] alloc] initWithDatabase:aDatabase andSQL:sql error:error];
    if (preparedStatement) {
        return [preparedStatement autorelease];
    }
    return nil;
}

- (id)initWithDatabase:(CSQLDatabase *)aDatabase
{
    return [self initWithDatabase:aDatabase error:nil];
}

- (id)initWithDatabase:(CSQLDatabase *)aDatabase error:(NSError **)error
{
    if (error) {
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
    }
    return self;
}

- (id)initWithDatabase:(CSQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
	[self initWithDatabase:aDatabase error:error];
	[self setSQL:sql error:error];
	return self;
}

- (BOOL)setSQL:(NSString *)sql error:(NSError **)error
{
    if (error) {
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
    }
    return NO;
}

- (BOOL)setSQL:(NSString *)sql
{
    return [self setSQL:sql error:nil];
}

- (BOOL)isActive:(NSError **)error
{
    // MUST be overridden by subclasses
    if (error) {
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
    }
    return NO;
}

- (BOOL)isActive
{
    return [self isActive:nil];
}

- (BOOL)finish:(NSError **)error
{
    // MUST be overridden by subclasses
    if (error) {
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
    }
    return NO;
}

- (BOOL)finish
{
    return [self finish:nil];
}

- (BOOL)bindIntegerValue:(NSNumber *)aValue toColumn:(int)column
{
    // MUST be overridden by subclasses
    NSLog(@"bindIntegerValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL)bindDecimalValue:(NSDecimalNumber *)aValue toColumn:(int)column
{
    // MUST be overridden by subclasses
    NSLog(@"bindDecimalValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL)bindStringValue:(NSString *)aValue toColumn:(int)column
{
    // MUST be overridden by subclasses
    NSLog(@"bindStringValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL)bindDataValue:(NSData *)aValue toColumn:(int)column
{
    // MUST be overridden by subclasses
    NSLog(@"bindDataValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL)bindNullValueToColumn:(int)column
{
    // MUST be overridden by subclasses
    NSLog(@"bindNullValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL)bindValue:(id)aValue toColumn:(int)column;
{
    // MUST be overridden by subclasses
    NSLog(@"bindValue not implemented by %@\n", [self className]);
    return NO;
}

- (BOOL) execute:(NSError **)error
{
    return [self executeWithValues:nil error:error];
}

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
	// subclass MUST implement this method
	return NO;
}

- (BOOL)executeWithValues:(NSArray *)values receiver:(id)receiver selector:(SEL)selector error:(NSError **)error
{
	return [self executeWithValues:values receiver:receiver selector:selector rowAsDictionary:YES error:error];
}


- (BOOL)executeWithValues:(NSArray *)values receiver:(id)receiver selector:(SEL)selector
{
	return [self executeWithValues:values receiver:receiver selector:selector rowAsDictionary:YES error:nil];
}

- (BOOL)executeWithReceiver:(id)receiver selector:(SEL)selector error:(NSError **)error
{
	return [self executeWithValues:nil receiver:receiver selector:selector error:error];
}

- (BOOL)executeWithReceiver:(id)receiver selector:(SEL)selector
{
	return [self executeWithValues:nil receiver:receiver selector:selector];
}


- (BOOL)executeWithValues:(NSArray *)values
				 receiver:(id)receiver
				 selector:(SEL)selector
		  rowAsDictionary:(BOOL)wantsDictionary
					error:(NSError **)error
{
	if ([self executeWithValues:values error:nil]) {
		if (receiver && selector) {
			SEL fetchSelector;
			if (wantsDictionary)
				fetchSelector = @selector(fetchRowAsDictionary:);
			else
				fetchSelector = @selector(fetchRowAsArray:);
			
			NSDictionary *row;
			while ((row = [self performSelector:fetchSelector withObject:nil])) {
				[receiver performSelector:selector withObject:row];
			}
		}
		return YES;
	}
	return NO;
}

- (BOOL)executeWithValues:(NSArray *)values
				 receiver:(id)receiver
				 selector:(SEL)selector
		  rowAsDictionary:(BOOL)wantsDictionary
{
	return [self executeWithValues:values receiver:receiver selector:selector rowAsDictionary:wantsDictionary error:nil];
}

- (void)dealloc
{
    [super dealloc];
}

@end
