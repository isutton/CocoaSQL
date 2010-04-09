/*
 *  otest.c
 *  CocoaSQL
 *
 *  Created by Igor Sutton on 4/9/10.
 *  Copyright 2010 CocoaSQL.org. All rights reserved.
 *
 */


#import <Cocoa/Cocoa.h>
#import <SenTestingKit/SenTestingKit.h>

int main(int argc, char **argv) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Tell SenTestingKit to use our last argument as the test bundle, to
    // run all the tests it can find, and that the executable is equivalent
    // to the otest test rig supplied with OCUnit.
    
    NSDictionary *testDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [[[NSProcessInfo processInfo] arguments] lastObject], SenTestedUnitPath,
                                  SenTestScopeAll, SenTestScopeKey,
                                  [NSNumber numberWithBool:YES], SenTestToolKey,
                                  nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:testDefaults];
    
    // Run the tests based on the defaults set above.
    // It will invoke exit() with an appropriate value as well.

    SenSelfTestMain();
    
    [pool drain];
    return 0;
}
