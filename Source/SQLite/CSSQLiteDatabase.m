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
//  CSSQLiteDatabase.h by Igor Sutton on 3/25/10.
//

#import "CocoaSQL.h"
#import "CSSQLiteDatabase.h"
#include <sqlite3.h>


@implementation CSSQLiteDatabase

@synthesize path;

+ (CSQLDatabase *)databaseWithOptions:(NSDictionary *)options error:(NSError **)error
{
    CSSQLiteDatabase *database;
    database = [CSSQLiteDatabase databaseWithPath:[options objectForKey:@"path"] error:error];
    return database;
}

+ (id)databaseWithPath:(NSString *)aPath error:(NSError **)error
{
    CSSQLiteDatabase *database = [[CSSQLiteDatabase alloc] initWithPath:aPath error:error];
    return [database autorelease];
}

- (id)initWithPath:(NSString *)aPath error:(NSError **)error
{
    if (self = [super init]) {
        self.path = [aPath stringByExpandingTildeInPath];
        sqlite3 *databaseHandle_;
        int errorCode = sqlite3_open_v2([self.path UTF8String], &databaseHandle_, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, 0);
        if (errorCode != SQLITE_OK) {
            *error = [NSError errorWithMessage:[NSString stringWithFormat:@"%s", 
                                                sqlite3_errmsg(databaseHandle_)] 
                                       andCode:500];
            return nil;
        }
        databaseHandle = (voidPtr)databaseHandle_;
    }
    return self;
}

- (BOOL)disconnect:(NSError **)error
{
    int errorCode = sqlite3_close(databaseHandle);
    
    if (errorCode != SQLITE_OK) {
        if (error) {
            *error = [NSError errorWithMessage:[NSString stringWithFormat:@"%s", sqlite3_errmsg(databaseHandle)] andCode:500];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)isActive:(NSError **)error
{
    // Assume we are always connected for now.
    return YES;
}

- (void)dealloc
{
    [self disconnect];
    [path release];
    [super dealloc];
}

- (NSUInteger)executeSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error 
{
    CSQLPreparedStatement *statement = [self prepareStatement:sql error:error];
    
    if (!statement) {
        return 0;
    }
    
    return [statement executeWithValues:values error:error];
}

- (NSUInteger)executeSQL:(NSString *)sql error:(NSError **)error
{
    return [self executeSQL:sql withValues:nil error:error];
}

- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error
{
    CSQLPreparedStatement *statement = [self prepareStatement:sql error:error];
    
    if (!statement) {
        return nil;
    }
    
    [statement executeWithValues:values error:error];

    return [statement fetchRowAsArray:error];
}

- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql error:(NSError **)error
{
    return [self fetchRowAsArrayWithSQL:sql withValues:nil error:error];
}

- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error
{
    CSQLPreparedStatement *statement = [self prepareStatement:sql error:error];
    
    if (!statement) {
        return nil;
    }
    
    [statement executeWithValues:values error:error];
    
    return [statement fetchRowAsDictionary:error];
}

- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql error:(NSError **)error
{
    return [self fetchRowAsDictionaryWithSQL:sql withValues:nil error:error];
}

- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error
{
    CSQLPreparedStatement *statement = [self prepareStatement:sql error:error];
    
    if (!statement) {
        return nil;
    }
    
    NSDictionary *row;
    NSMutableArray *rows = [NSMutableArray array];
    if ([statement executeWithValues:values error:error]) {
        while (row = [statement fetchRowAsDictionary:error]) {
            [rows addObject:row];
        }
    }

    return rows;
}

- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql error:(NSError **)error
{
    return [self fetchRowsAsDictionariesWithSQL:sql withValues:nil error:error];
}

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error
{
    CSQLPreparedStatement *statement = [self prepareStatement:sql error:error];
    
    if (!statement) {
        return nil;
    }
    
    NSArray *row;
    NSMutableArray *rows = [NSMutableArray array];
    if ([statement executeWithValues:values error:error]) {
        while (row = [statement fetchRowAsArray:error]) {
            [rows addObject:row];
        }
    }

    return rows;
}

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql error:(NSError **)error
{
    return [self fetchRowsAsArraysWithSQL:sql withValues:nil error:error];
}

- (CSQLPreparedStatement *)prepareStatement:(NSString *)sql error:(NSError **)error
{
    return [CSSQLitePreparedStatement preparedStatementWithDatabase:self andSQL:sql error:error];
}

@end
