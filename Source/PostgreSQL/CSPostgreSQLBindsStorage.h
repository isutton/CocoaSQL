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
//  CSPostgreSQLBindsStorage.h by Igor Sutton on 4/26/10.
//

#import <Foundation/Foundation.h>
#import "CSPostgreSQLPreparedStatement.h"

#include "PostgreSQLDataType.h"
#include <libpq-fe.h>

@interface CSPostgreSQLBindsStorage : NSObject
{
    int numParams;
    int *paramTypes;
    int *paramLengths;
    int *paramFormats;
    char **paramValues;
    int resultFormat;
    
    CSPostgreSQLPreparedStatement *statement;
    
    PGresult *result;
}

@property (readonly, assign) int numParams;
@property (readonly, assign) int *paramTypes;
@property (readonly, assign) int *paramLengths;
@property (readonly, assign) int *paramFormats;
@property (readonly, assign) char **paramValues;
@property (readonly, assign) int resultFormat;

- (id)initWithStatement:(CSPostgreSQLPreparedStatement *)aStatement andValues:(NSArray *)values;
- (BOOL)bindValue:(id)aValue toColumn:(int)index;
- (BOOL)setValues:(NSArray *)values;

@end
