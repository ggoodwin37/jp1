//
//  WorldTest.m
//  JumpProto
//
//  Created by gideong on 7/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WorldTest.h"
#import "Block.h"
#import "DebugLogLayerView.h"
#import "gutil.h"
#import "AspectController.h"
#import "constants.h"
#import "WorldArchiveUtil.h"
#import "BlockGroup.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TestBlock

@implementation TestBlock

@synthesize color = m_color;

-(id)initWithRect:(EmuRect)rect color:(UInt32)color
{
    if( self = [super init] )
    {
        self.state.p = rect.origin;
        self.state.d = rect.size;
        m_color = color;
        
    }
    return self;    
}


-(void)dealloc
{
    [super dealloc];
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// rtti experiment 1/20/2012
// how much of a perf hit is it to do lots of rtti checks? can I base a design on rtti or do I need a faster way?

@interface RTestBase : NSObject {
}
-(void)polymethSumA:(long *)sumA sumB:(long *)sumB;
@end


@interface RTestA : RTestBase {
}
-(void)testASpecialSumA:(long *)sumA sumB:(long *)sumB;
@end

@interface RTestB : RTestBase {
}
-(void)testBSpecialSumA:(long *)sumA sumB:(long *)sumB;
@end


@implementation RTestBase

-(void)polymethSumA:(long *)sumA sumB:(long *)sumB;
{
}

@end

@implementation RTestA

// override
-(void)polymethSumA:(long *)sumA sumB:(long *)sumB;
{
    [super polymethSumA:sumA sumB:sumB];
    (*sumA)++;
}

-(void)testASpecialSumA:(long *)sumA sumB:(long *)sumB
{
    [self polymethSumA:sumA sumB:sumB];
}

@end

@implementation RTestB

// override
-(void)polymethSumA:(long *)sumA sumB:(long *)sumB;
{
    [super polymethSumA:sumA sumB:sumB];
    (*sumB)++;
}

-(void)testBSpecialSumA:(long *)sumA sumB:(long *)sumB
{
    [self polymethSumA:sumA sumB:sumB];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// msg timing experiment 2/2/2012
// I always see objc_sendMsg on the profiles, is it a savings to use member vars instead?



@interface SendMsgTest : NSObject
{
    long m_testCounterMember;
}

@property (nonatomic, assign) long testCounterProperty;

-(void)runTest;

@end


@implementation SendMsgTest

@synthesize testCounterProperty;

-(void)runTest
{
    m_testCounterMember = 0;
    self.testCounterProperty = 0;

    const long maxCount = 1000 * 1000 * 1000;
    
    long timerStart, delta;
    
    timerStart = getUpTimeMs();
    for( long i = 0; i < maxCount; ++i )
    {
        ++m_testCounterMember;
    }
    delta = getUpTimeMs() - timerStart;
    NSLog( @"member time: %ld", delta );
    
    timerStart = getUpTimeMs();
    for( long i = 0; i < maxCount; ++i )
    {
        self.testCounterProperty++;
    }
    delta = getUpTimeMs() - timerStart;
    NSLog( @"prop time:   %ld", delta );
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldTest

@implementation WorldTest

+(void)runMiscTests_rttiTimingTest
{
    const long c_numLoops = 1 * 1000 * 1000;
    
    long startTime;
    
    long controlTime, testTime;
    
    long sumA = 0;
    long sumB = 0;
    
    RTestBase *pBase;
    
    startTime = getUpTimeMs();   
    for( long i = 0; i < c_numLoops; ++i )
    {
        if( frand() < 0.5f )
        {
            pBase = [[RTestA alloc] init];
        }
        else
        {
            pBase = [[RTestB alloc] init];
        }
        
        [pBase polymethSumA:&sumA sumB:&sumB];
         
        [pBase release];
    }
    controlTime = getUpTimeMs() - startTime;
    NSLog( @"controlRun sumA=%ld sumB=%ld", sumA, sumB );
    
    sumA = 0;
    sumB = 0;    
    startTime = getUpTimeMs();   
    for( long i = 0; i < c_numLoops; ++i )
    {
        if( frand() < 0.5f )
        {
            pBase = [[RTestA alloc] init];
        }
        else
        {
            pBase = [[RTestB alloc] init];
        }
        
        // test rtti
        if( [pBase isMemberOfClass:[RTestA class]] )
        {
            RTestA *rTestA = (RTestA *)pBase;
            [rTestA testASpecialSumA:&sumA sumB:&sumB];
        }
        else if( [pBase isMemberOfClass:[RTestB class]] )
        {
            RTestB *rTestB = (RTestB *)pBase;
            [rTestB testBSpecialSumA:&sumA sumB:&sumB];
        }
        
        [pBase release];
    }
    testTime = getUpTimeMs() - startTime;
    NSLog( @"testRun    sumA=%ld sumB=%ld", sumA, sumB );
   
    long delta = testTime - controlTime;
    NSLog( @"rtti test 1: controlTime=%ld, testTime=%ld (delta=%ld).", controlTime, testTime, delta );
   
}


+(void)runMiscTests_sendMessageVsMemberTimingTest
{
    SendMsgTest *smt = [[[SendMsgTest alloc] init] autorelease];
    [smt runTest];
}


+(void)runMiscTests
{
    // result: rtti is fairly slow, taking about 50% longer than the control loop.
    //[WorldTest runMiscTests_rttiTimingTest];
    
    // result: sendMsg is very slow, removing excessive property usage can be a big savings.
    //[WorldTest runMiscTests_sendMessageVsMemberTimingTest];
}


+(void)logTestResultStr:(NSString *)testStr exp:(Emu)expected act:(Emu)actual pNumPassed:(int *)pNumPassed pNumTotal:(int *)pNumTotal
{
    NSString *str;
    BOOL passed = (expected == actual);
    str = [NSString stringWithFormat:
           @"test %@ [%@] exp:%d act:%d", (passed ? @"PASS" : @"FAIL"), testStr, (int)expected, (int)actual];
    DebugOut( str );
    
    if( passed )
    {
        (*pNumPassed)++;
    }
    
    (*pNumTotal)++;
}


+(void)runTestsOnWorld:(World *)world
{
    
    DebugOut( @"Running ElbowRoom Tests (not all converted to Emu yet)" );
    // Note from Emu conversion: you didn't yet convert all of these to native Emus, some are still using EmuRectMakeFromFl. Currently
    //   you're still passing 100% but this is lucky because MakeFromFl is subject to off-by-1 rounding errors. This would be more pure
    //   if you just convert the rest to native Emu coords.
    
    int numPassed = 0, numTotal = 0;
    TestBlock *b;
    TestBlock *testSubject;
    UInt32 color = 0x00ff00;  // not used (since we aren't drawing anything)
    Emu expected, actual;
    NSString *logStr;
    NSArray *edgeList;
    
    [world.elbowRoom reset];
    
    logStr = @"basic left";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 10 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirLeft outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"basic right";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 10 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirRight outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"basic up";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 10 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirUp outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"basic down";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 10 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    
    
    logStr = @"partial clip down";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu + (ONE_BLOCK_SIZE_Emu >> 1), 10 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"partial clip up";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu + (ONE_BLOCK_SIZE_Emu >> 1), 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 10 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirUp outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"partial clip left";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 10 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu + (ONE_BLOCK_SIZE_Emu >> 1), ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirLeft outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"partial clip right";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu + (ONE_BLOCK_SIZE_Emu >> 1), ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 10 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirRight outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    
    
    logStr = @"no hit down";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"no hit up";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirUp outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"no hit left";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirLeft outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"no hit right";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirRight outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    
    
    
    logStr = @"right abut";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 9 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = 0;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirRight outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"left abut";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 9 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = 0;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirLeft outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"up abut";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 9 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = 0;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirUp outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"down abut";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 9 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = 0;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    
    
    
    logStr = @"down barelyHit";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 10 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 9 * ONE_BLOCK_SIZE_Emu - 1, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"up barelyHit";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 9 * ONE_BLOCK_SIZE_Emu - 1, 10 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirUp outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"left barelyHit";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 10 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 9 * ONE_BLOCK_SIZE_Emu - 1, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirLeft outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"right barelyHit";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 10 * ONE_BLOCK_SIZE_Emu, 9 * ONE_BLOCK_SIZE_Emu - 1, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirRight outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    
    
    logStr = @"down barelyMissed";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 120, 10, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 110, 100, 10, 10 ) color:color];
    [world addWorldBlock:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"up barelyMissed";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 100, 10, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 110, 120, 10, 10 ) color:color];
    [world addWorldBlock:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirUp outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"left barelyMissed";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 100, 10, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 80, 110, 10, 10 ) color:color];
    [world addWorldBlock:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirLeft outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"right barelyMissed";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 100, 10, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 120, 110, 10, 10 ) color:color];
    [world addWorldBlock:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirRight outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    
    
    logStr = @"down wideBlockHit";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 9 * ONE_BLOCK_SIZE_Emu, 2 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 14 * ONE_BLOCK_SIZE_Emu, 3 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = 4 * ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"up wideBlockHit";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 8 * ONE_BLOCK_SIZE_Emu, 2 * ONE_BLOCK_SIZE_Emu, 8 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 9 * ONE_BLOCK_SIZE_Emu, 11 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMake( 14 * ONE_BLOCK_SIZE_Emu, 15 * ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu, ONE_BLOCK_SIZE_Emu ) color:color];
    [world addWorldBlock:b];
    expected = 8 * ONE_BLOCK_SIZE_Emu;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirUp outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    
    
    
    logStr = @"down multiMiss";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 110, 110, 20, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 105, 105, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 132, 90, 10, 10 ) color:color];
    [world addWorldBlock:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"up multiMiss";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 110, 10, 20, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 105, 105, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 132, 90, 10, 10 ) color:color];
    [world addWorldBlock:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirUp outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    
    logStr = @"down edgeList basic miss";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 105, 100, 10, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 50, 80, 2, 2 ) color:color];
    [world addWorldBlock:b];
    [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:(&edgeList)];
    actual = [edgeList count];
    expected = 0;
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"down edgeList basic hit";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 105, 100, 10, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 105, 80, 2, 2 ) color:color];
    [world addWorldBlock:b];
    [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:(&edgeList)];
    actual = [edgeList count];
    expected = 1;
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"down edgeList basic multihit";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 105, 100, 10, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 105, 80, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 111, 80, 2, 2 ) color:color];
    [world addWorldBlock:b];
    [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:(&edgeList)];
    actual = [edgeList count];
    expected = 2;
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"down edgeList adv multihit1";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 100, 100, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 130, 80, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 135, 80, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 170, 80, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 190, 80, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 50, 100, 100 ) color:color];
    [world addWorldBlock:b];
    [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:(&edgeList)];
    actual = [edgeList count];
    expected = 4;
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"down edgeList adv multihit2";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 100, 100, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 130, 10, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 135, 20, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 170, 30, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 190, 20, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 30, 2, 2 ) color:color];
    [world addWorldBlock:b];
    [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:(&edgeList)];
    actual = [edgeList count];
    expected = 2;
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"up edgeList adv multihit2";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 500, 500, 100, 10 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 530, 520, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 535, 530, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 570, 540, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 590, 520, 2, 2 ) color:color];
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 600, 515, 2, 2 ) color:color];
    [world addWorldBlock:b];
    [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirUp outCollidingEdgeList:(&edgeList)];
    actual = [edgeList count];
    expected = 2;
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    
    logStr = @"basic remove down";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 100, 20, 20 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 40, 20, 20 ) color:color];
    [world addWorldBlock:b];
    [world removeWorldSO:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"basic remove up";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 100, 20, 20 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 150, 20, 20 ) color:color];
    [world addWorldBlock:b];
    [world removeWorldSO:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirUp outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    logStr = @"multistrip remove down";
    [world reset];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 500, 500, 5, 5 ) color:color];   testSubject = b;
    [world addWorldBlock:b];
    b = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl( 100, 40, 600, 20 ) color:color];
    [world addWorldBlock:b];
    [world removeWorldSO:b];
    expected = ERMaxDistance;
    actual = [world.elbowRoom getElbowRoomForSO:testSubject inDirection:ERDirDown outCollidingEdgeList:nil];
    [WorldTest logTestResultStr:logStr exp:expected act:actual pNumPassed:&numPassed pNumTotal:&numTotal];
    
    
    
    // all done
    NSString *str;
    str = [NSString stringWithFormat:@"Passed %d/%d.%@",
           numPassed, numTotal, (numPassed == numTotal ? @" Yippee!" : @" I am disappoint.") ];
    DebugOut( str );
    
    [world reset];
    
}




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// test worlds

