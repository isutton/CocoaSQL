# About CocoaSQL

The aim of the CocoaSQL project is to deliver a de-facto database API for
Cocoa. Also, we want it to be as Cocoa compliant as possible.

Our initial plan is to provide at least SQLite and MySQL connectors, and
eventually extend it to other databases.

The project is, at the time of this writing, composed of the following 
protocols that must be implemented on a per driver basis:

* CSQLDatabase
* CSQLPreparedStatement

Additionally, provides the following concrete classes:

* CSQLDatabase
* CSQLBindValue

# Sample Code
        #import <CocoaSQL.h>

	NSError *error = nil;
	NSMutableDictionary *options = [NSMutableDictionary dictionary];

	// Connects to a SQLite database.
	CSQLDatabase *database = [CSQLDatabase databaseWithDriver:@"SQLite" andOptions:options error:&error];
	
	// Executes a query.
	NSUInteger affectedRows = [database executeSQL:@"DELETE FROM t" error:&error];

	// Creates a new prepared statement
	CSQLPreparedStatement *statement = [database prepareStatement:@"SELECT * FROM t WHERE i = ? LIMIT 10" error:&error];

	// Create the binding values. the bind*Value in NSMutableArray is added through
	// the CocoaSQL category.
	NSMutableArray *values = [NSMutableArray arrayWithCapacity:1];
	[values bindIntValue:1];

	// or simply by creating/populating an NSArray (or a normal NSMutableArray) with CSQLBindValues
	NSArray *values = [NSArray arrayWithObject:[CSQLBindValue bindValueWithInt:1]];

	// Executes the prepared statement.
	BOOL success = [statement executeWithValues:values error:&error];
	
	// Fetch all rows, one by one.
	NSDictionary* row = nil;
	while (row = [statement fetchRowAsDictionary:&error]) {
		NSLog(@"Row: %@", row);
	}
	
