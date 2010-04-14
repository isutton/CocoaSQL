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
//  CSSQLitePreparedStatement.h by Igor Sutton on 3/26/10.
//

#import <Cocoa/Cocoa.h>

#import "CocoaSQL.h"
#import "CSSQLiteDatabase.h"
#import "CSQLDatabase.h"
#import "CSQLPreparedStatement.h"

@class CSSQLiteDatabase;

@interface CSSQLitePreparedStatement : CSQLPreparedStatement  {

}

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