+(void)addStandardWalls_forWorld:(World *)world
{
    EmuRect thisRect;
    UInt32 thisColor;
    TestBlock *thisBlock;
    
    // walls
    thisRect = EmuRectMakeFromFl(4, 40, 1016, 10 );
    thisColor = 0x00dd00;
    thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
    thisBlock.props.canMoveFreely = NO;
    thisBlock.props.affectedByGravity = NO;
    thisBlock.props.affectedByFriction = NO;
    [world addWorldBlock:thisBlock];
    
    thisRect = EmuRectMakeFromFl(4, 756, 1016, 10 );
    thisColor = 0x00dd00;
    thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
    thisBlock.props.canMoveFreely = NO;
    thisBlock.props.affectedByGravity = NO;
    thisBlock.props.affectedByFriction = NO;
    [world addWorldBlock:thisBlock];
    
    thisRect = EmuRectMakeFromFl(4, 50, 10, 706 );
    thisColor = 0x00dd00;
    thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
    thisBlock.props.canMoveFreely = NO;
    thisBlock.props.affectedByGravity = NO;
    thisBlock.props.affectedByFriction = NO;
    [world addWorldBlock:thisBlock];
    
    thisRect = EmuRectMakeFromFl( 1010, 50, 10, 706 );
    thisColor = 0x00dd00;
    thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
    thisBlock.props.canMoveFreely = NO;
    thisBlock.props.affectedByGravity = NO;
    thisBlock.props.affectedByFriction = NO;
    [world addWorldBlock:thisBlock];
    
}


