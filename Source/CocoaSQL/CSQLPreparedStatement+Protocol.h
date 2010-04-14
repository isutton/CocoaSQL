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
//  CSQLPreparedStatement+Protocol.h by Igor Sutton on 4/8/10.
//

@protocol CSQLPreparedStatement

- (BOOL)isActive;

- (BOOL)finish;

#pragma mark -
#pragma mark Execute messages

@optional

/**
 
 Executes the prepared statement with <code>values</code> as bind values. 
 Returns a <code>BOOL</code> value indicating if the operation was successful.
 If any error occurred, populates the <code>NSError</code> instance.
 
 @param values
 @param error
 
 @return 
 
 */
- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error;

/**
 
 Executes the prepared statement. Returns a <code>BOOL</code> value indicating
 if the operation was successful. If any error occurred, populates the 
 <code>NSError</code> instance.
 
 @param error
 
 @return 
 
 */
- (BOOL)execute:(NSError **)error;

#pragma mark -
#pragma mark Fetch messages

/**
 
 If the executed prepared statement returns data, fetches the next pending row
 as an <code>NSDictionary</code> instance. If any error occurred, populates the
 <code>NSError</code> instance.
 
 @param error
 
 @return <code>row</code> An <code>NSDictionary</code> instance containing the
 row contents, with the column names as keys.
 
 */

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error;

/**
 
 If the executed prepared statement returns data, fetches the next pending row
 as an <code>NSArray</code> instance. Returns <code>nil</code> if there's no
 more rows to be fetched, or if any error occurred. In case of an error, also
 populates the <code>NSError</code> instance.
 
 @param error
 
 @return <code>row</code> An <code>NSArray</code> instance containing the row
 contents.
 
 */
- (NSArray *)fetchRowAsArray:(NSError **)error;

#pragma mark -
#pragma mark Bind messages

/**
 
 @param aValue
 @param column
 
 @return <code>YES</code> if the value could be properly binded, otherwise
 <code>NO</code>.
 
 */
- (BOOL)bindIntValue:(int)aValue forColumn:(int)column;

/**
 
 @param aValue
 @param column
 
 @return <code>YES</code> if the value could be properly binded, otherwise
 <code>NO</code>.
 
 */
- (BOOL)bindDoubleValue:(double)aValue forColumn:(int)column;

/**
 
 @param aValue
 @param column
 
 @return <code>YES</code> if the value could be properly binded, otherwise
 <code>NO</code>.
 
 */
- (BOOL)bindStringValue:(NSString *)aValue forColumn:(int)column;

/**
 
 @param aValue
 @param column
 
 @return <code>YES</code> if the value could be properly binded, otherwise
 <code>NO</code>.
 
 */
- (BOOL)bindDataValue:(NSData *)aValue forColumn:(int)column;

/**
 
 @param column
 
 @return <code>YES</code> if the value could be properly binded, otherwise
 <code>NO</code>.
 
 */
- (BOOL)bindNullValueForColumn:(int)column;

- (BOOL)isActive:(NSError **)error;

- (BOOL)finish:(NSError **)error;

@end
