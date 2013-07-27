//
//  ElbowRoom.m
//  JumpProto
//
//  Created by gideong on 7/24/11.
//  Copyright 2011 GoodGuyApps. All rights reserved.
//

#import "ElbowRoom.h"
#import "DebugLogLayerView.h"
#import "gutil.h"
#import "BlockGroup.h"

//#define DEBUG_ER

#define ROUND_TO_STRIP(val) ((val)-((val)%m_stripSize))    

////////////////////////////////////////////////////////////////////////////////////////////////////////////////// EREdge

@implementation EREdge

@synthesize majorVal = m_majorVal, minorLowVal = m_minorLowVal, minorHighVal = m_minorHighVal, block = m_block;
@synthesize cacheIndex = m_cacheIndex, containingCache = m_containingCache, dir = m_dir;


-(NSComparisonResult)compare:(EREdge *)other
{
#ifdef LOG_ER_STATS
    [[ERStats instance] inc_edgeCompare];
#endif

    if( m_majorVal < other.majorVal )
    {
        return NSOrderedAscending;  // this should be earlier than other
    }
    else if ( m_majorVal > other.majorVal)
    {
        return NSOrderedDescending;
    }
    // else same majorVal
    	
    // ignore minorvalues
    return NSOrderedSame;
}


-(NSComparisonResult)compareStrict:(EREdge *)other
{
#ifdef LOG_ER_STATS
    [[ERStats instance] inc_edgeCompare];
#endif
    
    if( m_majorVal < other.majorVal )
    {
        return NSOrderedAscending;  // this should be earlier than other
    }
    else if ( m_majorVal > other.majorVal)
    {
        return NSOrderedDescending;
    }
    // else same majorVal
    
    if( m_minorLowVal < other.minorLowVal )
    {
        return NSOrderedAscending;
    }
    else if( m_minorLowVal > other.minorLowVal )
    {
        return NSOrderedDescending;
    }
    // else same minorLowVal
    
    if( m_minorHighVal < other.minorHighVal )
    {
        return NSOrderedAscending;
    }
    else if( m_minorHighVal > other.minorHighVal )
    {
        return NSOrderedDescending;
    }
    
    // all the same
    return NSOrderedSame;
}