+(void)loadTestWorld_helloWorld_forWorld:(World *)world
{
    EmuRect thisRect;
    UInt32 thisColor;
    TestBlock *thisBlock;
    
    [world.elbowRoom reset];
    
    for( int i = 0; i < 40; ++i )
    {
        thisRect = EmuRectMakeFromFl( i * 30 + 24, 680 - (i * 6), 20 * frand() + 5, 30 * frand() + 8 );
        thisColor = 0xff00ff;
        thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
        thisBlock.props.canMoveFreely = YES;
        thisBlock.props.affectedByGravity = NO;
        thisBlock.props.affectedByFriction = YES;
        
        thisBlock.props.initialVelocity = EmuPointMakeFromFl( frand() * 100 - 50, frand() * 20 - 10 );
        
        [world addWorldBlock:thisBlock];
    }
    
    [WorldTest addStandardWalls_forWorld:world];
    
    EmuPoint playerPos = EmuPointMakeFromFl( 480.0f, 650.f );
    [world initPlayerAt:playerPos];
    
}


+(void)loadTestWorld_dk_forWorld:(World *)world
{
    EmuRect thisRect;
    UInt32 thisColor;
    TestBlock *thisBlock;
    float x, y, w, h, vx, vy;
    
    [world.elbowRoom reset];
    
    [WorldTest addStandardWalls_forWorld:world];
    
    // more random walls
    for( float iy = 100.f; iy < 700.f; iy += 50.f )
    {
        x = frand() * 820.f + 50.f;
        y = iy;
        w = frand() * 100.f + 10.f;
        h = 5.f;
        
        thisRect = EmuRectMakeFromFl( x, y, w, h );
        thisColor = 0x0000ff;
        thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
        thisBlock.props.canMoveFreely = NO;
        thisBlock.props.affectedByGravity = NO;
        thisBlock.props.affectedByFriction = NO;
        
        [world addWorldBlock:thisBlock];
    }
    
    // falling blocks
    for( float iy = 100.f; iy < 700.f; iy += 30.f )
    {
        x = frand() * 820.f + 50.f;
        y = iy;
        w = frand() * 30.f + 10.f;
        h = frand() * 30.f + 10.f;
        
        thisRect = EmuRectMakeFromFl( x, y, w, h );
        thisColor = 0xff00ff;
        thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
        thisBlock.props.canMoveFreely = YES;
        thisBlock.props.affectedByGravity = YES;
        thisBlock.props.affectedByFriction = YES;
        thisBlock.props.initialVelocity = EmuPointMakeFromFl( 0, 0 );
        
        [world addWorldBlock:thisBlock];
    }
    
    // random floaters
    for( int i = 0; i < 10; ++i )
    {
        x = frand() * 820.f + 50.f;
        y = frand() * 730.f + 20.f;
        w = frand() * 30.f + 10.f;
        h = frand() * 30.f + 10.f;
        vx = frand() * 200.f - 100.f;
        vy = frand() * 200.f - 100.f;
        
        thisRect = EmuRectMakeFromFl( x, y, w, h );
        thisColor = 0xff4400;
        thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
        thisBlock.props.canMoveFreely = YES;
        thisBlock.props.affectedByGravity = NO;
        thisBlock.props.affectedByFriction = NO;
        thisBlock.props.bounceDampFactor = 1.0f;   // bouncy
        thisBlock.props.initialVelocity = EmuPointMakeFromFl( vx, vy );
        
        [world addWorldBlock:thisBlock];
    }
    
    EmuPoint playerPos = EmuPointMakeFromFl( frand() * 1000.f + 12.f, frand() * 700.f + 60.f );
    [world initPlayerAt:playerPos];
    
}


+(void)loadTestWorld_justPlayer_forWorld:(World *)world
{
    [world.elbowRoom reset];
    
    [WorldTest addStandardWalls_forWorld:world];
    
    EmuPoint playerPos = EmuPointMakeFromFl( frand() * 1000.f + 12.f, frand() * 700.f + 60.f );
    [world initPlayerAt:playerPos];
    
}


+(void)loadTestWorld_zenElements_forWorld:(World *)world
{
    EmuRect thisRect;
    UInt32 thisColor;
    TestBlock *thisBlock;
    
    [world.elbowRoom reset];
    
    [WorldTest addStandardWalls_forWorld:world];
    
    // one bouncy platform
    thisRect = EmuRectMakeFromFl( 200.f, 300.f, 400.f, 10.f );
    thisColor = 0xdddd22;
    thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
    thisBlock.props.canMoveFreely = YES;
    thisBlock.props.affectedByGravity = NO;
    thisBlock.props.affectedByFriction = NO;
    thisBlock.props.bounceDampFactor = 1.0f;   // bouncy
    thisBlock.props.initialVelocity = EmuPointMakeFromFl( 20, 0 );
    [world addWorldBlock:thisBlock];
    
    // one crate on floor
    thisRect = EmuRectMakeFromFl( 900.f, 100.f, 40.f, 40.f );
    thisColor = 0xff4400;
    thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
    thisBlock.props.canMoveFreely = YES;
    thisBlock.props.affectedByGravity = YES;
    thisBlock.props.affectedByFriction = YES;
    [world addWorldBlock:thisBlock];
    
    // one crate on platform
    thisRect = EmuRectMakeFromFl( 300.f, 311.f, 120.f, 40.f );
    thisColor = 0xff4400;
    thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
    thisBlock.props.canMoveFreely = YES;
    thisBlock.props.affectedByGravity = YES;
    thisBlock.props.affectedByFriction = YES;
    [world addWorldBlock:thisBlock];
    
    EmuPoint playerPos = EmuPointMakeFromFl( 480.0f, 650.f );
    [world initPlayerAt:playerPos];
    
}


