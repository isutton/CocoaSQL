//
//
//  This file is part of CocoaSQL
//
//  CocoaSQL is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with CocoaSQL.  If not, see <http://www.gnu.org/licenses/>.
//
//  otest.c by Igor Sutton on 4/9/10.
//

#import <Cocoa/Cocoa.h>
#import <SenTestingKit/SenTestingKit.h>

int main(int argc, char **argv) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSBundle *bundle = [NSBundle bundleWithPath:@"CocoaSQL.framework"];
    [bundle load];
    
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
