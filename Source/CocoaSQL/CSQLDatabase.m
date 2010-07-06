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
//  CSQLDatabase.m by Igor Sutton on 3/25/10.
//

#import "CocoaSQL.h"

@implementation CSQLDatabase

@synthesize databaseHandle;
@synthesize affectedRows;

+ (CSQLDatabase *)databaseWithOptions:(NSDictionary *)options error:(NSError **)error
{
	// MUST be overridden by subclasses
    if (error)
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
	return nil;
}

+ (CSQLDatabase *)databaseWithDriver:(NSString *)aDriver options:(NSDictionary *)options error:(NSError **)error
{
    NSString *aClassName = [NSString stringWithFormat:@"CS%@Database", aDriver];
    Class class = NSClassFromString(aClassName);
    
    if (!class) {
        if (error)
            *error = [NSError errorWithMessage:[NSString stringWithFormat:@"Couldn't find class %@.", aClassName] andCode:500];
        return nil;
    }
    
    CSQLDatabase *database = [class databaseWithOptions:options error:error];
    return database;
}

+ (CSQLDatabase *)databaseWithDSN:(NSString *)aDSN error:(NSError **)error
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    NSScanner *scanner = [NSScanner scannerWithString:aDSN];
    
    NSString *aDriver;    
    [scanner scanUpToString:@":" intoString:&aDriver];
    [scanner setScanLocation:[scanner scanLocation] + 1];
    
    NSString *aKey;
    NSString *aValue;
    while (![scanner isAtEnd]) {
        [scanner scanUpToString:@"=" intoString:&aKey];
        [scanner setScanLocation:[scanner scanLocation] + 1];
        [scanner scanUpToString:@";" intoString:&aValue];

        if (![scanner isAtEnd]) {
            [scanner setScanLocation:[scanner scanLocation] + 1];            
        }
        
        [options setObject:aValue forKey:aKey];
    }
    
    return [self databaseWithDriver:aDriver options:options error:error];
}

- (void)dealloc
{
	if (affectedRows)
		[affectedRows release];
	[super dealloc];
}

- (BOOL)isActive:(NSError **)error
{
    // MUST be overridden by subclasses
    if (error)
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
    return NO;
}

- (BOOL)isActive
{
    return [self isActive:nil];
}

- (BOOL)disconnect:(NSError **)error
{
    // MUST be overridden by subclasses
    if (error)
        *error = [NSError errorWithMessage:@"Driver needs to implement this message." andCode:500];
    return NO;
}

- (BOOL)disconnect
{
    return [self disconnect:nil];
}

- (NSNumber *)lastInsertID
{
    // MUST be overridden by subclasses
    return [NSNumber numberWithInt:0];
}

- (BOOL)executeSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error
{
    CSQLPreparedStatement *preparedStatement = [self prepareStatement:sql error:error];
    
    if (!preparedStatement) {
        return NO;
    }
    
    return [preparedStatement executeWithValues:values error:error];
}

- (BOOL)executeSQL:(NSString *)sql error:(NSError **)error
{
    return [self executeSQL:sql withValues:nil error:error];
}

- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql andValues:(NSArray *)values error:(NSError **)error
{
    CSQLPreparedStatement *preparedStatement = [self prepareStatement:sql error:error];
    
    if (!preparedStatement)
        return nil;
    
    [preparedStatement executeWithValues:values error:error];
    
    return [preparedStatement fetchRowAsDictionary:error];
}

- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql error:(NSError **)error
{
    return [self fetchRowAsDictionaryWithSQL:sql andValues:nil error:error];
}

- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql andValues:(NSArray *)values error:(NSError **)error
{
    CSQLPreparedStatement *preparedStatement = [self prepareStatement:sql error:error];
    
    if (!preparedStatement)
        return nil;
    
    [preparedStatement executeWithValues:values error:error];
    
    return [preparedStatement fetchRowAsArray:error];
}

- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql error:(NSError **)error
{
    return [self fetchRowAsArrayWithSQL:sql andValues:nil error:error];
}

- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql andValues:(NSArray *)values error:(NSError **)error
{
    CSQLPreparedStatement *preparedStatement = [self prepareStatement:sql error:error];
    
    if (!preparedStatement)
        return nil;
    
    NSDictionary *row;
    NSMutableArray *rows = [NSMutableArray array];
    
    if ([preparedStatement executeWithValues:values error:error]) {
        while (row = [preparedStatement fetchRowAsDictionary:error]) {
            [rows addObject:row];
        }                      
    }
    
    return rows;
}

- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql error:(NSError **)error
{
	return [self fetchRowsAsDictionariesWithSQL:sql andValues:nil error:error];
}


- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql andValues:(NSArray *)values error:(NSError **)error
{
    CSQLPreparedStatement *preparedStatement = [self prepareStatement:sql error:error];
    
    if (!preparedStatement)
        return nil;
    
    NSArray *row;
    NSMutableArray *rows = [NSMutableArray array];
    
    if ([preparedStatement executeWithValues:values error:error]) {
        while (row = [preparedStatement fetchRowAsArray:error]) {
            [rows addObject:row];
        }
    }
	
    return rows;
}

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql error:(NSError **)error
{
	return [self fetchRowsAsArraysWithSQL:sql andValues:nil error:error];
}

- (CSQLPreparedStatement *)prepareStatement:(NSString *)sql error:(NSError **)error
{
    return [CSQLPreparedStatement preparedStatementWithDatabase:self andSQL:sql error:error];
}

+ (Class)preparedStatementClass
{
    return nil;
}

@end

