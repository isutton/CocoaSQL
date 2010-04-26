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
//  CSPostgreSQLRow.m by Igor Sutton on 4/26/10.
//

#import "CSPostgreSQLRow.h"


@implementation CSPostgreSQLRow

@synthesize row;
@synthesize numFields;
@synthesize statement;

+ (id)rowWithStatement:(CSPostgreSQLPreparedStatement *)aStatement andRow:(int)index
{
    return [[[self alloc] initWithStatement:aStatement andRow:index] autorelease];
}

- (id)initWithStatement:(CSPostgreSQLPreparedStatement *)aStatement andRow:(int)index
{
    if (self = [super init]) {
        self.row = index;
        self.statement = aStatement;
        numFields = PQnfields(statement.statement);
    }
    
    return self;
}

- (BOOL)isBinary:(int)index
{
    return PQfformat(statement.statement, index) == 1;
}

- (int)lengthForColumn:(int)index
{
    return PQgetlength(statement.statement, row, index);
}

- (int)typeForColumn:(int)index
{
    return PQftype(statement.statement, index);
}

- (char *)valueForColumn:(int)index
{
    return PQgetvalue(statement.statement, row, index);
}

- (BOOL)isNull:(int)index
{
    return (PQgetisnull(statement.statement, row, index) == 1);
}

- (id)objectForColumn:(int)index
{
    CSQLResultValue *aValue = nil;
    
    int length_ = [self lengthForColumn:index];
    char *value_ = [self valueForColumn:index];
    union { float f; uint32_t i; } floatValue;
    union { double d; uint64_t i; } doubleValue;
    
    if ([self isNull:index]) {
        return [CSQLResultValue valueWithNull];
    }
    
    static NSDate *POSTGRES_EPOCH_DATE = nil;
    
    if (!POSTGRES_EPOCH_DATE)
        POSTGRES_EPOCH_DATE = [NSDate dateWithString:@"2000-01-01 00:00:00 +0000"];
    
    switch ([self typeForColumn:index]) {
        case BYTEAOID:
            aValue = [CSQLResultValue valueWithData:[NSData dataWithBytes:value_ length:length_]];
            break;
        case CHAROID:
        case TEXTOID:
        case VARCHAROID:
            aValue = [CSQLResultValue valueWithUTF8String:value_];
            break;
        case INT8OID:
            aValue = [CSQLResultValue valueWithNumber:[NSNumber numberWithLong:OSSwapConstInt64(*((uint64_t *)value_))]];
            break;
        case INT4OID:
            aValue = [CSQLResultValue valueWithNumber:[NSNumber numberWithInt:OSSwapConstInt32(*((uint32_t *)value_))]];
            break;
        case INT2OID:
            aValue = [CSQLResultValue valueWithNumber:[NSNumber numberWithShort:OSSwapConstInt16(*((uint16_t *)value_))]];
            break;
        case FLOAT4OID:
            floatValue.i = OSSwapConstInt32(*((uint32_t *)value_));
            aValue = [CSQLResultValue valueWithNumber:[NSNumber numberWithFloat:floatValue.f]];
            break;
        case FLOAT8OID:
            doubleValue.i = OSSwapConstInt64(*((uint64_t *)value_));
            aValue = [CSQLResultValue valueWithNumber:[NSNumber numberWithDouble:doubleValue.d]];
            break;
            
            //
            // Both TIMESTAMPOID and TIMESTAMPTZOID are sent either as int64 if compiled
            // with timestamp as integers or double (float8 in PostgreSQL speak) if the compile
            // option was disabled. Basically here we're assuming int64 which are microseconds since
            // POSTGRES_EPOCH_DATE (2000-01-01).
            //
            
        case TIMESTAMPTZOID:
        case TIMESTAMPOID:
            aValue = [CSQLResultValue valueWithDate:[NSDate dateWithTimeInterval:((double)OSSwapConstInt64(*((uint64_t *)value_))/1000000) 
                                                                       sinceDate:POSTGRES_EPOCH_DATE]];
            break;
        case DATEOID:
            aValue = [CSQLResultValue valueWithDate:[[NSDate dateWithString:@"2000-01-01 00:00:00 +0000"] 
                                                     dateByAddingTimeInterval:OSSwapConstInt32(*((uint32_t *)value_)) * 24 * 3600]];
            break;
        default:
            break;
    }
    return aValue;
}

- (id)nameForColumn:(int)index
{
    return [NSString stringWithUTF8String:PQfname(statement.statement, index)];
}

- (NSArray *)rowAsArray
{
    NSMutableArray *row_ = [NSMutableArray arrayWithCapacity:numFields];
    for (int i = 0; i < numFields; i++) {
        [row_ addObject:[self objectForColumn:i]];
    }
    return row_;
}

- (NSDictionary *)rowAsDictionary
{
    NSMutableDictionary *row_ = [NSMutableDictionary dictionaryWithCapacity:numFields];
    for (int i = 0; i < numFields; i++) {
        [row_ setObject:[self objectForColumn:i] forKey:[self nameForColumn:i]];
    }
    return row_;
}

- (void)dealloc
{
    [statement release];
    [super dealloc];
}

@end
