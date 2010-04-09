//
//  CSQLDatabase.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/31/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CocoaSQL.h"

@implementation CSQLDatabase

@synthesize databaseHandle;

+ (CSQLDatabase *)databaseWithDriver:(NSString *)aDriver options:(NSDictionary *)options error:(NSError **)error
{
    NSString *aClassName = [NSString stringWithFormat:@"CS%@Database", aDriver];
    Class class = NSClassFromString(aClassName);
    
    if (!class) {
        if (error) {
            *error = [NSError errorWithMessage:[NSString stringWithFormat:@"Couldn't find class %@.", aClassName] andCode:500];
        }
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

@end


int rowAsArrayCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames)
{
    NSMutableArray *row = callbackContext;
    for (int i = 0; i < columnCount; i++) {
        [row addObject:[NSString stringWithFormat:@"%s", columnValues[i]]];
    }
    return 0;
}

int rowAsDictionaryCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames)
{
    NSMutableDictionary *row = callbackContext;
    for (int i = 0; i < columnCount; i++) {
        [row setObject:[NSString stringWithFormat:@"%s", columnValues[i]]
                forKey:[NSString stringWithFormat:@"%s", columnNames[i]]];
    }
    return 0;
}

int rowsAsDictionariesCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames)
{
    NSMutableArray *rows = callbackContext;
    NSMutableDictionary *row = [NSMutableDictionary dictionaryWithCapacity:columnCount];
    for (int i = 0; i < columnCount; i++) {
        [row setObject:[NSString stringWithFormat:@"%s", columnValues[i]]
                forKey:[NSString stringWithFormat:@"%s", columnNames[i]]];
    }
    [rows addObject:row];
    return 0;
}

int rowsAsArraysCallback(void *callbackContext, int columnCount, char **columnValues, char **columnNames)
{
    NSMutableArray *rows = callbackContext;
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:columnCount];
    for (int i = 0; i < columnCount; i++) {
        [row addObject:[NSString stringWithFormat:@"%s", columnValues[i]]];
    }
    [rows addObject:row];
    return 0;
}

