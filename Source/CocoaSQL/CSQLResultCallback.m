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
//  CSQLResultCallback.m by xant on 4/15/10.
//

#import "CSQLResultCallback.h"


@implementation CSQLResultCallback

- (id)init
{
    if (!(self = [super init]))
        return nil;
    
	rows = [[NSMutableArray alloc] init];
    return self;
}

- (void)dealloc
{
	if (rows)
		[rows release];
	[super dealloc];
}


- (NSInteger)rowsAsDictionaries:(NSDictionary *)row
{
	[rows addObject:row];
    return 0;
}

- (NSInteger)rowsAsArrays:(NSDictionary *)row
{
	id key;
	NSEnumerator *enumerator = [row keyEnumerator];
    NSMutableArray *thisRow = [NSMutableArray array];
	while ((key = [enumerator nextObject]))
		[thisRow addObject:[row objectForKey:key]];
    [rows addObject:thisRow];
    return 0;
}

@synthesize rows;
@end