+(void)loadTestWorld_zen2_forWorld:(World *)world
{
    EmuRect thisRect;
    UInt32 thisColor;
    TestBlock *thisBlock;
    
    [world.elbowRoom reset];
    
    [WorldTest addStandardWalls_forWorld:world];
    
    float x;
    float y = 150.f;
    
    for( int i = 0; i < 4; ++i )
    {
        // bouncy platform
        x = frand() * 400.f + 300.f;
        thisRect = EmuRectMakeFromFl( x, y, 300.f, 10.f );
        thisColor = 0xdddd22;
        thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
        thisBlock.props.canMoveFreely = YES;
        thisBlock.props.affectedByGravity = NO;
        thisBlock.props.affectedByFriction = NO;
        thisBlock.props.bounceDampFactor = 1.0f;   // bouncy
        thisBlock.props.initialVelocity = EmuPointMakeFromFl( 100, 0 );
        [world addWorldBlock:thisBlock];
        
        // one crate on platform
        x += frand() * 260.f - 30.f;
        thisRect = EmuRectMakeFromFl( x, y + 10.f, frand() * 80.f + 40.f, 40.f );
        thisColor = 0xff4400;
        thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
        thisBlock.props.canMoveFreely = YES;
        thisBlock.props.affectedByGravity = YES;
        thisBlock.props.affectedByFriction = YES;
        [world addWorldBlock:thisBlock];
        
        y+= 135.f;
        
    }
    
    EmuPoint playerPos = EmuPointMakeFromFl( 480.0f, 650.f );
    [world initPlayerAt:playerPos];
    
}


+(void)loadTestWorld_runUp_forWorld:(World *)world
{
    EmuRect thisRect;
    UInt32 thisColor;
    TestBlock *thisBlock;
    
    [world.elbowRoom reset];
    
    [WorldTest addStandardWalls_forWorld:world];
    
    float xPixel = [AspectController instance].xPixel;
    //float yPixel = [AspectController instance].yPixel;
    
    const float numDuders = 18.f;
    const float yGrowth = 650.f;
    
    float x, y, w, h;
    x = 0.f;
    y = 0.f;
    w = xPixel / numDuders;
    h = 30.f;
    
    for( int i = 0; i < numDuders; ++i )
    {
        thisRect = EmuRectMakeFromFl( x, y, w, h );
        thisColor = 0x44ff44;
        thisBlock = [[TestBlock alloc] initWithRect:thisRect color:thisColor];        
        thisBlock.props.canMoveFreely = NO;
        thisBlock.props.affectedByGravity = NO;
        thisBlock.props.affectedByFriction = NO;
        [world addWorldBlock:thisBlock];
        
        x += w;
        h += (yGrowth / numDuders);    
    }
    
    EmuPoint playerPos = EmuPointMakeFromFl( 480.0f, 650.f );
    [world initPlayerAt:playerPos];
    
}


// compressed miniature block-adder Deluxe
+(void)cmbadx:(Emu)x y:(Emu)y w:(Emu)w h:(Emu)h c:(UInt32)c m:(BOOL)m g:(BOOL)g v:(EmuPoint)v bdf:(float)bdf forWorld:(World *)world
{
    
    Block *thisBlock;
    thisBlock = [[TestBlock alloc] initWithRect:EmuRectMakeFromFl(x, y, w, h ) color:c];        
    thisBlock.props.canMoveFreely = m;
    thisBlock.props.affectedByGravity = g;
    thisBlock.props.affectedByFriction = NO;
    thisBlock.props.bounceDampFactor = bdf;    
    thisBlock.props.initialVelocity = v;
    
    [world addWorldBlock:thisBlock];
}
+(void)cmbadx:(Emu)x y:(Emu)y w:(Emu)w h:(Emu)h c:(UInt32)c m:(BOOL)m g:(BOOL)g forWorld:(World *)world
{
    [self cmbadx:x y:y w:w h:h c:c m:m g:g v:EmuPointMakeFromFl( 0.f, 0.f ) bdf:0.f forWorld:world];
}



+(void)loadTestWorld_particleContainment_forWorld:(World *)world
{
    // this world is a JustPlayer world with an additional high-frequency particle containment system.
    
    [world.elbowRoom reset];
    
    [WorldTest addStandardWalls_forWorld:world];
    
    EmuPoint playerPos = EmuPointMakeFromFl( frand() * 1000.f + 12.f, frand() * 700.f + 60.f );  // could spawn inside the containment chamber, poor soul.
    [world initPlayerAt:playerPos];
    
    
    const float wallDim = 12.f;
    const UInt32 wallColor = 0xd000dd;
    
    const float xBox = 300.f;
    const float yBox = 460.f;
    const float wBox = 400.f;
    const float hBox = 756.f - 60.f - yBox - wallDim;
    
    float x, y, w, h;
    
    // containment system walls
    x = xBox; y = yBox; w = wBox; h = wallDim;
    [WorldTest cmbadx:x y:y w:w h:h c:wallColor m:NO g:NO forWorld:world];
    
    y = yBox + hBox;
    [WorldTest cmbadx:x y:y w:w h:h c:wallColor m:NO g:NO forWorld:world];
    
    y = yBox + wallDim; w = wallDim; h = hBox - wallDim;
    [WorldTest cmbadx:x y:y w:w h:h c:wallColor m:NO g:NO forWorld:world];
    
    x = xBox + wBox - wallDim;
    [WorldTest cmbadx:x y:y w:w h:h c:wallColor m:NO g:NO forWorld:world];
    
    
    // high-frequency particles
    const float partiDim = 8.f;
    const float partiSpeed = 200.f;
    const UInt32 partiColor = 0xffaa00;

    
    // I set this at 100 for profiling purposes.
    //const int numPartis = 100;
    const int numPartis = 50;
    
    
    float partiTheta;
    EmuPoint partiV;
    float thisPartiSpeed = frand() * partiSpeed + partiSpeed;
    x = xBox + (wBox / 2.f);
    y = yBox + (hBox / 2.f);
    for( int i = 0; i < numPartis; ++i )
    {
        partiTheta = frand() * 360.f;
        partiV = EmuPointMakeFromFl( thisPartiSpeed * cosf( partiTheta ), thisPartiSpeed * sinf( partiTheta ) );
        [WorldTest cmbadx:x y:y w:partiDim h:partiDim c:partiColor m:YES g:NO v:partiV bdf:1.f forWorld:world];
    }
    
}

#define ROR( min, max ) (frand() * ((max)-(min)) + min)

+(void)loadTestWorld_zen3_forWorld:(World *)world
{
    [world.elbowRoom reset];
    
    [WorldTest addStandardWalls_forWorld:world];
    
    EmuPoint playerPos = EmuPointMakeFromFl( frand() * 1000.f + 12.f, frand() * 700.f + 60.f );
    [world initPlayerAt:playerPos];

    
    for( int i = 0; i < 20; ++i )
    {
        [self cmbadx:ROR( 20.f, 1000.f ) y:ROR( 20.f, 740.f ) w:ROR( 80.f, 260.f) h:6.f c:0x0022ff m:NO g:NO forWorld:world];
        
    }
    
}


+(void)loadTestWorld_zen4_forWorld:(World *)world
{
    [world.elbowRoom reset];
    
    [WorldTest addStandardWalls_forWorld:world];
    
    EmuPoint playerPos = EmuPointMakeFromFl( frand() * 1000.f + 12.f, frand() * 700.f + 60.f );
    [world initPlayerAt:playerPos];
    
    const float w = 120.f;
    const float gap = 120.f;
    const float ymin = 100.f;
    const float ymax = 700.f;
    
    for( float x = 45.f; YES; x += (w + gap) )
    {
        if( x + w > 1024.f )
            break;
        [self cmbadx:x y:ROR( ymin, ymax ) w:w h:90.f c:0x0022ff m:NO g:NO forWorld:world];
    }
}


