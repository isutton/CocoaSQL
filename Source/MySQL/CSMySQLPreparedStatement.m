//
//  CSMySQLPreparedStatement.m
//  CocoaSQL
//
//  Created by xant on 4/6/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSMySQLPreparedStatement.h"
#import "CSMySQLDatabase.h"
#import "CSQLBindValue.h"

@implementation CSMySQLPreparedStatement


- (id)initWithDatabase:(CSMySQLDatabase *)aDatabase andSQL:(NSString *)sql error:(NSError **)error
{
    [super init];
    self.database = aDatabase;
    statement = mysql_stmt_init([aDatabase MySQLDatabase]);
    int errorCode = mysql_stmt_prepare(statement, [sql UTF8String], [sql length]); 
    if (errorCode != 0) {
        NSMutableDictionary *errorDetail;
        errorDetail = [NSMutableDictionary dictionary];
        NSString *errorMessage = [NSString stringWithFormat:@"%s", mysql_error([aDatabase MySQLDatabase])];
        [errorDetail setObject:errorMessage forKey:@"errorMessage"];
        *error = [NSError errorWithDomain:@"CSMySQL" code:errorCode userInfo:errorDetail];
        return nil;
    }
    return self;
}


#pragma mark -
#pragma mark Execute messages

- (BOOL)executeWithValues:(NSArray *)values error:(NSError **)error
{
    int bindParameterCount = [values count];
    
    if (bindParameterCount > 0) {
        
        if (!values || [values count] < bindParameterCount) {
            NSMutableDictionary *errorDetail;
            errorDetail = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Expected %i value(s), %i provided", bindParameterCount, [values count]], @"errorMessage", nil];
            *error = [NSError errorWithDomain:@"CSMySQL" code:100 userInfo:errorDetail];
            return NO;
        }
        
        for (int i = 1; i <= bindParameterCount; i++) {
            CSQLBindValue *value = [values objectAtIndex:i-1];
            BOOL success;
            switch ([value type]) {
                case CSQLInteger:
                    success = [self bindIntValue:[value intValue] forColumn:i];
                    break;
                case CSQLDouble:
                    success = [self bindDoubleValue:[value doubleValue] forColumn:i];
                    break;
                case CSQLText:
                    success = [self bindStringValue:[value stringValue] forColumn:i];
                    break;
                case CSQLBlob:
                    success = [self bindDataValue:[value dataValue] forColumn:i];
                    break;
                case CSQLNull:
                    success = [self bindNullValueForColumn:i];
                    break;
                default:
                    break;
            }
            
            if (!success) {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
                NSString *errorMessage = [NSString stringWithFormat:@"%s", mysql_error([(CSMySQLDatabase *)database MySQLDatabase])];
                [errorDetail setObject:errorMessage forKey:@"errorMessage"];
                *error = [NSError errorWithDomain:@"CSMySQL" code:101 userInfo:errorDetail];
                return NO;
            }
        }
    }
    
    return YES;
}

- (BOOL)execute:(NSError **)error
{
    return [self executeWithValues:nil error:error];
}

@end
