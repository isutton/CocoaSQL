//
//
//  This file is part of CocoaSQL
//
//  CocoaSQL is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  CocoaSQL is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with CocoaSQL.  If not, see <http://www.gnu.org/licenses/>.
//
//  CSMySQLDatabase.h by xant on 4/2/10.
//

#import <Cocoa/Cocoa.h>
#import "CocoaSQL.h"


@interface CSMySQLDatabase : CSQLDatabase {
}

@property (readwrite,assign) voidPtr databaseHandle;
@property (readonly) NSNumber *affectedRows;

#pragma mark -
#pragma mark Initialization related messages

+ (id)databaseWithOptions:(NSDictionary *)options 
                    error:(NSError **)error;

+ (id)databaseWithName:(NSString *)databaseName
                  host:(NSString *)host
                  user:(NSString *)user
              password:(NSString *)password
                 error:(NSError **)error;

- (id)initWithName:(NSString *)databaseName
              host:(NSString *)host
              user:(NSString *)user
          password:(NSString *)password
             error:(NSError **)error;

@end