+(void)generateMappedMaze:(unsigned char *)maze w:(int)w h:(int)h forWorld:(World *)world
{
    [world.elbowRoom reset];

    const float wCol = 45.f;
    const float hRow = 65.f;
    
    float xmin = (1024.f - (wCol * w) ) / 2.f;
    float ymin = (768.f - (hRow * h) ) / 2.f;
    
    for( int yloop = 0; yloop < h; ++yloop )
    {
        for( int xloop = 0; xloop < w; ++xloop )
        {
            unsigned char block = maze[(h - yloop - 1) * w + xloop];  // y index flipped
            float x = xmin + (xloop * wCol);
            float y = ymin + (yloop * hRow);
            if( block == 1 )  // basic test block
            {
                UInt32 color = 0xdddd00;
                if( yloop < h - 1 )
                {
                    unsigned char blockAbove = maze[(h - yloop - 2) * w + xloop];  // y index flipped
                    if(  blockAbove != 1 )
                    {
                        color = 0x00ee00;
                    }
                }
                else
                {
                    color = 0x00ff00;
                }
                [self cmbadx:x y:y w:wCol h:hRow c:color m:NO g:NO forWorld:world];
            }
            else if( block == 2 )  // horiz moving platform 1: right medium
            {
                y += 0.75f * hRow;
                EmuPoint v = EmuPointMakeFromFl( 50.f, 0.f );
                [self cmbadx:x y:y w:wCol h:(0.25f * hRow) c:0xff0044 m:YES g:NO v:v bdf:1.f forWorld:world];
            }
            else if( block == 3 )  // horiz moving platform 2: right slow
            {
                y += 0.75f * hRow;
                EmuPoint v = EmuPointMakeFromFl( 10.f, 0.f );
                [self cmbadx:x y:y w:wCol h:(0.25f * hRow) c:0xff0044 m:YES g:NO v:v bdf:1.f forWorld:world];
            }
            else if( block == 4 )  // player start position
            {                
                EmuPoint playerPos = EmuPointMakeFromFl( x, y );
                [world initPlayerAt:playerPos];
            }
            else if( block == 5 )  // horiz moving platform 3: left medium
            {
                y += 0.75f * hRow;
                EmuPoint v = EmuPointMakeFromFl( -50.f, 0.f );
                [self cmbadx:x y:y w:wCol h:(0.25f * hRow) c:0xff0044 m:YES g:NO v:v bdf:1.f forWorld:world];
            }
        }
    }
}


+(void)loadTestWorld_maze1_forWorld:(World *)world
{
    const int mazeWidth = 20;
    const int mazeHeight = 10;

    unsigned char maze[] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 
        0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 
        1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 
        1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 2, 0, 1, 0, 1, 
        1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 
        1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 
        1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 
    };

    [WorldTest generateMappedMaze:maze w:mazeWidth h:mazeHeight forWorld:world];
}


+(void)loadTestWorld_maze2_testDownPhasing_forWorld:(World *)world
{
    const int mazeWidth = 20;
    const int mazeHeight = 10;
    
    unsigned char maze[] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    };
    
    [WorldTest generateMappedMaze:maze w:mazeWidth h:mazeHeight forWorld:world];
}


+(void)loadTestWorld_maze3_platforms_forWorld:(World *)world
{
    const int mazeWidth = 20;
    const int mazeHeight = 10;
    
    unsigned char maze[] = {
        4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,  
        0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 1, 0, 
        0, 1, 0, 0, 0, 2, 0, 1, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, 
        0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 
        0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 0, 0, 0, 3, 0, 1, 0, 
        0, 1, 0, 2, 0, 0, 0, 1, 0, 1, 5, 0, 0, 0, 0, 0, 0, 0, 1, 0, 
        0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 3, 0, 0, 0, 0, 0, 0, 1, 0, 
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1,  
    };
    
    [WorldTest generateMappedMaze:maze w:mazeWidth h:mazeHeight forWorld:world];
}


+(void)loadTestWorld_maze4_testPlatformSticking_forWorld:(World *)world
{
    const int mazeWidth = 20;
    const int mazeHeight = 10;
    
    unsigned char maze[] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    };
    
    [WorldTest generateMappedMaze:maze w:mazeWidth h:mazeHeight forWorld:world];
}


+(void)loadTestWorld_velInheritProblemCase1_forWorld:(World *)world
{
    // test the problem case where I think I should inherit velocity from my downblock but the downblock
    //  is not actually moving.
    
    [world.elbowRoom reset];

    float x, y, w, h;
    EmuPoint v;

    // moving platform
    x = 200.f;
    y = 180.f;
    w = 300.f;
    h = 20.f;
    v = EmuPointMakeFromFl( 20.f, 0.f );
    [self cmbadx:x y:y w:w h:h c:0x0000ff m:YES g:NO v:v bdf:1.f forWorld:world];

    // stationary block
    x = 550.f;
    y = 215.f;
    w = 30.f;
    h = 30.f;
    v = EmuPointMakeFromFl( 0.f, 0.f );
    [self cmbadx:x y:y w:w h:h c:0x00ff00 m:NO g:NO v:v bdf:0.f forWorld:world];

    // crate
    x = 450.f;
    y = 200.f;
    w = 50.f;
    h = 50.f;
    v = EmuPointMakeFromFl( 0.f, 0.f );
   [self cmbadx:x y:y w:w h:h c:0xff0044 m:YES g:YES v:v bdf:1.f forWorld:world];

    // player
    EmuPoint playerPos = EmuPointMakeFromFl( 455.f, 250.f );
    [world initPlayerAt:playerPos];

}


