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
}

@property (readwrite,assign) voidPtr databaseHandle;

+ (CSQLDatabase *)databaseWithDSN:(NSString *)aDSN error:(NSError **)error;
+ (CSQLDatabase *)databaseWithDriver:(NSString *)aDriver options:(NSDictionary *)options error:(NSError **)error;

- (NSNumber *)affectedRows;
- (NSNumber *)lastInsertID;
- (BOOL)disconnect;
- (BOOL)disconnect:(NSError **)error;
- (BOOL)isActive;
- (BOOL)isActive:(NSError **)error;
@end

#pragma mark -
#pragma mark callbacks


typedef int (*CSQLCallback)(void *, int, char**, char**);

int rowAsArrayCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames);

int rowAsDictionaryCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames);

int rowsAsDictionariesCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames);

int rowsAsArraysCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames);
