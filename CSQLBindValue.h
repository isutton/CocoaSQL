//
//  CSQLBindValue.h
//  CocoaSQL
//
//  Created by Igor Sutton on 3/29/10.
//  Copyright 2010 CocoaSQL.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    Float,
    Text,
    Integer,
    Blob
} CSQLBindValueType;

@interface CSQLBindValue : NSObject {
    CSQLBindValueType type;
    id value;
}

@end
