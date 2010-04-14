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
//  CSQLPreparedStatement.h by Igor Sutton on 3/26/10.
//

#import "CSQLPreparedStatement+Protocol.h"

@class CSQLDatabase;

@interface CSQLPreparedStatement : NSObject <CSQLPreparedStatement>
{
    CSQLDatabase *database;
    voidPtr statement;
    BOOL canFetch;
}

@property (retain) CSQLDatabase *database;
@property (readonly) BOOL canFetch;
@property (readwrite,assign) voidPtr statement;

/**
 
 @param database
 @param sql
 
 @return <code>preparedStatement</code>
 
 */
+ (id)preparedStatementWithDatabase:(CSQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error;

/**
 
 @param aDatabase
 @param sql
 @param error
 
 @return 
 
 */
- (id)initWithDatabase:(CSQLDatabase *)aDatabase;
- (id)initWithDatabase:(CSQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error;
- (id)initWithDatabase:(CSQLDatabase *)aDatabase error:(NSError **)error;

- (BOOL)setSQL:(NSString *)sql;
- (BOOL)setSQL:(NSString *)sql error:(NSError **)error;

- (BOOL)isActive;
- (BOOL)isActive:(NSError **)error;

- (BOOL)finish;
- (BOOL)finish:(NSError **)error;

- (BOOL)bindValue:(id)aValue toColumn:(int)column;
- (BOOL)bindIntegerValue:(NSNumber *)aValue toColumn:(int)column;
- (BOOL)bindDecimalValue:(NSDecimalNumber *)aValue toColumn:(int)column;
- (BOOL)bindStringValue:(NSString *)aValue toColumn:(int)column;
- (BOOL)bindDataValue:(NSData *)aValue toColumn:(int)column;
- (BOOL)bindNullValueToColumn:(int)column;

- (voidPtr)statement;

@end