+(void)loadHardcodedWorldToWorld:(World *)world nextWorld:(BOOL)fNext
{
    const int startingWorldNum = 12;
    const int worldNumMax = 13;
    
    static int worldNum = -1;
    if( worldNum == -1 )  // initial case
    {
        worldNum = startingWorldNum;
    }
    else
    {
        if( fNext )
        {
            ++worldNum;
            if( worldNum >= worldNumMax )
                worldNum = 0;
        }
    }

    NSString *dstr;
    switch( worldNum )
    {
        case 0:
            dstr = @"testhc_particle_containment";
            [WorldTest loadTestWorld_particleContainment_forWorld:world];
            break;
        case 1:
            dstr = @"testhc_just_player";
            [WorldTest loadTestWorld_justPlayer_forWorld:world];
            break;
        case 2:
            dstr = @"testhc_run_up";
            [WorldTest loadTestWorld_runUp_forWorld:world];
            break;
        case 3:
            dstr = @"testhc_zen1";
            [WorldTest loadTestWorld_zenElements_forWorld:world];
            break;
        case 4:
            dstr = @"testhc_zen2";
            [WorldTest loadTestWorld_zen2_forWorld:world];
            break;
        case 5:
            dstr = @"testhc_dk";
            [WorldTest loadTestWorld_dk_forWorld:world];
            break;
        case 6:
            dstr = @"testhc_zen3";
            [WorldTest loadTestWorld_zen3_forWorld:world];
            break;
        case 7:
            dstr = @"testhc_zen4";
            [WorldTest loadTestWorld_zen4_forWorld:world];
            break;
        case 8:
            dstr = @"testhc_m1";
            [WorldTest loadTestWorld_maze1_forWorld:world];
            break;
        case 9:
            dstr = @"testhc_m2_testDown";
            [WorldTest loadTestWorld_maze2_testDownPhasing_forWorld:world];
            break;
        case 10:
            dstr = @"testhc_m3_plat";
            [WorldTest loadTestWorld_maze3_platforms_forWorld:world];
            break;
        case 11:
            dstr = @"testhc_m4_testSticky";
            [WorldTest loadTestWorld_maze4_testPlatformSticking_forWorld:world];
            break;
        case 12:
            dstr = @"testhc_velInheritTest";
            [WorldTest loadTestWorld_velInheritProblemCase1_forWorld:world];
            break;
            
        default:
            dstr = @"testhc_unknown_index";
            [WorldTest loadTestWorld_justPlayer_forWorld:world];
            break;
    }
    
    world.levelName = dstr;
    world.levelDescription = @"misc hardcoded testBlock world.";

    NSString *output = [NSString stringWithFormat:@"showing hard-coded world: %@.", dstr];
    DebugOut( output );
}


// sprite-mapped maze symbols. eventually you plug in disk storage here. good luck. have a great day.
#define SM___  0
#define SMXXX  1
#define SMVVV  2
#define SM_X_  3
#define SMRRR  4
#define SM_O_  5
#define SM_G1  6
#define SM_G2  7

// compressed miniature block-adder Deluxe, Sprite edition
+(Block *)cmbads:(Emu)x y:(Emu)y w:(Emu)w h:(Emu)h sn:(NSString *)sn m:(BOOL)m g:(BOOL)g v:(EmuPoint)v bdf:(float)bdf fr:(BOOL)fr forWorld:(World *)world
{
    Block *thisBlock;
    SpriteStateMap *spriteStateMap = [[[SpriteStateMap alloc] initWithSize:CGSizeMake( 1.f, 1.f )] autorelease];
    thisBlock = [[[SpriteBlock alloc] initWithRect:EmuRectMake(x, y, w, h ) spriteStateMap:spriteStateMap] autorelease];
    
    thisBlock.props.canMoveFreely = m;
    thisBlock.props.affectedByGravity = g;
    thisBlock.props.affectedByFriction = fr;
    thisBlock.props.bounceDampFactor = bdf;    
    thisBlock.props.initialVelocity = v;
    
    [world addWorldBlock:thisBlock];
    return thisBlock;
}
+(Block *)cmbads:(Emu)x y:(Emu)y w:(Emu)w h:(Emu)h sn:(NSString *)sn m:(BOOL)m g:(BOOL)g forWorld:(World *)world
{
    return [self cmbads:x y:y w:w h:h sn:sn m:m g:g v:EmuPointMake( 0.f, 0.f ) bdf:0.f fr:NO forWorld:world];
}


+(void)generateSpriteMappedMaze:(unsigned char *)maze w:(int)w h:(int)h forWorld:(World *)world
{
    [world.elbowRoom reset];
    
    NSAssert( PLAYER_WIDTH == PLAYER_HEIGHT / 2.f, @"generateSpriteMappedMaze assumes player is 1x2 blocks." );
    const Emu wCol = PLAYER_WIDTH;
    const Emu hRow = PLAYER_WIDTH;

    for( int yloop = 0; yloop < h; ++yloop )
    {
        for( int xloop = 0; xloop < w; ++xloop )
        {
            unsigned char block = maze[(h - yloop - 1) * w + xloop];  // y index flipped
            Emu x = (xloop * wCol);
            Emu y = (yloop * hRow);
            if( block == SMXXX )  // basic test block
            {
                [self cmbads:x y:y w:wCol h:hRow sn:@"bl_clown" m:NO g:NO forWorld:world];
            }
            else if( block == SMVVV )  // basic test block
            {
                [self cmbads:x y:y w:wCol h:hRow sn:@"bl_clown" m:NO g:NO forWorld:world];
            }
            else if( block == SMRRR )  // horiz moving platform 1: right medium
            {
                [self cmbads:x y:(y + 0.75f * hRow) w:wCol h:(0.25f * hRow) sn:@"bl_ice" m:YES g:NO v:EmuPointMakeFromFl( 50.f, 0.f ) bdf:1.f fr:NO forWorld:world];
            }
            else if( block == SM_X_ )  // crate
            {
                [self cmbads:x y:y w:wCol h:hRow sn:@"bl_clown" m:YES g:YES v:EmuPointMakeFromFl( 0.f, 0.f ) bdf:0.f fr:YES forWorld:world];
            }
            else if( block == SM_O_ )  // player start position
            {
                EmuPoint playerPos = EmuPointMake( x, y );
                [world initPlayerAt:playerPos];
            }
            else if( block == SM_G1 || block == SM_G2 ) // test group block
            {
                const GroupId testGroupId = 0x101 + block;  // different groupIDs for different constants.
                NSString *spriteName;
                switch( block )
                {
                    case SM_G1: spriteName = @"bl_fancyCrate0"; break;
                    case SM_G2: spriteName = @"bl_clown"; break;
                    default:  spriteName = @"bl_clown"; break;
                }
                
                BlockGroup *testGroup = [world ensureGroupForId:testGroupId];
                Block *testGroupBlock = [self cmbads:x y:y w:wCol h:hRow sn:spriteName m:YES g:YES v:EmuPointMakeFromFl( 0.f, 0.f ) bdf:0.f fr:YES forWorld:world];
                [world addBlock:testGroupBlock toGroup:testGroup];
            }
            else if( block == SM___ )  // blank
            {
            }
            else
            {
                NSLog( @"unknown block type %d.", block );
            }
        }
    }

}


const int mazeWidth0 = 8;
const int mazeHeight0 = 8;
static unsigned char mazedat0[] = {
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM_O_,SM___,SM_X_,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SMVVV,SM___,SM___,SM___,SM___,SMRRR,SM___,SMVVV,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SM___,
    SMXXX,SM___,SMXXX,SMXXX,SM___,SM___,SM___,SM___,
    SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,
};

const int mazeWidth1 = 24;
const int mazeHeight1 = 24;
static unsigned char mazedat1[] = {
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SMVVV,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,
    SMXXX,SMRRR,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM_O_,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SMRRR,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SMRRR,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,
    SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,SM___,SMXXX,SM___,
    SM___,SMXXX,SM___,SM___,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SM___,SM___,SMVVV,SM___,SM___,SM___,SM___,SMVVV,SMXXX,SM___,SM___,SM___,SMXXX,SM___,
    SM___,SMXXX,SM___,SM___,SM___,SM___,SMXXX,SMXXX,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,
    SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SMVVV,SMXXX,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,
    SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SMXXX,SMXXX,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,    
    SMVVV,SMXXX,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMXXX,SMVVV,SMVVV,SMVVV,SMXXX,SM___,SMXXX,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMXXX,SMVVV,
};

