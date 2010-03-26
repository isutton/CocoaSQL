//
//  CSSQLite.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/25/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSSQLiteDatabase.h"


@implementation CSSQLiteDatabase

#pragma mark -
#pragma mark Initialization and dealloc related messages

+ (id)databaseWithPath:(NSString *)aPath error:(NSError **)error
{
    CSSQLiteDatabase *database = [[CSSQLiteDatabase alloc] initWithPath:aPath error:error];
    return database;
}

- (id)initWithPath:(NSString *)aPath error:(NSError **)error
{
    if ([super init] == nil) {
        return nil;
    }
    
    path = [aPath retain];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    int errorCode = sqlite3_open_v2([fileManager fileSystemRepresentationWithPath:path], 
                                    &sqliteDatabase,
                                    SQLITE_OPEN_READWRITE,
                                    0);

    if (errorCode != SQLITE_OK) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        *error = [[NSError alloc] initWithDomain:@"CSSQLite" 
                                            code:errorCode
                                        userInfo:errorDetail];

        return nil;
    }
    
    return self;
}

- (void)dealloc
{
    int errorCode = sqlite3_close(sqliteDatabase);
    
    if (errorCode != SQLITE_OK) {
        NSLog(@"Couldn't close database handle.");
    }
    else {
        sqliteDatabase = NULL;
    }

    [path release];
    [super dealloc];
}

#pragma mark -
#pragma mark CSSQLiteDatabase related messages

- (BOOL)executeSQL:(NSString *)sql
        withValues:(NSArray *)values
          callback:(CSQLiteCallback)callbackFunction 
           context:(void *)context
             error:(NSError **)error;
{
    int errorCode;
    char *errorMessage;
    
    errorCode = sqlite3_exec(sqliteDatabase, [sql UTF8String], callbackFunction, 
                             context, &errorMessage);
    
    if (errorCode != SQLITE_OK && errorCode != SQLITE_ABORT) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        
        [errorDetail setObject:[NSString stringWithFormat:@"%s", errorMessage] 
                        forKey:@"errorMessage"];
        *error = [[NSError alloc] initWithDomain:@"CSSQLite" 
                                            code:errorCode 
                                        userInfo:errorDetail];
        
        return NO;
    }
    
    return YES;    
}

#pragma mark -
#pragma mark CSQLDatabase related messages

- (BOOL)executeSQL:(NSString *)sql 
        withValues:(NSArray *)values
             error:(NSError **)error 
{
    return [self executeSQL:sql
                 withValues:values
                   callback:nil
                    context:nil
                      error:error];
}

- (BOOL)executeSQL:(NSString *)sql 
             error:(NSError **)error
{
    return [self executeSQL:sql
                 withValues:nil
                      error:error];
}

#pragma mark -
#pragma mark Row as Array

- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql 
                         withValues:(NSArray *)values 
                              error:(NSError **)error
{
    NSMutableArray *row = [NSMutableArray array];

    BOOL success = [self executeSQL:sql
                         withValues:values
                           callback:(CSQLiteCallback)rowAsArrayCallback 
                            context:row
                              error:error];
    
    if (!success) 
        return nil;
        
    return row;
}

- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql 
                              error:(NSError **)error
{
    return [self fetchRowAsArrayWithSQL:sql
                             withValues:nil
                                  error:error];
}

#pragma mark -
#pragma mark Row as Dictionary

- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql 
                                   withValues:(NSArray *)values 
                                        error:(NSError **)error
{
    NSMutableDictionary *row = [NSMutableDictionary dictionary];
    
    BOOL success = [self executeSQL:sql withValues:values 
                           callback:(CSQLiteCallback)rowAsDictionaryCallback 
                            context:row error:error];
    
    if (!success)
        return nil;
    
    return row;
}

- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql 
                                        error:(NSError **)error
{
    return [self fetchRowAsDictionaryWithSQL:sql withValues:nil error:error];
}

#pragma mark -
#pragma mark Rows as Dictionaries

- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql 
                                 withValues:(NSArray *)values 
                                      error:(NSError **)error
{
    NSMutableArray *rows = [NSMutableArray array];
    
    BOOL success = [self executeSQL:sql
                         withValues:values
                           callback:(CSQLiteCallback)rowsAsDictionariesCallback
                            context:rows
                              error:error];
    
    if (!success)
        return nil;
    
    return rows;
}

- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql 
                                      error:(NSError **)error
{
    return [self fetchRowsAsDictionariesWithSQL:sql
                                     withValues:nil
                                          error:error];
}

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                           withValues:(NSArray *)values 
                                error:(NSError **)error
{
    NSMutableArray *rows = [NSMutableArray array];
    
    BOOL success = [self executeSQL:sql
                         withValues:values
                           callback:(CSQLiteCallback)rowsAsArraysCallback
                            context:rows 
                              error:error];
    
    if (!success)
        return nil;
    
    return rows;
}

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                                error:(NSError **)error
{
    return [self fetchRowsAsArraysWithSQL:sql
                               withValues:nil
                                    error:error];
}

#pragma mark -
#pragma mark Prepared Statement messages

- (id)prepareStatement:(NSString *)sql 
                 error:(NSError **)error
{
    return nil;
}

@end

#pragma mark -
#pragma mark SQLite callbacks

int rowAsArrayCallback(void *callbackContext,
                       int columnCount,
                       char **columnValues,
                       char **columnNames)
{
    NSMutableArray *row = callbackContext;
    
    for (int i = 0; i < columnCount; i++) {
        [row addObject:[NSString stringWithFormat:@"%s", columnValues[i]]];
    }

    return SQLITE_DONE;
}

int rowAsDictionaryCallback(void *callbackContext,
                            int columnCount,
                            char **columnValues,
                            char **columnNames)
{
    NSMutableDictionary *row = callbackContext;
    
    for (int i = 0; i < columnCount; i++) {
        [row setObject:[NSString stringWithFormat:@"%s", columnValues[i]]
                forKey:[NSString stringWithFormat:@"%s", columnNames[i]]];
    }
    
    return SQLITE_DONE;
}

int rowsAsDictionariesCallback(void *callbackContext,
                               int columnCount,
                               char **columnValues,
                               char **columnNames)
{
    NSMutableArray *rows = callbackContext;

    NSMutableDictionary *row = [NSMutableDictionary dictionaryWithCapacity:columnCount];
    
    for (int i = 0; i < columnCount; i++) {
        [row setObject:[NSString stringWithFormat:@"%s", columnValues[i]]
                forKey:[NSString stringWithFormat:@"%s", columnNames[i]]];
    }
    
    [rows addObject:row];
    
    return SQLITE_OK;
}

int rowsAsArraysCallback(void *callbackContext,
                         int columnCount,
                         char **columnValues,
                         char **columnNames)
{
    NSMutableArray *rows = callbackContext;
    
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:columnCount];
    
    for (int i = 0; i < columnCount; i++) {
        [row addObject:[NSString stringWithFormat:@"%s", columnValues[i]]];
    }
    
    [rows addObject:row];
    
    return SQLITE_OK;
}
