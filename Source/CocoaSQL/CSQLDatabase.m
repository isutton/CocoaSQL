//
//  CSQLDatabase.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/31/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSQLDatabase.h"

@implementation CSQLDatabase

@synthesize databaseHandle;

+ (CSQLDatabase *)databaseWithDriver:(NSString *)aDriver options:(NSDictionary *)options error:(NSError **)error
{
    NSString *aClassName = [NSString stringWithFormat:@"CS%@Database", aDriver];
    Class class = NSClassFromString(aClassName);
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