const int mazeWidth2 = 24;
const int mazeHeight2 = 24;
static unsigned char mazedat2[] = {
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMRRR,SM___,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM_O_,SM___,SM___,SM_X_,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SMXXX,SMXXX,SMXXX,SMXXX,SMXXX,SM___,SM___,SM___,SM___,SMVVV,SMRRR,SM___,SM___,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMRRR,SM___,SM___,SM___,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMVVV,SMVVV,SMXXX,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMVVV,SMVVV,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMVVV,SM___,SM___,SM___,SM_X_,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,
    SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,
    SM___,SM___,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,
    SM___,SM___,SM___,SM___,SMXXX,SMXXX,SMXXX,SMXXX,SMXXX,SMXXX,SMXXX,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMVVV,SMVVV,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,

};

const int mazeWidthBlank = 24;
const int mazeHeightBlank = 24;
static unsigned char mazedatBlank[] = {
    SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM_O_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,
    
    
};

const int mazeWidth3 = 24;
const int mazeHeight3 = 24;
static unsigned char mazedat3[] = {
    SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,SMVVV,SMVVV,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM_X_,SM___,SM___,SM___,SM_X_,SMVVV,SM_X_,SM___,SMVVV,SM___,SMVVV,SM___,SMXXX,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM_X_,SM___,SM___,SM___,SMVVV,SM___,SMVVV,SM___,SMXXX,SMVVV,SMXXX,SM___,SMXXX,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SMVVV,SMVVV,SMVVV,SM___,SMXXX,SMVVV,SMXXX,SM___,SMXXX,SM___,SMXXX,SM___,SMXXX,SMVVV,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM___,SM___,
    SM___,SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM_X_,SM_X_,SM___,
    SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM_X_,SM_X_,SM___,
    SM___,SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM_X_,SM_X_,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMVVV,SMVVV,SM___,SMVVV,SM_X_,SM_X_,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SM_X_,SMVVV,SM_X_,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,SMVVV,SM___,SM___,SMXXX,SM___,SM___,SM___,SM___,SM_X_,SM_X_,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMXXX,SMVVV,SMXXX,SMVVV,SM___,SMXXX,SMVVV,SM___,SM___,SMVVV,SM_X_,SMVVV,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SMXXX,SM___,SMXXX,SM___,SMXXX,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SMXXX,SM___,SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM_X_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMXXX,SM___,SM___,SM___,SMXXX,SM___,SMXXX,SMVVV,SMVVV,SM___,SM___,SM___,SM___,SM___,
    SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM_X_,SM_X_,SM___,
    SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM_X_,SM_X_,SM___,
    SMXXX,SM___,SM___,SM_O_,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_X_,SM_X_,SMVVV,SM___,
    SMXXX,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMXXX,SMVVV,
    
    
};


const int mazeWidth4 = 16;
const int mazeHeight4 = 16;
static unsigned char mazedat4[] = {

    
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM_G1,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,SM___,SM___,SM___,
    SM___,SM_G1,SM_G1,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,
    SM___,SM___,SM_G1,SM_G1,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,
    SM___,SM___,SM_G1,SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SMRRR,SM___,SM___,SM___,SM_G2,SM_G2,SM_G2,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM_G2,SM_G2,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM_G2,SM_G2,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,SM___,SM___,SM_O_,SM___,
    SM___,SM___,SM___,SM___,SM___,SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMVVV,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMXXX,SMXXX,
    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SMVVV,SMXXX,SMXXX,SMXXX,
    SM___,SM___,SM___,SMVVV,SMVVV,SMVVV,SM___,SM___,SM___,SMVVV,SMVVV,SMVVV,SMXXX,SMXXX,SMXXX,SMXXX,
    
    
    
//    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
//    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
//    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,
//    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_G2,SM_G2,SM_G2,SM_G2,SM___,SM___,SM___,SM___,
//    SM___,SM___,SM___,SM___,SM___,SM_G2,SM_G2,SM_G2,SM_G2,SM___,SM___,SM_G2,SM_G2,SM___,SM___,SM___,
//    SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SMVVV,SM___,SM___,
//    SM___,SM___,SM_G1,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SMXXX,SM___,SM___,
//    SMVVV,SM___,SM_G1,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SM___,SM___,SM___,
//    SMXXX,SM___,SM_G1,SM_G1,SM_G1,SM_G1,SM___,SM___,SM___,SM___,SM_G2,SM_G2,SM___,SM___,SM___,SM___,
//    SMXXX,SM___,SM_G1,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SM___,SMVVV,SM___,SM___,
//    SMXXX,SM_G1,SM_G1,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SM___,SM___,SM___,SMVVV,
//    SM___,SM_G1,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SM___,SM___,SM___,SM___,
//    SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SM___,SM___,SM___,SM___,
//    SMVVV,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_G2,SM___,SM___,SM___,SM___,SM___,
//    SMXXX,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM___,SM_O_,SM___,
//    SMXXX,SMVVV,SMVVV,SMVVV,SM___,SM___,SMVVV,SMVVV,SMVVV,SMVVV,SM___,SM___,SMVVV,SMVVV,SMVVV,SMVVV,
};

//const int mazeWidth4 = 6;
//const int mazeHeight4 = 12;
//static unsigned char mazedat4[] = {
//    SM___,SM___,SM___,SM___,SM___,SM___,
//    SM_O_,SM___,SM___,SM___,SM___,SM___,
//    SMVVV,SM_G2,SM_G2,SM_G2,SM_G2,SM_G2,
//    SM___,SM___,SM___,SM___,SM___,SM_G2,
//    SM___,SM___,SM___,SM___,SM___,SM_G2,
//    SMVVV,SM___,SM___,SM_G2,SM_G2,SM_G2,
//    SM___,SM___,SM___,SM_G2,SM___,SM___,
//    SM___,SM___,SM___,SM___,SM___,SM___,
//    SM___,SM___,SM___,SM_G1,SM___,SM___,
//    SM___,SM___,SM___,SM___,SM___,SM___,
//    SM___,SM___,SM___,SM___,SM___,SM___,
//    SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,SMVVV,
//    
//};


const int mazeWidth5_basic = 3;
const int mazeHeight5_basic = 3;
static unsigned char mazedat5_basic[] = {
    SM___,SM___,SM___,
    SM___,SM_O_,SM___,
    SM___,SMVVV,SM___,
};






