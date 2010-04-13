//
//  CSQLPostgreSQLDatabase.h
//  CocoaSQL
//
//  Created by Igor Sutton on 4/13/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CocoaSQL.h"

@interface CSPostgreSQLDatabase : CSQLDatabase {

}

- (id)initWithOptions:(NSDictionary *)options error:(NSError **)error;

@end