-(BOOL)equals:(EREdge *)other
{
#ifdef LOG_ER_STATS
    [[ERStats instance] inc_edgeEquality];
#endif
    return m_majorVal == other.majorVal && m_minorLowVal == other.minorLowVal && m_minorHighVal == other.minorHighVal;
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////// ERSortedEdgeCache

@implementation ERSortedEdgeCache

-(id)init
{
    if( self = [super init] )
    {
        m_sortedCache = [[NSMutableArray arrayWithCapacity:32] retain];
        
        m_workingEdgeList = [[NSMutableArray arrayWithCapacity:32] retain];
    }
    return self;
}


-(void)dealloc
{
    [m_workingEdgeList release]; m_workingEdgeList = nil;
    [m_sortedCache release]; m_sortedCache = nil;
    [super dealloc];
}


// bubble sort. can do better.
// this version goes backwards in anticipation of levels being populated top-down
-(int)getInsertPoint_bubbleSort:(EREdge *)edge
{
    const int count = [m_sortedCache count];
    int insertPoint = count;
    while( YES )
    {
        NSAssert( insertPoint >= 0 && insertPoint <= count, @"bad insert point." );
        
        if( insertPoint == 0 )
        {
            return 0;
        }
        
        EREdge *nextSlotDown = (EREdge *)[m_sortedCache objectAtIndex:(insertPoint - 1)];
        if( [edge compare:nextSlotDown] == NSOrderedAscending )
        {
            --insertPoint;
            continue;
        }
        return insertPoint;
    }
}


// binary version
-(int)getInsertPoint_binarySort:(EREdge *)edge
{
    const int count = [m_sortedCache count];
    float insertPointF = count / 2.f;
    float nextStep = count / 4.f;
    
    const int bailoutMax = 20;
    int bailout = 0;
    
    while( ++bailout < bailoutMax )
    {
        int insertPoint = (int)roundf( insertPointF );
        
        NSAssert( insertPoint >= 0 && insertPoint <= count, @"bad insert point." );

        NSComparisonResult lowerComparison;
        NSComparisonResult higherComparison;
        if( insertPoint == 0 )
        {
            lowerComparison = NSOrderedDescending;            
        }
        else
        {
            EREdge *lowerEdge  = (EREdge *)[m_sortedCache objectAtIndex:(insertPoint - 1)];
            lowerComparison  = [edge compare:lowerEdge];
        }
        
        if( insertPoint >= count )
        {
            higherComparison = NSOrderedAscending;
        }
        else
        {
            EREdge *higherEdge = (EREdge *)[m_sortedCache objectAtIndex:(insertPoint)];
            higherComparison = [edge compare:higherEdge];
        }
        
        // (lowerComparison == NSOrderedSame) check because insertPoint should point past any existing edges equal to input.
        BOOL done = (lowerComparison  == NSOrderedDescending || lowerComparison == NSOrderedSame ) &&
                     higherComparison == NSOrderedAscending;
        if( done )
        {
#if 0
            // test: check result against bubble sort
            int checkValue = [self getInsertPoint_bubbleSort:edge];
            if( insertPoint != checkValue )
            {
                NSLog( @"binary: disagree with bubble!!!!!!! my ip is %d, bubble's is %d.", insertPoint, checkValue );
            }
#endif
            
            //NSLog( @"binary: success. ip=%d, count=%d.", insertPoint, count );
            
            return insertPoint;
        }

        if( lowerComparison == NSOrderedAscending )
        {
            // insert point is too high, need to lower it.
            insertPointF -= nextStep;            
        }
        else
        {
            // insert point is too low, need to raise it.
            insertPointF += nextStep;
        }
        nextStep = nextStep / 2.f;
    }
    if( bailout >= bailoutMax )
    {
        NSString *debugString = [NSString stringWithFormat:@"binary sort: bailed out. ipf=%f, step=%f.", insertPointF, nextStep];
        NSAssert( NO, debugString );
    }
    NSAssert( bailout < bailoutMax, @"binary sort: bailout." );
    return (int)roundf( insertPointF );  // best guess
}


// a modified version of bubble sort that accepts a hint for the starting point.
//  the hint may be high or low, so this sort needs to be able to bubble up or down.
//  if there's no hint (e.g. the add case), just start at the top and bubble down.
-(int)getInsertPoint_bubbleSort:(EREdge *)edge withHint:(int *)hint
{
    const int count = [m_sortedCache count];
    int insertPoint = (hint == nil) ? count : *hint;
    insertPoint = MAX( 0, MIN( count, insertPoint ) );

    // determine whether we need to bubble up or down
    BOOL bubbleUp = YES;
    if( insertPoint > 0 )
    {
        EREdge *nextSlotDown = (EREdge *)[m_sortedCache objectAtIndex:(insertPoint - 1)];
        if( [edge compare:nextSlotDown] == NSOrderedAscending )
        {
            bubbleUp = NO;
        }
    }
    
    while( YES )
    {
        NSAssert( insertPoint >= 0 && insertPoint <= count, @"bad insert point." );
    
        if( bubbleUp )
        {
            if( insertPoint == count )
            {
                break;
            }
            
            EREdge *nextSlotUp = (EREdge *)[m_sortedCache objectAtIndex:(insertPoint)];
            if( [edge compare:nextSlotUp] != NSOrderedAscending )
            {
                ++insertPoint;
                continue;
            }
            break;
        }
        else
        {
            if( insertPoint == 0 )
            {
                break;
            }
            
            EREdge *nextSlotDown = (EREdge *)[m_sortedCache objectAtIndex:(insertPoint - 1)];
            if( [edge compare:nextSlotDown] == NSOrderedAscending )
            {
                --insertPoint;
                continue;
            }
            break;
        }
    }
    if( hint != nil )
    {
        //NSLog( @"hint was %d, result was %d.", *hint, insertPoint );
        *hint = insertPoint;
    }
    
    return insertPoint;
}


-(int)getInsertPoint:(EREdge *)edge withSortHint:(int *)sortHint
{
    //return [self getInsertPoint_bubbleSort:edge];
    
    // this seems about equal or slower than bubble >:-{
    //  I'll leave the code here for posterity.
    //  there may be some cases where this is faster, like if count is really high.
    //return [self getInsertPoint_binarySort:edge];
    
    return [self getInsertPoint_bubbleSort:edge withHint:sortHint];
}


-(void)addEdge:(EREdge *)edge
{
#ifdef LOG_ER_STATS
    [[ERStats instance] inc_addEdge];
    [[ERStats instance] startTimer_addEdge];
#endif
    
    int insertPoint = [self getInsertPoint:edge withSortHint:nil];
    [m_sortedCache insertObject:edge atIndex:insertPoint];

#ifdef LOG_ER_STATS
    [[ERStats instance] stopTimer_addEdge];
#endif
    
    edge.containingCache = self;
    
    // update cacheIndex field for all edges that need it
    for( int i = insertPoint; i < [m_sortedCache count]; ++i )
    {
        EREdge *thisEdge = (EREdge *)[m_sortedCache objectAtIndex:i];
        thisEdge.cacheIndex = i;
    }
}


-(void)removeEdge:(EREdge *)edge
{
    NSAssert( edge.containingCache == self, @"tried to remove edge from wrong cache?" );

#ifdef LOG_ER_STATS
    [[ERStats instance] inc_removeEdge];
#endif
    
    int removeIndex = edge.cacheIndex;
    [m_sortedCache removeObjectAtIndex:removeIndex];
    edge.cacheIndex = -1;
    edge.containingCache = nil;
    
    // update cacheIndex field for all edges that need it
    for( int i = removeIndex; i < [m_sortedCache count]; ++i )
    {
        EREdge *thisEdge = (EREdge *)[m_sortedCache objectAtIndex:i];
        thisEdge.cacheIndex = i;
    }
    
}


-(void)moveEdge:(EREdge *)edge toMajorVal:(Emu)majorVal
{
#ifdef LOG_ER_STATS
    [[ERStats instance] inc_moveEdge];
    [[ERStats instance] startTimer_moveEdge];
#endif

    int targetIndex = edge.cacheIndex;
    if( majorVal < edge.majorVal )
    {
        // if we moved in a negative direction, our index can only be too big.
        if( edge.cacheIndex > 0 )
        {
            EREdge *testEdge;
            do
            {
                testEdge = (EREdge *)[m_sortedCache objectAtIndex:(targetIndex - 1)];
                if( testEdge.majorVal > majorVal )  // TODO: >=? depends on assumptions elsewhere in ER
                {
                    // swap
                    [m_sortedCache exchangeObjectAtIndex:(targetIndex - 1) withObjectAtIndex:targetIndex];
                    testEdge.cacheIndex = testEdge.cacheIndex + 1;
                    --targetIndex;
                }
                else
                {
                    // left val is smaller than my val, so we're done.
                    break;
                }
            } while( targetIndex > 0 );
        }
    }
    else if( majorVal > edge.majorVal )
    {
        // if we moved in a positive direction, our index can only be too small.
        int count = [m_sortedCache count];
        if( edge.cacheIndex < count - 1 )
        {
            EREdge *testEdge;
            do
            {
                testEdge = (EREdge *)[m_sortedCache objectAtIndex:(targetIndex + 1)];
                if( testEdge.majorVal < majorVal )  // TODO: <=? depends on assumptions elsewhere in ER
                {
                    // swap
                    [m_sortedCache exchangeObjectAtIndex:(targetIndex + 1) withObjectAtIndex:targetIndex];
                    testEdge.cacheIndex = testEdge.cacheIndex - 1;
                    ++targetIndex;
                }
                else
                {
                    // right val is greater than my val, so we're done.
                    break;
                }
            } while( targetIndex < count - 1 );
        }
        
    }

    edge.majorVal = majorVal;
    edge.cacheIndex = targetIndex;
    
#ifdef LOG_ER_STATS
    [[ERStats instance] stopTimer_moveEdge];
#endif

}


// TODO: if needed we can probably avoid returning an array here most of the time.
//  we can have a Results object that holds either a single instance or an array.
-(NSArray *)collidingEdgeListForEdge:(EREdge *)edge positiveDirection:(BOOL)fPos sortHint:(int *)sortHint
{
#ifdef LOG_ER_STATS
    [[ERStats instance] inc_getEdgeList];
    [[ERStats instance] startTimer_getEdgeList];
#endif

    const int count = [m_sortedCache count];
    [m_workingEdgeList removeAllObjects];
    
    BOOL wasNotMissed = NO;  // were we recording notMissed edges?
    Emu collideMajor;      // once we start recording collisions, remember the major value.
    int collidePoint = [self getInsertPoint:edge withSortHint:sortHint];
    
    // special handling for positive abut case:
    //  when we scan in the positive direction, our insert point will actually be pointing
    //  just past any abutting edges (due to the sort algorithm in use). This means our
    //  insert point is "missing" abutting edges that should register as colliding.
    //  The fix is to bubble our insert point down until we don't see any more abutting edges.
    if( fPos )
    {
        EREdge *testAbutEdge;
        while( collidePoint > 0 )
        {
            testAbutEdge = (EREdge *)[m_sortedCache objectAtIndex:(collidePoint - 1)];
            if( [edge compare:testAbutEdge] == NSOrderedDescending )
            {
                // the edge just before us is smaller, so collidePoint is good.
                break;
            }
            --collidePoint;
        }
    }

#ifdef DEBUG_ER
#if 0
    if( [m_sortedCache count] > 0 )
    {
        EREdge *collidingEdge = nil;
        NSString *collidingEdgeString = @"";
        EREdge *prevEdge = nil;
        NSString *prevEdgeString = @"";
        EREdge *nextEdge = nil;
        NSString *nextEdgeString = @"";
        
        if( collidePoint > 0 && collidePoint <= ([m_sortedCache count] - 1) )
        {
            collidingEdge = (EREdge *)[m_sortedCache objectAtIndex:(collidePoint)];
            collidingEdgeString = [NSString stringWithFormat:@"collidingEdge at: %d,%d-%d. ", collidingEdge.majorVal, collidingEdge.minorLowVal, collidingEdge.minorHighVal];
        }
        if( collidePoint > 0 )
        {
            prevEdge = (EREdge *)[m_sortedCache objectAtIndex:(collidePoint - 1)];
            prevEdgeString = [NSString stringWithFormat:@"prevEdge at: %d,%d-%d. ", prevEdge.majorVal, prevEdge.minorLowVal, prevEdge.minorHighVal];
        }
        if( collidePoint < ([m_sortedCache count] - 1) )
        {
            nextEdge = (EREdge *)[m_sortedCache objectAtIndex:(collidePoint + 1)];
            nextEdgeString = [NSString stringWithFormat:@"nextEdge at: %d,%d-%d. ", nextEdge.majorVal, nextEdge.minorLowVal, nextEdge.minorHighVal];
        }
        
        NSLog( @"sortedEdgeCache: collidePoint=%d of %d. %@%@%@", collidePoint, [m_sortedCache count], prevEdgeString, collidingEdgeString, nextEdgeString );
    }
    else  // cache count == 0
    {
        NSLog( @"sortedEdgeCache empty (this may not be the dir you are looking for)." );        
    }
#endif
#endif

    // edge cases: no collisions
    if( !fPos && collidePoint == 0 )
    {
        return m_workingEdgeList;
    }
    if( fPos && collidePoint == count )
    {
        return m_workingEdgeList;
    }
    
    // this loop is almost the same for the pos/neg cases, except the looping vars/conditions are different.
    int i = fPos ? collidePoint : collidePoint - 1;
    while( YES )
    {
        EREdge *other = (EREdge *)[m_sortedCache objectAtIndex:i];
        
        // using lte/gte instead of lt/gt here because minorHighValue is understood to be an exclusive endpoint.            
        BOOL missed = (edge.minorLowVal >= other.minorHighVal) || (edge.minorHighVal <= other.minorLowVal);
        
        if( wasNotMissed && other.majorVal != collideMajor )
        {
            // we are now looking at edges further than a known collide edge, so we must be done.
            break;
        }
        
        if( missed )
        {
            if( wasNotMissed )
            {
                // done
                break;
            }
            
        }
        else
        {
            [m_workingEdgeList addObject:other];
            wasNotMissed = YES;
            collideMajor = other.majorVal;
        }
        
        BOOL fLoopAgain;
        if( fPos )
        {
            fLoopAgain = (i < count - 1);
            ++i;        
        }
        else
        {
            fLoopAgain = (i > 0);
            --i;        
        }
        if( !fLoopAgain )
        {
            break;
        }        
    }

#ifdef LOG_ER_STATS
    [[ERStats instance] stopTimer_getEdgeList];
#endif

    return m_workingEdgeList;  // this can only be used or copied in the immediate callstack, since this will be reused next time.
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////// ERCacheStrip

@implementation ERCacheStrip


@synthesize stripMinVal = m_stripMinVal, stripMaxVal = m_stripMaxVal, dir = m_dir;


-(id)initWithMinVal:(Emu)minVal maxVal:(Emu)maxVal dir:(ERDirection)dir
{
    if( self = [super init] )
    {
        m_stripMinVal = minVal;
        m_stripMaxVal = maxVal;
        m_dir = dir;
        m_edgeCache = [[ERSortedEdgeCache alloc] init];
        m_testEdge = [[EREdge alloc] init];
    }
    return self;
}


-(void)dealloc
{
    [m_testEdge release]; m_testEdge = nil;
    [m_edgeCache release]; m_edgeCache = nil;
    [super dealloc];
}


-(EREdge *)addEdgeForBlock:(Block *)block
{
    
    Emu majorVal, minorLowVal, minorHighVal;
    switch( m_dir )
    {
        case ERDirLeft:
            majorVal = block.x;
            minorLowVal = block.y;
            minorHighVal = block.y + block.h;
            break;
        case ERDirRight:
            majorVal = block.x + block.w;
            minorLowVal = block.y;
            minorHighVal = block.y + block.h;
            break;
        case ERDirUp:
            majorVal = block.y + block.h;
            minorLowVal = block.x;
            minorHighVal = block.x + block.w;
            break;
        case ERDirDown:
            majorVal = block.y;
            minorLowVal = block.x;
            minorHighVal = block.x + block.w;
            break;
        default:
            NSAssert( NO, @"Unknown direction problem?" );
            break;
    }
    
    EREdge *edge = [[EREdge alloc] init];
    edge.majorVal = majorVal;
    edge.minorLowVal = minorLowVal;
    edge.minorHighVal = minorHighVal;
    edge.block = block;  // weak;
    edge.dir = m_dir;
    
    [m_edgeCache addEdge:edge];
    [edge release];
    return edge;
}


-(Emu)cacheStripGetElbowRoomForBlock:(Block *)block outEdgeList:(NSArray **)outEdgeList
{
    // here we are testing for collision detection, so we should select the edge that would
    //  collide with whatever edges we have cached. so if m_dir==Left, we should test for
    //  collisions with block's right edge.
    Emu majorVal, minorLowVal, minorHighVal;
    int sortHint;
    switch( m_dir )
    {
        case ERDirLeft:
            majorVal = block.x + block.w;
            minorLowVal = block.y;
            minorHighVal = block.y + block.h;
            sortHint = block.state.erSortHint.leftHint;
            break;
        case ERDirRight:
            majorVal = block.x;
            minorLowVal = block.y;
            minorHighVal = block.y + block.h;
            sortHint = block.state.erSortHint.rightHint;
            break;
        case ERDirUp:
            majorVal = block.y;
            minorLowVal = block.x;
            minorHighVal = block.x + block.w;
            sortHint = block.state.erSortHint.upHint;
            break;
        case ERDirDown:
            majorVal = block.y + block.h;
            minorLowVal = block.x;
            minorHighVal = block.x + block.w;
            sortHint = block.state.erSortHint.downHint;
            break;
        default:
            NSAssert( NO, @"Unknown direction problem?" );
            break;
    }
    
    m_testEdge.majorVal = majorVal;
    m_testEdge.minorLowVal = minorLowVal;
    m_testEdge.minorHighVal = minorHighVal;

    BOOL fPos = (m_dir == ERDirLeft) || (m_dir == ERDirDown);
    
    NSArray *collidingEdgeList = [m_edgeCache collidingEdgeListForEdge:m_testEdge positiveDirection:fPos sortHint:&sortHint];
    
    // save the updated sortHint
    switch( m_dir )
    {
        case ERDirLeft:
            block.state.erSortHint.leftHint = sortHint;
            break;
        case ERDirRight:
            block.state.erSortHint.rightHint = sortHint;
            break;
        case ERDirUp:
            block.state.erSortHint.upHint = sortHint;
            break;
        case ERDirDown:
            block.state.erSortHint.downHint = sortHint;
            break;
        default:
            NSAssert( NO, @"Unknown direction problem?" );
            break;
    }
    
    if( outEdgeList != nil )
    {
        (*outEdgeList) = collidingEdgeList;
    }
    
    if( [collidingEdgeList count] == 0 )
    {
        return ERMaxDistance;
    }
    
    // all edges in this array should have same majorVal, so just use zero'th
    EREdge *edge = (EREdge *)[collidingEdgeList objectAtIndex:0];
    
    Emu result = 0;
    switch( m_dir )
    {
        case ERDirLeft:
            result = edge.majorVal - (block.x + block.w);
            break;
        case ERDirRight:
            result = block.x - edge.majorVal;
            break;
        case ERDirUp:
            result = block.y - edge.majorVal;
            break;
        case ERDirDown:
            result = edge.majorVal - (block.y + block.h);
            break;
        default:
            NSAssert( NO, @"Unknown direction problem?" );
            break;
    }
    return result;
}


+(NSNumber *)getHashCodeForMinVal:(Emu)minVal maxVal:(Emu)maxVal dir:(ERDirection)dir
{
    // TODO: review the first two bitshifts, seems like we are just wasting bits?
    int minValA = (int)minVal >> 4;
    int maxValA = (int)maxVal >> 4;
    int dirA = (int)dir;
    int mask = (1 << 14) - 1;
    int hashCode = (minValA & mask) + ( (maxValA & mask) << 14) + (dirA << 28);
    return [NSNumber numberWithInt:hashCode];
}


@end




////////////////////////////////////////////////////////////////////////////////////////////////////////////////// ERSOInfo

@implementation ERSOInfo

@synthesize edgeList = m_edgeList;

-(id)init
{
    if( self = [super init] )
    {
        m_edgeList = [[NSMutableArray arrayWithCapacity:10] retain];
    }
    return self;
}


-(void)dealloc
{
    [m_edgeList release]; m_edgeList = nil;
    [super dealloc];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////// ElbowRoom

@implementation ElbowRoom

-(id)init
{
    if( self = [super init] )
    {
        // TODO: need to put more thought into this. One_Block strikes me as too small for actors. works well for movingplatform stuff that stays constrained.
        // TODO: try tweaking this value to see if it affects stress test performance.
        m_stripSize = ONE_BLOCK_SIZE_Emu;
        
        // TODO: what's the right capacity?
        m_stripTable = [[NSMutableDictionary dictionaryWithCapacity:200] retain];
        
        m_blockInfoCache = [[NSMutableDictionary dictionaryWithCapacity:200] retain];
        
        m_resultCollidingEdgeList = [[NSMutableArray arrayWithCapacity:100] retain];
        
    }
    return self;
}


-(void)dealloc
{
    [m_resultCollidingEdgeList release]; m_resultCollidingEdgeList = nil;
    [m_blockInfoCache release]; m_blockInfoCache = nil;
    [m_stripTable release]; m_stripTable = nil;
    [super dealloc];
}


-(void)registerEdge:(EREdge *)edge forSOInfo:(ERSOInfo *)info
{
    [info.edgeList addObject:edge];
}


-(ERSOInfo *)ensureSOInfoForSO:(ASolidObject *)solidObject
{
    ERSOInfo *info = (ERSOInfo *)[m_blockInfoCache valueForKey:[solidObject getKey]];
    if( info == nil )
    {
        info = [[ERSOInfo alloc] init];
        [m_blockInfoCache setValue:info forKey:[solidObject getKey]];
        [info release];
    }
    return info;
}


-(ERSOInfo *)getSOInfoForSO:(ASolidObject *)solidObject
{
    return [self ensureSOInfoForSO:solidObject];
}


-(void)addBlock:(Block *)block forUp:(bool)fUp left:(bool)fLeft right:(bool)fRight down:(bool)fDown
{
    NSAssert( m_stripSize != 0.f, @"need to set stripSize before adding blocks." );
    
    ERSOInfo *soInfo = [self ensureSOInfoForSO:block];
    
    Emu minVal, maxVal;
    Emu stripStart;
    NSNumber *stripTableKey;
    ERCacheStrip *cacheStrip;
    
    EREdge *edge;
    
    if( fLeft || fRight )
    {
        // left/right edges
        minVal = block.y;
        maxVal = block.y + block.h;
        stripStart = ROUND_TO_STRIP( minVal );
        while( stripStart <= maxVal )
        {
            if( fLeft )
            {
                stripTableKey = [ERCacheStrip getHashCodeForMinVal:stripStart maxVal:(stripStart + m_stripSize) dir:ERDirLeft];
                cacheStrip = [m_stripTable objectForKey:stripTableKey];
                if( cacheStrip == nil )
                {
                    cacheStrip = [[ERCacheStrip alloc] initWithMinVal:stripStart maxVal:(stripStart + m_stripSize) dir:ERDirLeft];
                    [m_stripTable setObject:cacheStrip forKey:stripTableKey];
                    [cacheStrip release];
                }
                edge = [cacheStrip addEdgeForBlock:block];
                [self registerEdge:edge forSOInfo:soInfo];
            }
            
            if( fRight )
            {
                stripTableKey = [ERCacheStrip getHashCodeForMinVal:stripStart maxVal:(stripStart + m_stripSize) dir:ERDirRight];
                cacheStrip = [m_stripTable objectForKey:stripTableKey];
                if( cacheStrip == nil )
                {
                    cacheStrip = [[ERCacheStrip alloc] initWithMinVal:stripStart maxVal:(stripStart + m_stripSize) dir:ERDirRight];
                    [m_stripTable setObject:cacheStrip forKey:stripTableKey];
                    [cacheStrip release];
                }
                edge = [cacheStrip addEdgeForBlock:block];
                [self registerEdge:edge forSOInfo:soInfo];
            }
            
            stripStart += m_stripSize;
        }
    }

    if( fUp || fDown )
    {    
        // up/down edges
        minVal = block.x;
        maxVal = block.x + block.w;
        stripStart = ROUND_TO_STRIP( minVal );
        while( stripStart <= maxVal )
        {
            if( fUp )
            {
                stripTableKey = [ERCacheStrip getHashCodeForMinVal:stripStart maxVal:(stripStart + m_stripSize) dir:ERDirUp];
                cacheStrip = [m_stripTable objectForKey:stripTableKey];
                if( cacheStrip == nil )
                {
                    cacheStrip = [[ERCacheStrip alloc] initWithMinVal:stripStart maxVal:(stripStart + m_stripSize) dir:ERDirUp];
                    [m_stripTable setObject:cacheStrip forKey:stripTableKey];
                    [cacheStrip release];
#ifdef DEBUG_ER
                    NSLog( @"adding up strip %d", stripStart );
#endif
                }
                edge = [cacheStrip addEdgeForBlock:block];
                [self registerEdge:edge forSOInfo:soInfo];
#ifdef DEBUG_ER
                NSLog( @"added an  up edge y=%d,x=%d,%d to strip %d.", edge.majorVal, edge.minorLowVal, edge.minorHighVal, stripStart );
#endif
            }
            
            if( fDown )
            {
                stripTableKey = [ERCacheStrip getHashCodeForMinVal:stripStart maxVal:(stripStart + m_stripSize) dir:ERDirDown];
                cacheStrip = [m_stripTable objectForKey:stripTableKey];
                if( cacheStrip == nil )
                {
                    cacheStrip = [[ERCacheStrip alloc] initWithMinVal:stripStart maxVal:(stripStart + m_stripSize) dir:ERDirDown];
                    [m_stripTable setObject:cacheStrip forKey:stripTableKey];
                    [cacheStrip release];
#ifdef DEBUG_ER
                    NSLog( @"adding down strip %d", stripStart );
#endif
                }
                edge = [cacheStrip addEdgeForBlock:block];
                [self registerEdge:edge forSOInfo:soInfo];
#ifdef DEBUG_ER
                NSLog( @"added a down edge y=%d,x=%d,%d to strip %d.", edge.majorVal, edge.minorLowVal, edge.minorHighVal, stripStart );
#endif
            }
            
            stripStart += m_stripSize;
        }
    }

}


-(void)addBlock:(Block *)block
{
    [self addBlock:block forUp: (block.props.solidMask & BlockEdgeDirMask_Up)
                         left:  (block.props.solidMask & BlockEdgeDirMask_Left)
                         right: (block.props.solidMask & BlockEdgeDirMask_Right)
                         down:  (block.props.solidMask & BlockEdgeDirMask_Down) ];
}


-(void)removeBlock:(Block *)block
{
    ERSOInfo *soInfo = [m_blockInfoCache valueForKey:block.key];
    NSAssert( soInfo != nil, @"removeBlock: no soInfo?" );
    
    for( int i = 0; i < [soInfo.edgeList count]; ++i )
    {
        EREdge *thisEdge = (EREdge *)[soInfo.edgeList objectAtIndex:i];
        
        thisEdge.block = nil;  // edges can outlive blocks in some cases (by one frame when blocks die).
        
        ERSortedEdgeCache *cache = (ERSortedEdgeCache *)thisEdge.containingCache;
        [cache removeEdge:thisEdge];   // TODO: this could leave empty caches, do we care?
    }
    [soInfo.edgeList removeAllObjects];
    [m_blockInfoCache removeObjectForKey:block.key];
}


-(void)singleAxisMoveBlock:(Block *)block withOffset:(EmuPoint)offset
{
    // optimized special case: a block is moving along one axis.
    // we can just update its edge in the parallel strips, potentially rebubbling.
    // in the perpendicular strips, we can just update the edge if the move is small enough (doesn't cross strip bounds)
    
    ERSOInfo *soInfo = [m_blockInfoCache valueForKey:block.key];
    NSAssert( soInfo != nil, @"singleAxisMoveBlock: no blockInfo?" );

    bool movedX = (offset.x != 0);
    bool movedY = (offset.y != 0);
    if( !( movedX || movedY ) )
    {
        // no motion
        return;
    }
    if( movedX && movedY )
    {
        NSAssert( NO, @"singleAxisMove called for dual-axis move. You insensitive clod." );
        return;
    }
    
    // a further optimization: if our move is small enough such that all perpendicular edges can
    //  remain in their current strips, we can just slide them too (instead of removing/re-adding)
    BOOL canSlidePerpendicularEdges = NO;
    Emu origStripStart;
    Emu newStripStart;
    Emu origStripEnd;
    Emu newStripEnd;
    Emu eTmp;
    if( movedX )
    {
        eTmp = block.x;                      origStripStart = ROUND_TO_STRIP( eTmp );
        eTmp = block.x + offset.x;           newStripStart = ROUND_TO_STRIP( eTmp );
        eTmp = block.x + block.w ;           origStripEnd = ROUND_TO_STRIP( eTmp );
        eTmp = block.x + offset.x + block.w; newStripEnd = ROUND_TO_STRIP( eTmp );
    }
    else
    {
        eTmp = block.y;                      origStripStart = ROUND_TO_STRIP( eTmp );
        eTmp = block.y + offset.y;           newStripStart = ROUND_TO_STRIP( eTmp );
        eTmp = block.y + block.h;            origStripEnd = ROUND_TO_STRIP( eTmp );
        eTmp = block.y + offset.y + block.h; newStripEnd = ROUND_TO_STRIP( eTmp );
    }
    
    if( origStripStart == newStripStart && origStripEnd == newStripEnd )
    {
        canSlidePerpendicularEdges = YES;
    }
    
#ifdef DEBUG_ER
    if( movedX )
    {
        if( canSlidePerpendicularEdges )
        {
            NSLog( @"sliding up/down edges, stripStart/end unchanged at %d-%d", newStripStart, newStripEnd );
        }
        else
        {
            NSLog( @"not sliding up/down edges, stripStart/end was %d-%d, changed to %d-%d", origStripStart, origStripEnd, newStripStart, newStripEnd );
        }
    }
#endif
    
    EmuRect targetRect = EmuRectMake( block.x + offset.x, block.y + offset.y, block.w, block.h );
    [block.state setRect:targetRect];
    
    // iterate in reverse since we remove perpendicular edges from the edgeList.
    for( int i = [soInfo.edgeList count] - 1; i >= 0 ; --i )
    {
        float majorVal;
        EREdge *thisEdge = (EREdge *)[soInfo.edgeList objectAtIndex:i];
        ERSortedEdgeCache *edgeCache = (ERSortedEdgeCache *)thisEdge.containingCache;
        NSAssert( edgeCache != nil, @"singleAxisMoveParallelEdge: need edgeCache!" );
        
        if( movedX )
        {
            switch( thisEdge.dir )
            {
                // slide edges facing parallel to direction of motion
                case ERDirLeft:
                    majorVal = block.x;
                    [edgeCache moveEdge:thisEdge toMajorVal:majorVal ];
                    break;
                case ERDirRight:
                    majorVal = block.x + block.w;
                    [edgeCache moveEdge:thisEdge toMajorVal:majorVal ];
                    break;

                // remove edges facing perpendicular to direction of motion
                case ERDirUp:    // fallthrough
                case ERDirDown:
                    if( canSlidePerpendicularEdges )
                    {
#ifdef DEBUG_ER
                        if( thisEdge.dir == ERDirUp )   NSLog( @"    sliding perpendicular   up edge       y=%d,x=%d-%d.", thisEdge.majorVal, thisEdge.minorLowVal, thisEdge.minorHighVal );
                        if( thisEdge.dir == ERDirDown ) NSLog( @"    sliding perpendicular down edge       y=%d,x=%d-%d.", thisEdge.majorVal, thisEdge.minorLowVal, thisEdge.minorHighVal );
#endif
                        // just updated minor values! no bubbling required.
                        thisEdge.minorLowVal = block.x;
                        thisEdge.minorHighVal = block.x + block.w;
#ifdef DEBUG_ER
                        if( thisEdge.dir == ERDirUp )   NSLog( @"     new values for   up edge post-slide  y=%d,x=%d-%d.", thisEdge.majorVal, thisEdge.minorLowVal, thisEdge.minorHighVal );
                        if( thisEdge.dir == ERDirDown ) NSLog( @"     new values for down edge post-slide  y=%d,x=%d-%d.", thisEdge.majorVal, thisEdge.minorLowVal, thisEdge.minorHighVal );
#endif
                    }
                    else
                    {
#ifdef DEBUG_ER
                        if( thisEdge.dir == ERDirDown ) NSLog( @"not sliding perpendicular down edge            y=%d,x=%d-%d.", thisEdge.majorVal, thisEdge.minorLowVal, thisEdge.minorHighVal );
#endif
                        [edgeCache removeEdge:thisEdge];
                        [soInfo.edgeList removeObjectAtIndex:i];  // assumes we're iterating backwards over edgeList
                    }
                    break;
                default:
                    NSAssert( NO, @"singleAxisMoveBlock: bad edge direction?" );
                    break;                    
            }
        }
        else  // moved y
        {
            switch( thisEdge.dir )
            {
                // slide edges facing parallel to direction of motion
                case ERDirDown:
                    majorVal = block.y;
                    [edgeCache moveEdge:thisEdge toMajorVal:majorVal ];
                    break;
                case ERDirUp:
                    majorVal = block.y + block.h;
                    [edgeCache moveEdge:thisEdge toMajorVal:majorVal ];
                    break;
                    
                // remove edges facing perpendicular to direction of motion
                case ERDirLeft:    // fallthrough
                case ERDirRight:
                    if( canSlidePerpendicularEdges )
                    {
                        // just updated minor values! no bubbling required.
                        thisEdge.minorLowVal = block.y;
                        thisEdge.minorHighVal = block.y + block.h;
                    }
                    else
                    {
                        [edgeCache removeEdge:thisEdge];
                        [soInfo.edgeList removeObjectAtIndex:i];  // assumes we're iterating backwards over edgeList
                    }
                    break;
                    
                default:
                    NSAssert( NO, @"singleAxisMoveBlock: bad edge direction?" );
                    break;                    
            }
        }
    }

    if( !canSlidePerpendicularEdges )
    {
        // if we had to remove perpendicular edges, re-add edges for the perpendicular strips only.
        [self addBlock:block forUp:movedX left:(!movedX) right:(!movedX) down:movedX];
#ifdef DEBUG_ER
        if( movedX ) NSLog( @"re-added block with down edge major %d and up edge major %d minorVals %d,%d", (block.y), (block.y + block.h), block.x, (block.x + block.w) );
#endif
    }
}


-(void)deduplicateEdgeList:(NSMutableArray *)list
{
#ifdef LOG_ER_STATS
    [[ERStats instance] inc_deduplicate];
    [[ERStats instance] startTimer_deduplicate];
#endif

    // before de-duping, sort the list strictly (including minor val)
    // why not always use strict compare? there seems to be an assumption baked
    // in somewhere about insert point not being strict, can't find it right now.
    [list sortUsingSelector:@selector(compareStrict:)];
    
    int i = 0;
    int listCount = [list count];
    while( YES )
    {
        if( i >= listCount - 1 )
            return;
        EREdge *thisEdge = (EREdge *)[list objectAtIndex:i];
        EREdge *nextEdge = (EREdge *)[list objectAtIndex:(i+1)];
        if( [thisEdge equals:nextEdge] )
        {
            // TODO: I'm curious how often this hits...can we get by without having to do this work somehow?
            [list removeObjectAtIndex:i];
            --listCount;
        }
        else
        {
            ++i;
        }
    }

#ifdef LOG_ER_STATS
    [[ERStats instance] stopTimer_deduplicate];
#endif
}


-(void)moveBlock:(Block *)block byOffset:(EmuPoint)offset
{
    BOOL movingBothAxes = (offset.x != 0) && (offset.y != 0);
    const BOOL disableSingleAxis = NO;
    
    if( disableSingleAxis || movingBothAxes )
    {
        // less common, more complex cases: just remove and re-add the block
        [self removeBlock:block];
        EmuRect targetRect = EmuRectMake( block.x + offset.x, block.y + offset.y, block.w, block.h );
        [block.state setRect:targetRect];
        [self addBlock:block];
    }
    else
    {
        // more common case: block is just moving along one axis, use optimized codepath.
        [self singleAxisMoveBlock:block withOffset:offset];
    }
}


-(Emu)getElbowRoomForBlock:(Block *)block inDirection:(ERDirection)dir outCollidingEdgeList:(NSArray **)outCollidingEdgeList
{
#ifdef LOG_ER_STATS
    if( outCollidingEdgeList == nil )
    {
        [[ERStats instance] inc_getERNoList];
        [[ERStats instance] startTimer_getERNoList];
    }
    else
    {
        [[ERStats instance] inc_getERList];
        [[ERStats instance] startTimer_getERList];
    }
#endif
    
    ERDirection edgeDirection;  // opposite of block collision direction.
    Emu minVal, maxVal;
    switch( dir )
    {
        case ERDirLeft:
            edgeDirection = ERDirRight;
            minVal = block.y;
            maxVal = block.y + block.h;
            break;
        case ERDirRight:
            edgeDirection = ERDirLeft;
            minVal = block.y;
            maxVal = block.y + block.h;
            break;
        case ERDirUp:
            edgeDirection = ERDirDown;
            minVal = block.x;
            maxVal = block.x + block.w;
            break;
        case ERDirDown:
            edgeDirection = ERDirUp;
            minVal = block.x;
            maxVal = block.x + block.w;
            break;
        default:
            NSAssert( NO, @"Unknown direction problem?" );
            break;
    }
    if( outCollidingEdgeList != nil )
    {
        [m_resultCollidingEdgeList removeAllObjects];
    }
    
    NSArray *thisCollidingEdgeList;
    Emu stripStart = ROUND_TO_STRIP( minVal );
    Emu minElbowRoom = ERMaxDistance;
    while( stripStart < maxVal )
    {
        NSNumber *stripTableKey = [ERCacheStrip getHashCodeForMinVal:stripStart maxVal:(stripStart + m_stripSize) dir:edgeDirection];
        ERCacheStrip *cacheStrip = [m_stripTable objectForKey:stripTableKey];
        if( cacheStrip == nil )
        {
            minElbowRoom = MIN( minElbowRoom, ERMaxDistance );
        }
        else
        {
            Emu thisElbowRoom = [cacheStrip cacheStripGetElbowRoomForBlock:block outEdgeList:(&thisCollidingEdgeList)];

            Emu oldMin = minElbowRoom;
            minElbowRoom = MIN( minElbowRoom, thisElbowRoom );
            
            if( outCollidingEdgeList != nil )
            {
                if( thisElbowRoom == minElbowRoom )
                {
                    if( oldMin != minElbowRoom )
                    {
#ifdef DEBUG_ER
                        NSLog( @"ditching %d colliding edges. oldMin=%d minElbowRoom=%d.", [m_resultCollidingEdgeList count], oldMin, minElbowRoom );
#endif
                        // min just changed, meaning that any colliding edges we'd accumulated
                        //  for return are not actually min edges. So ditch them.
                        [m_resultCollidingEdgeList removeAllObjects];
                    }
                    [m_resultCollidingEdgeList addObjectsFromArray:thisCollidingEdgeList];
#ifdef DEBUG_ER
                    if( cacheStrip.dir == ERDirUp )
                    {
                        NSLog( @"adding %d objects to resultCollidingEdgeList for cacheStrip with valRange %d,%d.", [thisCollidingEdgeList count], cacheStrip.stripMinVal, cacheStrip.stripMaxVal );
                    }
#endif
                }
            }
        }
        
        stripStart += m_stripSize;
    }

    // maybe we can avoid adding duplicates in the first place?
    //  - before putting an edge in the list, check a dictionary for the block key (can we ignore dir  and see if we've added it yet?
    //  - should time just this part to see how much we have to gain. I think I measured this before and found it unremarkable.
    if( outCollidingEdgeList != nil )
    {
        [self deduplicateEdgeList:m_resultCollidingEdgeList];
        (*outCollidingEdgeList) = m_resultCollidingEdgeList;
    }
    
#ifdef LOG_ER_STATS
    if( outCollidingEdgeList == nil )
    {
        [[ERStats instance] stopTimer_getERNoList];        
    }
    else
    {
        [[ERStats instance] stopTimer_getERList];        
    }
#endif
    
    return minElbowRoom;
}


-(BOOL)shouldShortCircuitBlock:(Block *)block inDirection:(ERDirection)erDir
{
    BlockEdgeDirMask bsDir = BlockEdgeDirMask_None;
    switch( erDir )
    {
        case ERDirLeft:  bsDir = BlockEdgeDirMask_Left;  break;
        case ERDirRight: bsDir = BlockEdgeDirMask_Right; break;
        case ERDirUp:    bsDir = BlockEdgeDirMask_Up;    break;
        case ERDirDown:  bsDir = BlockEdgeDirMask_Down;  break;
        default: NSAssert( NO, @"shouldShortCircuitBlock: unexpected erDir" ); break;            
    }
    return (block.shortCircuitER & bsDir) > 0;
}


-(Emu)getElbowRoomForGroup:(BlockGroup *)group inDirection:(ERDirection)dir outCollidingEdgeList:(NSArray **)outCollidingEdgeList
{
    Emu minER = ERMaxDistance;
    Emu thisER;
    NSMutableArray *resultCEdgeList = nil;
    if( outCollidingEdgeList != nil )
    {
        resultCEdgeList = [NSMutableArray arrayWithCapacity:4];
    }
    NSArray *thisResultCEdgeList;
    
    for( int i = 0; i < [group.blocks count]; ++i )
    {
        Block *thisBlock = (Block *)[group.blocks objectAtIndex:i];

        if( [self shouldShortCircuitBlock:thisBlock inDirection:dir] )
        {
            continue;
        }
        
        if( outCollidingEdgeList == nil )
        {
            thisER = [self getElbowRoomForBlock:thisBlock inDirection:dir outCollidingEdgeList:nil];
            minER = MIN( thisER, minER );
        }
        else
        {
            thisER = [self getElbowRoomForBlock:thisBlock inDirection:dir outCollidingEdgeList:&thisResultCEdgeList];
            if( thisER == minER )
            {
                // this block is (another) min block, so grab resulting edges
                [resultCEdgeList addObjectsFromArray:thisResultCEdgeList];
            }
            else if ( thisER < minER )
            {
                // a new min was set, so throw away existing results and start with new results.
                minER = thisER;
                resultCEdgeList = [NSMutableArray arrayWithArray:thisResultCEdgeList];
            }
        }
    }
    if( outCollidingEdgeList != nil )
    {
        *outCollidingEdgeList = resultCEdgeList;
    }
    return minER;
}


-(void)reset
{
    [m_stripTable release];
    m_stripTable = [[NSMutableDictionary dictionaryWithCapacity:200] retain];

    [m_blockInfoCache release];
    m_blockInfoCache = [[NSMutableDictionary dictionaryWithCapacity:200] retain];
}


-(Emu)getElbowRoomForSO:(ASolidObject *)solidObject inDirection:(ERDirection)dir outCollidingEdgeList:(NSArray **)outCollidingEdgeList
{
    if( [solidObject isGroup] )
    {
        return [self getElbowRoomForGroup:(BlockGroup *)solidObject inDirection:dir outCollidingEdgeList:outCollidingEdgeList];
    }
    else
    {
        // for posterity: saw an odd issue when ERMaxDistance is close to the max value of Emu.
        //   in particular, I set the constant to 0x0fffffff, and sometimes returning that value
        //   here would mysteriously add one by the time the caller recieves the value. freaky.
        return [self getElbowRoomForBlock:(Block *)solidObject inDirection:dir outCollidingEdgeList:outCollidingEdgeList];
    }
}


@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////// ERStats
@implementation ERStats

static ERStats *erStatsStaticInstance = nil;

-(id)init
{
    if( self = [super init] )
    {
        [self reset];
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


+(void)initStaticInstance
{
    NSAssert( erStatsStaticInstance == nil, @"ERStats: singleton already initialized. In the past, this has happened due to retain properties creating circular references, preventing World from dealloc'ing." );
    erStatsStaticInstance = [[ERStats alloc] init];
}


+(void)releaseStaticInstance
{
    [erStatsStaticInstance release]; erStatsStaticInstance = nil;    
}


+(ERStats *)instance
{
    return erStatsStaticInstance;
}


-(void)reset
{
    count_edgeCompare = 0;
    count_edgeEquality = 0;
    count_addEdge = 0;
    count_removeEdge = 0;
    count_moveEdge = 0;
    count_getEdgeList = 0;
    count_getERList = 0;
    count_getERNoList = 0;
    count_deduplicate = 0;
    
    time_addEdge = 0;
    time_moveEdge = 0;
    time_getEdgeList = 0;
    time_getERList = 0;
    time_getERNoList = 0;
    time_deduplicate = 0;
    
    m_timeRemainingBeforeReport = ERSTATS_REPORT_INTERVAL_S;
}


-(void)report
{
    // report all counts in terms of hertz
    // report all times in terms of average ms per second
    
    //int avg_edgeCompare  = (int)roundf( count_edgeCompare / ERSTATS_REPORT_INTERVAL_S );
    //int avg_edgeEquality = (int)roundf( count_edgeEquality / ERSTATS_REPORT_INTERVAL_S );
    //int avg_addEdge      = (int)roundf( count_addEdge / ERSTATS_REPORT_INTERVAL_S );
    //int avg_removeEdge   = (int)roundf( count_removeEdge / ERSTATS_REPORT_INTERVAL_S );
    //int avg_moveEdge     = (int)roundf( count_moveEdge / ERSTATS_REPORT_INTERVAL_S );
    //int avg_getEdgeList  = (int)roundf( count_getEdgeList / ERSTATS_REPORT_INTERVAL_S );
    //int avgTime_addEdge  = (int)roundf( time_addEdge / ERSTATS_REPORT_INTERVAL_S );
    //int avgTime_moveEdge = (int)roundf( time_moveEdge / ERSTATS_REPORT_INTERVAL_S );
    //int avgTime_getEdgeList = (int)roundf( time_getEdgeList / ERSTATS_REPORT_INTERVAL_S );

    int avg_getERNoList      = (int)roundf( count_getERNoList / ERSTATS_REPORT_INTERVAL_S );
    int avg_getERList        = (int)roundf( count_getERList / ERSTATS_REPORT_INTERVAL_S );
    int avg_dedup            = (int)roundf( count_deduplicate / ERSTATS_REPORT_INTERVAL_S );
    int avgTime_getERNoList  = (int)roundf( time_getERNoList / ERSTATS_REPORT_INTERVAL_S );
    int avgTime_getERList    = (int)roundf( time_getERList / ERSTATS_REPORT_INTERVAL_S );
    int avgTime_dedup        = (int)roundf( time_deduplicate / ERSTATS_REPORT_INTERVAL_S );
    
    
    //NSString *report = [NSString stringWithFormat:@"cmp=%d eql=%d add=%d rem=%d mov=%d get=%d tAdd=%d tMov=%d tGet=%d",
    //                    avg_edgeCompare, avg_edgeEquality, avg_addEdge, avg_removeEdge, avg_moveEdge, avg_getEdgeList, avgTime_addEdge, avgTime_moveEdge, avgTime_getEdgeList ];
    //NSString *report = [NSString stringWithFormat:@"tAdd=%d tMov=%d tGet=%d", avgTime_addEdge, avgTime_moveEdge, avgTime_getEdgeList ];
    NSString *report = [NSString stringWithFormat:@"cnolist=%d tnolist=%d clist=%d tlist=%d cdup=%d tdup=%d", avg_getERNoList, avgTime_getERNoList, avg_getERList, avgTime_getERList, avg_dedup, avgTime_dedup ];

    DebugOut( report );
}


-(void)updateWithTimeDelta:(float)delta
{
#ifdef LOG_ER_STATS
    m_timeRemainingBeforeReport -= delta;
    if( m_timeRemainingBeforeReport <= 0.f )
    {
        [self report];
        [self reset];
    }
#endif
}


-(void)inc_edgeCompare
{
    ++count_edgeCompare;
}


-(void)inc_edgeEquality
{
    ++count_edgeEquality;
}


-(void)inc_addEdge
{
    ++count_addEdge;
}


-(void)startTimer_addEdge
{
    m_timer_addEdge = getUpTimeMs();
}


-(void)stopTimer_addEdge
{
    time_addEdge += getUpTimeMs() - m_timer_addEdge;
}


-(void)inc_removeEdge
{
    ++count_removeEdge;
}


-(void)inc_moveEdge
{
    ++count_moveEdge;
}


-(void)startTimer_moveEdge
{
    m_timer_moveEdge = getUpTimeMs();
}


-(void)stopTimer_moveEdge
{
    time_moveEdge += getUpTimeMs() - m_timer_moveEdge;
}


-(void)inc_getEdgeList
{
    ++count_getEdgeList;
}


-(void)startTimer_getEdgeList
{
    m_timer_getEdgeList = getUpTimeMs();
}


-(void)stopTimer_getEdgeList
{
    time_getEdgeList += getUpTimeMs() - m_timer_getEdgeList;   
}


-(void)inc_getERNoList
{
    ++count_getERNoList;
}


-(void)inc_getERList
{
    ++count_getERList;
}


-(void)startTimer_getERNoList
{
    m_timer_getERNoList = getUpTimeMs();
}


-(void)stopTimer_getERNoList
{
    time_getERNoList += getUpTimeMs() - m_timer_getERNoList;
    
}


-(void)startTimer_getERList
{
    m_timer_getERList = getUpTimeMs();
}


-(void)stopTimer_getERList
{
    time_getERList += getUpTimeMs() - m_timer_getERList;
}


-(void)inc_deduplicate
{
    ++count_deduplicate;
}


-(void)startTimer_deduplicate
{
    m_timer_deduplicate = getUpTimeMs();
}


-(void)stopTimer_deduplicate
{
    time_deduplicate += getUpTimeMs() - m_timer_deduplicate;

}

@end