// test case for a known phase repro
+(void)generateCratePhaseTestForWorld:(World *)world
{
    [world.elbowRoom reset];
    
    const float wCol = PLAYER_WIDTH;
    const float hRow = PLAYER_WIDTH;

    float x, y;

    x = 224.f;
    y = 672.f;
    [self cmbads:x y:y w:wCol h:hRow sn:@"bl_clown" m:NO g:NO forWorld:world];
    x = 272.f;
    y = 672.f;
    [self cmbads:x y:y w:wCol h:hRow sn:@"bl_clown" m:NO g:NO forWorld:world];
    
    
    x = 272.f;
    y = 720.f;
    [self cmbads:x y:y w:wCol h:hRow sn:@"bl_clown" m:YES g:YES v:EmuPointMakeFromFl( 0.f, 0.f ) bdf:0.f fr:YES forWorld:world];

    x = 224.f;
    y = 720;
    EmuPoint playerPos = EmuPointMakeFromFl( x, y );
    [world initPlayerAt:playerPos];
}




+(void)loadMappedSpriteWorldForWorld:(World *)world nextWorld:(BOOL)fNext
{
    const int startingWorldNum = 6;
    const int worldNumMax = 8;
    
    static int worldNum = -1;
    if( worldNum == -1 )  // initial case
    {
        worldNum = startingWorldNum;
    }
    else
    {
        if( fNext )
        {
            ++worldNum;
            if( worldNum >= worldNumMax )
                worldNum = 0;
        }
    }
    
    switch( worldNum )
    {
        case 0:
            [WorldTest generateSpriteMappedMaze:mazedatBlank w:mazeWidthBlank h:mazeHeightBlank forWorld:world];
            world.levelName = @"test_spriteMapped0";
            world.levelDescription = @"blank sprite map.";
            break;
        case 1:
            [WorldTest generateSpriteMappedMaze:mazedat0 w:mazeWidth0 h:mazeHeight0 forWorld:world];
            world.levelName = @"test_spriteMapped1";
            world.levelDescription = @"tiny sprite map.";
            break;
        case 2:
            [WorldTest generateSpriteMappedMaze:mazedat1 w:mazeWidth1 h:mazeHeight1 forWorld:world];
            world.levelName = @"test_spriteMapped2";
            world.levelDescription = @"the first sprite map you made, woohoo.";
            break;
        case 3:
            [WorldTest generateSpriteMappedMaze:mazedat2 w:mazeWidth2 h:mazeHeight2 forWorld:world];
            world.levelName = @"test_spriteMapped3";
            world.levelDescription = @"ye olde crate test sprite map.";
            break;
        case 4:
            [WorldTest generateSpriteMappedMaze:mazedat3 w:mazeWidth3 h:mazeHeight3 forWorld:world];
            world.levelName = @"test_spriteMapped4";
            world.levelDescription = @"LOAD ME!!! sprite map.";
            break;
        case 5:
            [WorldTest generateCratePhaseTestForWorld:world];
            world.levelName = @"test_cratePhaseTest";
            world.levelDescription = @"Isolating the crate phase repro from spriteMapped3";
            break;
        case 6:
            [WorldTest generateSpriteMappedMaze:mazedat4 w:mazeWidth4 h:mazeHeight4 forWorld:world];
            world.levelName = @"test_testGroupsBasic";
            world.levelDescription = @"I like testing new functionality, such as groups in this case.";
            break;
        case 7:
            [WorldTest generateSpriteMappedMaze:mazedat5_basic w:mazeWidth5_basic h:mazeHeight5_basic forWorld:world];
            world.levelName = @"test_testBasicSanityTest";
            world.levelDescription = @"A very simple test world for basic sanity checks.";
            break;
            
        default:
            NSLog( @"invalid spriteMappedMaze number." );
            break;
    }
    
}


+(NSArray *)getOnDiskLevelList
{
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:50];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    for( int i = 0; i < [allFiles count]; ++i )
    {
        NSString *thisPath = (NSString *)[allFiles objectAtIndex:i];
        if( [thisPath hasSuffix:@".jlevel"] )
        {
            NSString *thisName = [[thisPath lastPathComponent] stringByDeletingPathExtension];
            [resultArray addObject:thisName];
        }
    }
    return resultArray;
}

static int levelListIndex = -1;

+(void)loadWorldFromDisk:(World *)world nextWorld:(BOOL)fNext
{
    const int startingLevelListIndex = 0;

    NSArray *levelNameList = [WorldTest getOnDiskLevelList];
//    for( int i = 0; i < [levelNameList count]; ++i )
//    {
//        NSLog( @"I see a level name: %@", (NSString *)[levelNameList objectAtIndex:i] );
//    }

    if( levelListIndex == -1 )  // initial case
    {
        levelListIndex = startingLevelListIndex;
    }
    else
    {
        if( fNext )
        {
            ++levelListIndex;
            if( levelListIndex >= [levelNameList count] )
                levelListIndex = 0;
        }
    }
    
    NSString *levelName = (NSString *)[levelNameList objectAtIndex:levelListIndex];
    [WorldArchiveUtil loadWorld:world fromDiskForName:levelName];
}


+(void)deleteAllLevelsOnDisk
{
#if 0
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    for( int i = 0; i < [allFiles count]; ++i )
    {
        NSString *thisPath = (NSString *)[allFiles objectAtIndex:i];
        thisPath = [documentsDirectory stringByAppendingPathComponent:thisPath];
        if( ![fileManager removeItemAtPath:thisPath error:NULL] )
        {
            NSLog( @"WorldTest deleteAllWorldsOnDisk: failed to delete %@!!", thisPath );
        }
    }
#else
    NSLog( @"don't do this. and if you must, the above code will delete everything, not just jlevels." );
#endif
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+(void)loadTestWorldTo:(World *)world loadFromDisk:(BOOL)fromDisk nextWorld:(BOOL)next
{
    if( fromDisk )
    {
        [WorldTest loadWorldFromDisk:world nextWorld:next];
    }
    else
    {
        //[WorldTest deleteAllLevelsOnDisk];
        
        //[WorldTest loadHardcodedWorldToWorld:world nextWorld:next];
        [WorldTest loadMappedSpriteWorldForWorld:world nextWorld:next];
        
        //[WorldArchiveUtil saveToDisk:world];
    }
}


+(void)loadTestWorldTo:(World *)world loadFromDisk:(BOOL)fromDisk startingWith:(NSString *)preferredStartingWorld
{
    int initialIndex = 0;
    NSArray *levelNameList = [WorldTest getOnDiskLevelList];
    for( int i = 0; i < [levelNameList count]; ++i )
    {
        NSString *thisLevelName = (NSString *)[levelNameList objectAtIndex:i];
        if( [thisLevelName isEqualToString:preferredStartingWorld] )
        {
            initialIndex = i;
            break;
        }
    }
    
    // set static index to the match we found.
    // potential bug: this assumes that getOnDiskLevelList returns the same order each time.
    levelListIndex = initialIndex;
    
    [self loadTestWorldTo:world loadFromDisk:fromDisk nextWorld:NO];
}

@end
