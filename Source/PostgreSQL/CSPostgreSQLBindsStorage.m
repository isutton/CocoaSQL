//
//
//  This file is part of CocoaSQL
//
//  CocoaSQL is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  CocoaSQL is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with CocoaSQL.  If not, see <http://www.gnu.org/licenses/>.
//
//  CSPostgreSQLBindsStorage.m by Igor Sutton on 4/26/10.
//

#import "CSPostgreSQLDatabase.h"
#import "CSPostgreSQLBindsStorage.h"

@implementation CSPostgreSQLBindsStorage

@synthesize numParams;
@synthesize paramTypes;
@synthesize paramLengths;
@synthesize paramFormats;
@synthesize paramValues;
@synthesize resultFormat;

- (id)initWithStatement:(CSPostgreSQLPreparedStatement *)aStatement andValues:(NSArray *)values
{
    if ([self init]) {
        statement = [aStatement retain];
        resultFormat = 1; // We want binary results.
        numParams = 0;
        paramValues = nil;
        paramLengths = nil;
        paramFormats = nil;
        paramTypes = nil;
        [self setValues:values];
    }
    return self;
}

- (BOOL)bindValue:(id)aValue toColumn:(int)index
{
    int type = PQftype(statement.statement, index);
    
    if ([[aValue class] isSubclassOfClass:[NSNumber class]]) {
        switch (type) {
            case FLOAT8OID:
                paramValues[index] = (char *)[aValue pointerValue];
                break;
            case FLOAT4OID:
                paramValues[index] = (char *)[aValue pointerValue];
                break;
            case INT2OID:
            case INT4OID:
            case INT8OID:
                *paramValues[index] = (uint32_t)htonl(*((uint32_t *)[aValue pointerValue]));
                break;
            default:
                paramValues[index] = (char *)[[aValue stringValue] UTF8String];
                break;
        }        
    }
    else if ([[aValue class] isSubclassOfClass:[NSString class]]) {
        paramFormats[index] = 1;
        paramLengths[index] = [(NSString *)aValue lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        paramValues[index] = (char *)[aValue UTF8String];
    }
    else if ([[aValue class] isSubclassOfClass:[NSData class]]) {
        paramFormats[index] = 1;
        paramLengths[index] = [aValue length];
        paramValues[index] = (char *)[aValue bytes];
    }
    else if ([[aValue class] isSubclassOfClass:[NSDate class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        switch (type) {
            case DATEOID:
                [formatter setDateFormat:((CSPostgreSQLDatabase *)statement.database).dateStyle];
                break;
            case TIMEOID:
                [formatter setDateFormat:((CSPostgreSQLDatabase *)statement.database).timeStyle];
                break;
            case TIMESTAMPOID:
            case TIMESTAMPTZOID:
            default:
                [formatter setDateFormat:((CSPostgreSQLDatabase *)statement.database).timestampStyle];
                break;
        }
        paramValues[index] = (char *)[[formatter stringFromDate:aValue] UTF8String]; 
        [formatter release];
    }
    else if ([[aValue class] isSubclassOfClass:[NSNull class]]) {
        paramFormats[index] = 1;
        paramValues[index] = '\0';
    }
    
    return YES;
}

- (BOOL)setValues:(NSArray *)values
{
    if (!values)
        return NO;
    
    numParams = [values count];
    paramValues = malloc([values count] * sizeof(char *));
    paramLengths = calloc([values count], sizeof(int));
    paramFormats = calloc([values count], sizeof(int));
    paramTypes = calloc([values count], sizeof(int));
    
    for (int i = 0; i < [values count]; i++) {
        [self bindValue:[values objectAtIndex:i] toColumn:i];
    }
    
    return YES;
    
}

- (void)dealloc
{
    free(paramValues);
    free(paramLengths);
    free(paramFormats);
    free(paramTypes);
    [statement release];
    [super dealloc];
}

@end
