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
//  CSQLDatabase.h by Igor Sutton on 3/25/10.
//

#import "CSQLPreparedStatement.h"
#import "CSQLDatabase+Protocol.h"

@class CSQLDatabase;

@interface CSQLDatabase : NSObject <CSQLDatabase>
{
    voidPtr databaseHandle;
	NSNumber *affectedRows;
}

@property (readonly,assign) voidPtr databaseHandle;
@property (readonly,assign) NSNumber *affectedRows;

+ (CSQLDatabase *)databaseWithDSN:(NSString *)aDSN error:(NSError **)error;
+ (CSQLDatabase *)databaseWithDriver:(NSString *)aDriver options:(NSDictionary *)options error:(NSError **)error;

- (NSNumber *)lastInsertID;
- (BOOL)disconnect;
- (BOOL)disconnect:(NSError **)error;
- (BOOL)isActive;
- (BOOL)isActive:(NSError **)error;
@end