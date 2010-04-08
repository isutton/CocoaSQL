//
//  CSSQLite.h
//  CocoaSQL
//
//  Created by Igor Sutton on 3/25/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CSQLDatabase.h"
#import "CSSQLitePreparedStatement.h"

#include <sqlite3.h>

typedef int (*CSQLiteCallback)(void *, int, char**, char**);

@interface CSSQLiteDatabase : CSQLDatabase {
    NSString *path;
}

@property (copy) NSString *path;
@property (readwrite,assign) voidPtr databaseHandle;

#pragma mark -
#pragma mark Initialization related messages

+ (id)databaseWithPath:(NSString *)aPath error:(NSError **)error;


- (id)initWithPath:(NSString *)aPath error:(NSError **)error;

#pragma mark -
#pragma mark CSSQLiteDatabase related messages

- (NSUInteger)executeSQL:(NSString *)sql withValues:(NSArray *)values callback:(CSQLiteCallback)callbackFunction context:(void *)context error:(NSError **)error;

@end

#pragma mark -
#pragma mark SQLite callbacks

int rowAsArrayCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames);

int rowAsDictionaryCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames);

int rowsAsDictionariesCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames);

int rowsAsArraysCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames);
