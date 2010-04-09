//
//  NSError+CocoaSQL.h
//  CocoaSQL
//
//  Created by Igor Sutton on 4/9/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSError (CocoaSQL)

+ (NSError *)errorWithMessage:(NSString *)errorMessage andCode:(NSInteger)code;

@end
