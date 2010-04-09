//
//  NSError+CocoaSQL.m
//  CocoaSQL
//
//  Created by Igor Sutton on 4/9/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "NSError+CocoaSQL.h"


@implementation NSError (CocoaSQL)

+ (NSError *)errorWithMessage:(NSString *)errorMessage andCode:(NSInteger)code
{
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
    [errorDetail setObject:errorMessage forKey:@"errorMessage"];
    return [NSError errorWithDomain:@"CocoaSQL" code:code userInfo:errorDetail];
}

@end
