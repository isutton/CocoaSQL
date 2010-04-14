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
//  CSQLPostgreSQLDatabase.h by Igor Sutton on 4/13/10.
//

#import <Cocoa/Cocoa.h>

#import "CocoaSQL.h"

@interface CSPostgreSQLDatabase : CSQLDatabase {

}

- (id)initWithOptions:(NSDictionary *)options error:(NSError **)error;

@end
