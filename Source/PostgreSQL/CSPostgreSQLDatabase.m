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
//  CSQLPostgreSQLDatabase.m by Igor Sutton on 4/13/10.
//

#import "CSPostgreSQLDatabase.h"
#import "CSPostgreSQLPreparedStatement.h"
#include <libpq-fe.h>

@implementation CSPostgreSQLDatabase

+ (CSQLDatabase *)databaseWithOptions:(NSDictionary *)options error:(NSError **)error
{
    CSQLDatabase *database = [[self alloc] initWithOptions:options error:error];
    if (database)
        return [database autorelease];
    return nil;
}

- (id)initWithOptions:(NSDictionary *)options error:(NSError **)error
{
    PGconn *databaseHandle_ = nil;
    
    if (self = [super init]) {
        
        NSMutableString *connectionOptions = [NSMutableString string];
        
        for (NSString *key in options) {
            [connectionOptions appendFormat:@"%@=%@ ", key, [options valueForKey:key]];
        }

        [connectionOptions replaceOccurrencesOfString:@"\"" 
                                           withString:@"\\\""
                                              options:NSLiteralSearch 
                                                range:NSMakeRange(0, [connectionOptions length])];

        [connectionOptions replaceOccurrencesOfString:@"\\" 
                                           withString:@"\\\\"
                                              options:NSLiteralSearch 
                                                range:NSMakeRange(0, [connectionOptions length])];
        
        databaseHandle_ = PQconnectdb([connectionOptions UTF8String]);
        
        if (databaseHandle_) {
            databaseHandle = databaseHandle_;
        }
        
        return self;
    }
    return nil;
}

- (BOOL)disconnect:(NSError **)error
{
    if (databaseHandle) {
        PQfinish(databaseHandle);
        databaseHandle = nil;
    }
    return YES;
}

- (BOOL)isActive:(NSError **)error
{
    return PQstatus(databaseHandle) == CONNECTION_OK;
}

- (void)dealloc
{
    [self disconnect];
    [super dealloc];
}

- (CSQLPreparedStatement *)prepareStatement:(NSString *)sql error:(NSError **)error
{
    return [CSPostgreSQLPreparedStatement preparedStatementWithDatabase:self andSQL:sql error:error];
}

- (BOOL)executeSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error
{
    CSQLPreparedStatement *statement = [self prepareStatement:sql error:error];
    
    if (!statement) {
        return NO;
    }
    
    return [statement executeWithValues:values error:error];
}

- (NSString *)dateStyle
{
    return @"MMddyyyy";
}

- (NSString *)timeStyle
{
    return @"HH:MM:SS";
}

- (NSString *)timestampStyle
{
    return @"MM-dd-yyyy HH:mm:ssZZZ";
}

@end
