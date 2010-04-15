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
//  CSMySQLDatabase.m by xant on 4/2/10.
//

#import "CSMySQLDatabase.h"
#import "CSMySQLPreparedStatement.h"
#import "CSQLResultCallback.h"
#include <mysql.h>

@implementation CSMySQLDatabase

@dynamic databaseHandle;
@dynamic affectedRows;

#pragma mark -
#pragma mark Initialization and dealloc related messages

+ (id)databaseWithOptions:(NSDictionary *)options 
                    error:(NSError **)error
{
    CSMySQLDatabase *database;
    NSString *databaseName = (NSString *)[options objectForKey:@"db"];
    NSString *hostname = (NSString *)[options objectForKey:@"host"];
    NSString *user = (NSString *)[options objectForKey:@"user"];
    NSString *password = (NSString *)[options objectForKey:@"password"];
    database = [CSMySQLDatabase databaseWithName:databaseName
                                            host:hostname
                                            user:user
                                        password:password
                                           error:error];
    return database;
}

+ (id)databaseWithName:(NSString *)databaseName host:(NSString *)host user:(NSString *)user password:(NSString *)password error:(NSError **)error
{
    CSMySQLDatabase *database = [[CSMySQLDatabase alloc] initWithName:databaseName
                                                                 host:host
                                                                 user:user
                                                             password:password
                                                                error:error];

    return [database autorelease];
    
}

- (id)initWithName:(NSString *)databaseName host:(NSString *)host user:(NSString *)user password:(NSString *)password error:(NSError **)error
{
    databaseHandle = calloc(1, sizeof(MYSQL));
    mysql_init(databaseHandle);
    MYSQL *connected = mysql_real_connect(databaseHandle, 
                                          [host UTF8String],
                                          [user UTF8String],
                                          [password UTF8String],
                                          [databaseName UTF8String],
                                          0,
                                          NULL,
                                          0);

    if (!connected && mysql_ping(databaseHandle) != 0) {
        if (error) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithCapacity:1];
            NSString *errorMessage = [NSString stringWithFormat:@"Can't connect to database: %s", 
                                      mysql_error(databaseHandle)];
            [errorDetail setObject:errorMessage forKey:@"errorMessage"];
            *error = [NSError errorWithDomain:@"CSMySQLDatabase" code:500 userInfo:errorDetail];
            // XXX - I'm unsure if returning nil here is safe, 
            //       since an instance has been already alloc'd
            //       so if used with the idiom [[class alloc] init]
            //       the alloc'd pointer will be leaked
            return nil;            
        }
    }
    return self;
}

- (void)dealloc
{
    if (databaseHandle) {
        mysql_close(databaseHandle);
        free(databaseHandle);
    }
    [super dealloc];
}

#pragma mark -
#pragma mark CSMySQLDatabase related messages

- (BOOL)executeSQL:(NSString *)sql
        withValues:(NSArray *)values
          receiver:(id)receiver
		  selector:(SEL)selector
             error:(NSError **)error;
{
	BOOL rc = NO;
	CSMySQLPreparedStatement *statement = [CSMySQLPreparedStatement preparedStatementWithDatabase:self andSQL:sql error:error];
	if (statement) {
		rc = [statement executeWithValues:values receiver:receiver selector:selector error:error];
		my_ulonglong numRows = mysql_affected_rows(databaseHandle);
		if (affectedRows)
			[affectedRows release]; 
		affectedRows = [[NSNumber numberWithUnsignedLongLong:numRows] retain];
		[statement finish];
	}
    return rc;
}

#pragma mark -
#pragma mark CSQLDatabase related messages
- (BOOL)executeSQL:(NSString *)sql 
              withValues:(NSArray *)values
                   error:(NSError **)error 
{
    return [self executeSQL:sql
                 withValues:values
                   receiver:nil
                    selector:nil
                      error:error];
}

- (BOOL)executeSQL:(NSString *)sql 
            error:(NSError **)error
{
    return [self executeSQL:sql
                 withValues:nil
				   receiver:nil
				   selector:nil
                      error:error];
}


- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error
{
    CSMySQLPreparedStatement *statement = [CSMySQLPreparedStatement preparedStatementWithDatabase:self andSQL:sql error:error];    
    if (!statement) {
        return nil;
    }
    
    [statement executeWithValues:values error:error];
	
    NSArray *row = [statement fetchRowAsArray:error];
	my_ulonglong numRows = mysql_affected_rows(databaseHandle);
	if (affectedRows)
		[affectedRows release]; 
	affectedRows = [[NSNumber numberWithUnsignedLongLong:numRows] retain];
	[statement finish];
	return row;
}

- (NSArray *)fetchRowAsArrayWithSQL:(NSString *)sql error:(NSError **)error
{
    return [self fetchRowAsArrayWithSQL:sql withValues:nil error:error];
}

- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql withValues:(NSArray *)values error:(NSError **)error
{
    CSMySQLPreparedStatement *statement = [CSMySQLPreparedStatement preparedStatementWithDatabase:self andSQL:sql error:error];    
    if (!statement) {
        return nil;
    }
    
    [statement executeWithValues:values error:error];
	
    NSDictionary *row = [statement fetchRowAsDictionary:error];
	my_ulonglong numRows = mysql_affected_rows(databaseHandle);
	if (affectedRows)
		[affectedRows release]; 
	affectedRows = [[NSNumber numberWithUnsignedLongLong:numRows] retain];
	[statement finish];
	return row;
}

- (NSDictionary *)fetchRowAsDictionaryWithSQL:(NSString *)sql error:(NSError **)error
{
    return [self fetchRowAsDictionaryWithSQL:sql withValues:nil error:error];
}


#pragma mark -
#pragma mark Rows as Dictionaries

- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql 
                                 withValues:(NSArray *)values 
                                      error:(NSError **)error
{
    CSQLResultCallback *callback = [CSQLResultCallback alloc];
    BOOL success = [self executeSQL:sql
                         withValues:values
                           receiver:callback
                            selector:@selector(rowsAsDictionaries:)
                              error:error];
    NSMutableArray *rows = [[callback rows] retain];
	[callback release];
    return success ? rows : nil;
}

- (NSArray *)fetchRowsAsDictionariesWithSQL:(NSString *)sql 
                                      error:(NSError **)error
{
    return [self fetchRowsAsDictionariesWithSQL:sql
                                     withValues:nil
                                          error:error];
}

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                           withValues:(NSArray *)values 
                                error:(NSError **)error
{
	CSQLResultCallback *callback = [CSQLResultCallback alloc];
    BOOL success = [self executeSQL:sql
                         withValues:values
                           receiver:callback
						   selector:@selector(rowsAsArrays:) 
                              error:error];
    NSMutableArray *rows = [[callback rows] retain]; 
	[callback release];
    return success ? rows : nil;
}

- (NSArray *)fetchRowsAsArraysWithSQL:(NSString *)sql 
                                error:(NSError **)error
{
    return [self fetchRowsAsArraysWithSQL:sql
                               withValues:nil
                                    error:error];
}

- (NSNumber *)lastInsertID
{
    my_ulonglong last_id = mysql_insert_id(databaseHandle);
    return [NSNumber numberWithLongLong:last_id];
}

- (BOOL)isActive:(NSError **)error
{
    // TODO - return an error message
    // XXX - being not active is a perfectly valid condition ...
    //       so I don't really know what should be considered an error here
    if (databaseHandle)
        return (mysql_ping(databaseHandle) == 0) ? YES : NO;
    return NO;
}

- (BOOL)disconnect:(NSError **)error
{
    // TODO - return an error message
    // XXX - also here I can't see any error condition 
    //       which requires an explanatory message
    mysql_close(databaseHandle);
    databaseHandle = nil;
    return YES;
}

#pragma mark -
#pragma mark Prepared Statement messages

- (CSQLPreparedStatement *)prepareStatement:(NSString *)sql error:(NSError **)error
{
    return [CSMySQLPreparedStatement preparedStatementWithDatabase:self andSQL:sql error:error];
}

@end
