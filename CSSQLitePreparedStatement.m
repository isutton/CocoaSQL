//
//  CSSQLitePreparedStatement.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/26/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSSQLitePreparedStatement.h"


@implementation CSSQLitePreparedStatement


+ (id <CSQLPreparedStatement>)preparedStatementWithDatabase:(id <CSQLDatabase> *)database 
                                                     andSQL:(NSString *)sql
{
    return nil;
}

- (id <CSQLPreparedStatement>)initWithDatabase:(id <CSQLDatabase> *)database 
                                        andSQL:(NSString *)sql
{
    return nil;
}

- (BOOL)executeWithValues:(NSArray *)values 
                    error:(NSError **)error
{
    return NO;
}

- (BOOL)execute:(NSError **)error
{
    return [self executeWithValues:nil error:error];
}

- (NSArray *)fetchRowAsArray:(NSError **)error
{
    return nil;
}

- (NSDictionary *)fetchRowAsDictionary:(NSError **)error
{
    return nil;
}

- (void)dealloc
{
    [super dealloc];
}
@end
