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
//  NSMutableArray+CocoaSQL.m by Igor Sutton on 3/31/10.
//

#import "NSMutableArray+CocoaSQL.h"

@implementation NSMutableArray (CocoaSQL)

- (void)bindDoubleValue:(double)aValue
{
    [self addObject:[NSNumber numberWithDouble:aValue]];
}

- (void)bindIntValue:(int)aValue
{
    [self addObject:[NSNumber numberWithInt:aValue]];
}

- (void)bindStringValue:(NSString *)aValue
{
    [self addObject:aValue];
}

- (void)bindDataValue:(NSData *)aValue
{
    [self addObject:aValue];
}

@end
