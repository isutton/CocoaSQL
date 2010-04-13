//
//  CSSQLite.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/25/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
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
