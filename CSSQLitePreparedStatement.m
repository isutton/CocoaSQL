//
//  CSSQLitePreparedStatement.m
//  CocoaSQL
//
//  Created by Igor Sutton on 3/26/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSSQLitePreparedStatement.h"


@implementation CSSQLitePreparedStatement


+ (id)preparedStatementWithDatabase:(id)aDatabase 
                             andSQL:(NSString *)sql
                              error:(NSError **)error
{
    return nil;
}

- (id)initWithDatabase:(id)aDatabase 
                andSQL:(NSString *)sql
                 error:(NSError **)error
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
