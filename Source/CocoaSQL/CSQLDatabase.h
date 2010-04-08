//
//  CSQLDatabase.h
//  CocoaSQL
//
//  Created by Igor Sutton on 3/25/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import "CSQLPreparedStatement.h"
#import "CSQLDatabase+Protocol.h"

@class CSQLDatabase;

@interface CSQLDatabase : NSObject <CSQLDatabase>
{
    voidPtr databaseHandle;
}

@property (readonly) voidPtr databaseHandle;

+ (CSQLDatabase *)databaseWithDSN:(NSString *)aDSN error:(NSError **)error;
+ (CSQLDatabase *)databaseWithDriver:(NSString *)aDriver options:(NSDictionary *)options error:(NSError **)error;

@end
