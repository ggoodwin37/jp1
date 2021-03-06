//
//  PropagateMovementUpdater.m
//  JumpProto
//
//  Created by Gideon iOS on 7/27/13.
//
//

#import "PropagateMovementUpdater.h"
#import "BlockGroup.h"
#import "Actor.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// PropagateMovementUpdater

@implementation PropagateMovementUpdater

-(id)initWithElbowRoom:(NSObject<IElbowRoom> *)elbowRoom frameCache:(WorldFrameCache *)frameCacheIn
{
    if( self = [super initWithElbowRoom:elbowRoom frameCache:frameCacheIn] )
    {
        m_groupPropStack = [[NSMutableArray arrayWithCapacity:4] retain];
        m_propsAccumulator = [[BlockProps alloc] init];
    }
    return self;
}


-(void)dealloc
{
    [m_propsAccumulator release]; m_propsAccumulator = nil;
    [m_groupPropStack release]; m_groupPropStack = nil;
    [super dealloc];
}


-(BOOL)collisionBetween:(ASolidObject *)nodeA and:(ASolidObject *)nodeB inDir:(ERDirection)dir overrideProps:(BlockProps *)props
{
    ERDirection opposingDir;
    switch( dir )
    {
        case ERDirUp: opposingDir    = ERDirDown;  break;
        case ERDirDown: opposingDir  = ERDirUp;    break;
        case ERDirLeft: opposingDir  = ERDirRight;  break;
        case ERDirRight: opposingDir = ERDirLeft; break;
        default: opposingDir = ERDirNone; break;
    }
    
    // why do we have to fire this twice?
    // consider the venus fly trap.
    BOOL didABounce = [nodeA collidedInto:nodeB inDir:dir props:props];
    BOOL didBBounce = [nodeB collidedInto:nodeA inDir:opposingDir props:[nodeA getProps]];  // use original (not accumulated) props for reverse direction
    return didABounce || didBBounce;
}


// basic idea here is to combine certain properties for all SOs in the list. We'll accumulate these properties
// into a member variable (for performance) and use these accumulated values in our collision handlers. This fixes
// the case where player is standing on a block and a spike (they would insta-die on the spike without this step).
// it's a little awkward because only specific properties fall in this bucket: hurty, springy, wallJump, and goal.
// in some cases we AND, in some cases we OR.
-(void)accumulatePropsForList:(NSArray *)list
{
    if( [list count] < 1 ) return;
    BlockProps *firstProps = [[list objectAtIndex:0] getProps];

    m_propsAccumulator.springyMask = firstProps.springyMask;
    m_propsAccumulator.hurtyMask = firstProps.hurtyMask;
    m_propsAccumulator.isGoalBlock = firstProps.isGoalBlock;
    m_propsAccumulator.isWallJumpable = firstProps.isWallJumpable;
    for( int i = 1; i < [list count]; ++i )
    {
        BlockProps *thisProps = [[list objectAtIndex:i] getProps];
        m_propsAccumulator.springyMask &= thisProps.springyMask;
        m_propsAccumulator.hurtyMask &= thisProps.hurtyMask;
        m_propsAccumulator.isGoalBlock &= thisProps.isGoalBlock;
        m_propsAccumulator.isWallJumpable |= thisProps.isWallJumpable;
    }
}


// implement "gap check" (aka one-hole-down) logic. this is required so that we can avoid skipping entirely
//  over small gaps in the opposing axis. we detect if we are on the edge of a gap, and if so, limit the
//  target offset so that we end the turn directly over the gap, instead of moving beyond it.
// this method makes a distinction between group SOs and their element blocks. we only want to check
//  gaps against elements.
-(Emu)checkPerpGapsForNode:(ASolidObject *)node targetOffset:(Emu)targetOffset isXAxis:(BOOL)xAxis outStoppedForGap:(BOOL *)outStoppedForGap
{
    NSAssert( ![node isGroup], @"don't pass group nodes in here" );  // note: can process group elements, just not group owners.
    
    EmuPoint vOrig = [node getV];
    
    // try to bail early
    if(      targetOffset == 0 ) return targetOffset;
    if( !xAxis && vOrig.x == 0 ) return targetOffset;
    // note: still process the vy=0 case so we can check for downward gaps.
    // if a block is resting it won't have down v but should still be able to hit gaps.
    
    ERDirection gapDirection;
    if( xAxis ) gapDirection = vOrig.y > 0 ? ERDirUp : ERDirDown;  // if vy == 0, check for down gaps.
    else        gapDirection = vOrig.x > 0 ? ERDirRight : ERDirLeft;
    NSArray *gapAbutters = [m_worldFrameCache lazyGetAbuttListForSO:node inER:m_elbowRoom direction:gapDirection];
    if( [gapAbutters count] == 0 ) return targetOffset;
    
    // assumption: the common case for typical values of physics constants is that we only risk skipping over a gap
    //  if we are on the edge of one block and about to move over the gap. so assume that we'll only be able to skip a
    //  gap if we are on top of exactly one block.
    // this isn't always true, for example if we are moving very fast or if the blocks are very small.
    // don't count group SOs here (else we'd never have exactly 1 abutter if we were standing on a group, since
    //  both group and element blocks are in this list).
    int nonGroupAbutters = 0;
    int firstAbutterIndex = -1;  // not counting groups in the list
    for( int i = 0; i < [gapAbutters count]; ++i )
    {
        ASolidObject *thisAbuttSO = (ASolidObject *)[gapAbutters objectAtIndex:i];
        if( [thisAbuttSO isGroup] ) continue;
        if( firstAbutterIndex == -1 ) firstAbutterIndex = i;
        if( ++nonGroupAbutters > 1 ) break;
    }
    if( nonGroupAbutters != 1 ) return targetOffset;
    
    // we have the preliminary conditions for a gap switch, now do math to see if we will hit the gap this frame.
    NSAssert( firstAbutterIndex != -1, @"gap check abutter index fail." );
    ASolidObject *gapAbutter = (ASolidObject *)[gapAbutters objectAtIndex:firstAbutterIndex];
    if( [gapAbutter isGroup] )
    {
        NSAssert( NO, @"supposed to be skipping groups during gap check." );
        return targetOffset;
    }
    
    Block *thisBlock = (Block *)node;
    Block *gapBlock = (Block *)gapAbutter;
    Emu result;
    switch( gapDirection )
    {
        case ERDirDown:
        case ERDirUp:
            if( targetOffset < 0 )  // left
            {
                result = MAX( targetOffset, MIN( 0, gapBlock.x - (thisBlock.x + thisBlock.w) ) );
            }
            else                    // right
            {
                result = MIN( targetOffset, MAX( 0, gapBlock.x + gapBlock.w - thisBlock.x ) );
            }
            break;
        case ERDirLeft:
        case ERDirRight:
            if( targetOffset < 0 )  // down
            {
                result = MAX( targetOffset, MIN( 0, gapBlock.y - (thisBlock.y + thisBlock.h) ) );
            }
            else                    // up
            {
                result = MIN( targetOffset, MAX( 0, gapBlock.y + gapBlock.h - thisBlock.y ) );
            }
            break;
        default: NSAssert( NO, @"unknown direction." ); return 0;
    }
    *outStoppedForGap = (result != targetOffset);
    return result;
}


-(Emu)performMoveForNode:(ASolidObject *)node targetOffset:(Emu)targetOffset isXAxis:(BOOL)xAxis outStoppedForGap:(BOOL *)outStoppedForGap
{
    NSAssert( [node getProps].canMoveFreely, @"only moveable blocks allowed." );
    *outStoppedForGap = NO;  // assume we don't hit any gaps (can be overridden in checkPerpGapsForNode:)
    
    ERDirection dir = xAxis ? ( targetOffset > 0 ? ERDirRight : ERDirLeft ) :
    ( targetOffset > 0 ? ERDirUp : ERDirDown );
    
    Emu elbowRoomThisDir = [self.elbowRoom getElbowRoomForSO:node inDirection:dir];      // unsigned
    Emu actualMoveThisFrame = MIN( ABS( targetOffset ), elbowRoomThisDir );              // unsigned
    Emu actualOffsetThisFrame = actualMoveThisFrame * ( (targetOffset < 0) ? -1 : 1 );   // signed
    
    // TODO revisit this. as written this doesn't account for all cases where there could be new abutters.
    //                    example: player walks horizontally onto a new block, they were moving in x only
    //                    but now have a new down abutter. not sure if this matters or not.
    BOOL fNewAbutters = (actualMoveThisFrame == elbowRoomThisDir) && (actualMoveThisFrame != 0);
    if( fNewAbutters )
    {
        while( YES )
        {
            Block *thisAbutter = [self.elbowRoom popCollider];
            if( thisAbutter == nil ) break;
            if( [thisAbutter getProps].canMoveFreely )
            {
                [m_worldFrameCache ensureEntryForSO:thisAbutter].newAbuttersThisFrame = YES;
            }
        }
    }
    
    if( [node isGroup] )
    {
        BlockGroup *thisGroup = (BlockGroup *)node;
        for( int i = 0; i < [thisGroup.blocks count]; ++i )
        {
            Block *thisBlock = (Block *)[thisGroup.blocks objectAtIndex:i];
            actualOffsetThisFrame = [self checkPerpGapsForNode:thisBlock targetOffset:actualOffsetThisFrame isXAxis:xAxis outStoppedForGap:outStoppedForGap];
        }
    }
    else
    {
        actualOffsetThisFrame = [self checkPerpGapsForNode:node targetOffset:actualOffsetThisFrame isXAxis:xAxis outStoppedForGap:outStoppedForGap];
    }
    
    [node changePositionOnXAxis:xAxis signedMoveOffset:actualOffsetThisFrame elbowRoom:self.elbowRoom];
    
    //NSLog( @"changed position on %@ axis by %d, elbowRoom was %d", (xAxis ? @"x" : @"y"), actualOffsetThisFrame, elbowRoomThisDir );
    
    return actualOffsetThisFrame;
}


-(BOOL)groupLoopCheckOkForSO:(ASolidObject *)solidObject stack:(NSMutableArray *)groupPropStack
{
    if( ![solidObject isGroup] )
    {
        return YES;
    }
    BlockGroup *testGroup = (BlockGroup *)solidObject;
    for( int i = 0; i < [groupPropStack count]; ++i )
    {
        NSNumber *thisGroupId = (NSNumber *)[groupPropStack objectAtIndex:i];
        if( thisGroupId.unsignedIntValue == testGroup.groupId )
        {
            return NO;
        }
    }
    return YES;
}


// sometimes blocks can be exempt from bouncing when they otherwise would.
// currently this happens when an actor is doing a hop.
-(BOOL)isBounceExempt:(ASolidObject *)solidObject inDir:(ERDirection)dir
{
    if( ![solidObject getProps].isActorBlock )
    {
        return NO;
    }
    ActorBlock *thisActorBlock = (ActorBlock *)solidObject;
    if( ![thisActorBlock.owningActor canHop] )
    {
        return NO;
    }

    NSArray *abutters = [m_worldFrameCache lazyGetAbuttListForSO:solidObject inER:m_elbowRoom direction:dir];
    for( int i = 0; i < [abutters count]; ++i )
    {
        ASolidObject *thisAbutter = (ASolidObject *)[abutters objectAtIndex:i];
        if ( [thisAbutter getProps].isHopBlock ) {
            return YES;
        }
    }
    return NO;
}


// returns actual move offset
// parameter isPerpProp controls whether we are handling the perpendicular drag propagation
//   (if so, avoid doing parallel propagation again to cut down on weird jittery effects...still not perfect)
// param depth is unused for now.
-(Emu)doRecurseForNode:(ASolidObject *)node targetOffset:(Emu)targetOffset isXAxis:(BOOL)xAxis isPerpProp:(BOOL)perpProp isOppParaProp:(BOOL)oppParaProp
                                            originSO:(ASolidObject *)originSO groupPropStack:(NSMutableArray *)groupPropStack depth:(int)depth
{
    if( ![node getProps].canMoveFreely )
    {
        return 0;
    }
    if( targetOffset == 0 )
    {
        if( xAxis ) return 0;
        if( ![node getProps].affectedByGravity ) return 0;
        // else for y, need to check down collision special case with targetOffset == 0 (gravity blocks only)
    }
    
    // handle group checks to prevent group loop.
    if( ![self groupLoopCheckOkForSO:node stack:groupPropStack] )
    {
        return 0;
    }
    if( [node isGroup] )
    {
        BlockGroup *thisGroup = (BlockGroup *)node;
        [groupPropStack addObject:[NSNumber numberWithUnsignedInt:thisGroup.groupId]];
    }
    
    int nodeWeight = [node getProps].weight;
    
    // handle parallel propagation
    BOOL didBounce = NO;
    if( !perpProp && !oppParaProp )
    {
        NSArray *paraAbuttList;
        ERDirection dir;
        if( targetOffset > 0 )
        {
            dir = xAxis ? ERDirRight : ERDirUp;
            paraAbuttList = [m_worldFrameCache lazyGetAbuttListForSO:node inER:m_elbowRoom direction:dir];
        }
        else
        {
            dir = xAxis ? ERDirLeft : ERDirDown;  // including targetOffset == 0
            paraAbuttList = [m_worldFrameCache lazyGetAbuttListForSO:node inER:m_elbowRoom direction:dir];
        }

        Emu attTargetOffset = targetOffset * 1;  // future: some attenuation here?
        for( int i = 0; i < [paraAbuttList count]; ++i )
        {
            ASolidObject *thisAbutter = (ASolidObject *)[paraAbuttList objectAtIndex:i];
            
            // skip group elements since they'll be handled via owning group.
            if( [thisAbutter isGroupElement] ) continue;
            
            if( targetOffset != 0 )
            {
                // compare weights to see if this node is heavy enough to push the abutter.
                int abutterWeight = [thisAbutter getProps].weight;
                if( abutterWeight != IMMOVABLE_WEIGHT && nodeWeight >= abutterWeight )
                {
                    [self doRecurseForNode:thisAbutter targetOffset:attTargetOffset isXAxis:xAxis isPerpProp:NO isOppParaProp:NO
                                  originSO:originSO groupPropStack:groupPropStack depth:(depth + 1)];
                }
            }
        }

        [self accumulatePropsForList:paraAbuttList];
        for( int i = 0; i < [paraAbuttList count]; ++i )
        {
            ASolidObject *thisAbutter = (ASolidObject *)[paraAbuttList objectAtIndex:i];
            didBounce = [self collisionBetween:node and:thisAbutter inDir:dir overrideProps:m_propsAccumulator] || didBounce;
        }
    }
    
    // we've had a chance to check for collisions in the y-axis-but-zero-targetOffset case, so finish early if we can.
    if( targetOffset == 0 )
    {
        return 0;
    }

    // special case for things moving downward:
    //   we'll also do a parallel recurse to abutters in the opposite direction, only if we are moving down.
    //   this is a "pull" instead of a push. the reason we do this is to avoid the case where somebody
    //   standing on top of us repeatedly falls from vy=0 until they bump into us (some distance below them).
    //   only do this if the opposite parallel abutter is affected by gravity and if we aren't moving too fast.
    //   if we are moving too fast, it's appropriate for them to fall from vy=0.
    //   note: need to cache the up abutt list now (before moving), then recurse it after moving so the abutters
    //   have room to move. this assumes that the cache doesn't change when we performMove.
    //   in other words we have an assumption here that the cache is stale :(
    NSArray *oppParaAbuttList = nil;
    if( !perpProp && !xAxis && targetOffset < 0 && targetOffset > PULL_DOWN_THRESHOLD )
    {
        oppParaAbuttList = [m_worldFrameCache lazyGetAbuttListForSO:node inER:m_elbowRoom direction:ERDirUp];
    }
    
    // perform the actual move!
    BOOL fStoppedForGap;
    Emu didMoveOffset = [self performMoveForNode:node targetOffset:targetOffset isXAxis:xAxis outStoppedForGap:&fStoppedForGap];
    
    // cheesy: recurse again if we just bumped into something without completing our desired move (for player only).
    //         this helps situations where we can't push a block while riding a conveyor or platform since the
    //         block doesn't register as an abutter if it moves away from us slightly mid-frame.
    if( didMoveOffset != targetOffset && didMoveOffset != 0 && targetOffset != 0 && [node getProps].isPlayerBlock )
    {
        // nuke cached abutters since we probably have new ones now.
        ERDirection dir;
        if( targetOffset > 0 )
        {
            dir = xAxis ? ERDirRight : ERDirUp;
        }
        else
        {
            dir = xAxis ? ERDirLeft : ERDirDown;
        }
        [[m_worldFrameCache ensureEntryForSO:node] clearAbuttListForDirection:dir];

        Emu remainder = targetOffset - didMoveOffset;
        return [self doRecurseForNode:node targetOffset:remainder isXAxis:xAxis isPerpProp:perpProp
                 isOppParaProp:oppParaProp originSO:originSO groupPropStack:groupPropStack depth:(depth + 1)];
    }
    
    // if we newly gain abutters, wait a frame before bouncing. This allows us to observe an "opposing motive"
    //  bounce with higher priority (by checking earlier next frame than "true" bounce).
    // don't run this check if we had cut our movement short due to gap checks, because that means we haven't
    //  actually hit anything and so we shouldn't run bounce code.
    // TODO: verify newAbuttersThisFrame is still necessary and correct. Seems a little suspish.
    // TODO: might need additional logic here for hops, to prevent bouncing if a hop occurred.
    if( !fStoppedForGap && didMoveOffset == 0 && ![m_worldFrameCache ensureEntryForSO:node].newAbuttersThisFrame )
    {
        ERDirection dir;
        if( targetOffset > 0 )
        {
            dir = xAxis ? ERDirRight : ERDirUp;
        }
        else
        {
            dir = xAxis ? ERDirLeft : ERDirDown;
        }

        if( !didBounce && ![self isBounceExempt:node inDir:dir] )
        {
            [m_worldFrameCache tryBounceNode:node onXAxis:xAxis];
        }
        
        // no movement, so nothing to propagate to perpendicular.
        return 0;
    }
    
    // did we save opposite parallel abutters from above, before performMove?
    if( oppParaAbuttList != nil )
    {
        for( int i = 0; i < [oppParaAbuttList count]; ++i )
        {
            ASolidObject *thisAbutter = (ASolidObject *)[oppParaAbuttList objectAtIndex:i];
            
            // skip group elements since they'll be handled via owning group.
            if( [thisAbutter isGroupElement] ) continue;
            
            if( targetOffset != 0 )
            {
                // don't pull things on y if they aren't affected by gravity.
                if( [thisAbutter getProps].affectedByGravity )
                {
                    [self doRecurseForNode:thisAbutter targetOffset:didMoveOffset isXAxis:xAxis isPerpProp:NO isOppParaProp:YES
                                  originSO:originSO groupPropStack:groupPropStack depth:(depth + 1)];
                }
            }
        }
    }
    
    // if we're in an opposite parallel recurse, we're done now.
    if( oppParaProp )
    {
        return didMoveOffset;
    }
    
    // special logic for x movement "dragging" things stacked on top.
    // doesn't apply to player because it's annoying.
    if( !xAxis || [node getProps].isPlayerBlock )
    {
        return didMoveOffset;
    }
    
    // handle perpendicular propagation
    Emu thisAbutterDidMove;
    NSArray *upAbuttList = [m_worldFrameCache lazyGetAbuttListForSO:node inER:m_elbowRoom direction:ERDirUp];
    for( int i = 0; i < [upAbuttList count]; ++i )
    {
        ASolidObject *thisAbutter = (ASolidObject *)[upAbuttList objectAtIndex:i];
        if( ![thisAbutter getProps].canMoveFreely || ![thisAbutter getProps].affectedByGravity )
        {
            continue;
        }
        
        // skip group elements since they'll be handled via owning group.
        if( [thisAbutter isGroupElement] ) continue;
        
        // some blocks just can't be dragged.
        if( [thisAbutter getProps].weight == IMMOVABLE_WEIGHT ) continue;
        
        // prevent multiple blocks from contributing up drag velocity to the same block by keeping
        // track of how much we've already applied this frame.
        WorldFrameCacheEntry *thisAbutterCacheEntry = [self.frameCache ensureEntryForSO:thisAbutter];
        Emu moveOffsetDifference = 0;
        // owningSO check helps the case where a block is getting perpProp from more than one propagation stack,
        //  e.g. player pushing against a stack of blocks on a conveyor.
        if( thisAbutterCacheEntry.gravityTallyOwningSO != originSO )
        {
            thisAbutterCacheEntry.gravityTallyOwningSO = originSO;
            thisAbutterCacheEntry.gravityTallyForFrameSoFar = 0;
        }
        if( didMoveOffset > 0 )
        {
            if( didMoveOffset > thisAbutterCacheEntry.gravityTallyForFrameSoFar )
            {
                moveOffsetDifference = didMoveOffset - thisAbutterCacheEntry.gravityTallyForFrameSoFar;
                thisAbutterCacheEntry.gravityTallyForFrameSoFar = didMoveOffset;
            }
        }
        else
        {
            if( didMoveOffset < thisAbutterCacheEntry.gravityTallyForFrameSoFar )
            {
                moveOffsetDifference = didMoveOffset - thisAbutterCacheEntry.gravityTallyForFrameSoFar;
                thisAbutterCacheEntry.gravityTallyForFrameSoFar = didMoveOffset;
            }
        }
        
        if( moveOffsetDifference != 0 )
        {
            thisAbutterDidMove = [self doRecurseForNode:thisAbutter targetOffset:moveOffsetDifference isXAxis:YES isPerpProp:YES isOppParaProp:NO
                                               originSO:originSO groupPropStack:groupPropStack depth:(depth + 1)];
        }
    }
    
    return didMoveOffset;
}


// handle fixed (non-accelerating, non-accumulating) velocity adjustments here.
// main example is conveyors.
-(EmuPoint)getVOffsetForSO:(ASolidObject *)solidObject
{
    if( ![solidObject getProps].affectedByGravity )
    {
        return EmuPointMake( 0, 0 );
    }
    
    // check for conveyor abutters.
    Emu xConveyorContribution = 0;
    NSArray *downAbutters = [m_worldFrameCache lazyGetAbuttListForSO:solidObject inER:m_elbowRoom direction:ERDirDown];
    for( int i = 0; i < [downAbutters count]; ++i )
    {
        ASolidObject *thisAbutter = (ASolidObject *)[downAbutters objectAtIndex:i];
        Emu thisXConveyor = [thisAbutter getProps].xConveyor;
        if( thisXConveyor == 0 )
        {
            continue;
        }
        else if( thisXConveyor > 0 )
        {
            xConveyorContribution = MIN( xConveyorContribution + thisXConveyor, thisXConveyor );
        }
        else // thisXConveyor < 0
        {
            xConveyorContribution = MAX( xConveyorContribution + thisXConveyor, thisXConveyor );
        }
    }
    return EmuPointMake( xConveyorContribution, 0 );
}


// special case: when moving in x axis, check if we are standing on any groups and if so,
//  add those groups to the groupPropStack before doing the main x movement recursion.
// the overall effect is that we can't push groups we are standing on.
-(void)checkExemptGroupsForNode:(ASolidObject *)node forStack:(NSMutableArray *)stack
{
    NSArray *downAbutters = [m_worldFrameCache lazyGetAbuttListForSO:node inER:m_elbowRoom direction:ERDirDown];
    for( int i = 0; i < [downAbutters count]; ++i )
    {
        ASolidObject *thisAbutter = (ASolidObject *)[downAbutters objectAtIndex:i];
        if( [thisAbutter isGroup] )
        {
            BlockGroup *thisGroup = (BlockGroup *)thisAbutter;
            [stack addObject:[NSNumber numberWithUnsignedInt:thisGroup.groupId]];
        }
    }
}


// override
-(void)updateSolidObject:(ASolidObject *)solidObject withTimeDelta:(float)delta
{
    if( ![solidObject getProps].canMoveFreely )
    {
        return;
    }
    
    EmuPoint vSO = [solidObject getV];
    EmuPoint vOffset = [self getVOffsetForSO:solidObject];
    
    // why are we doing y first here?
    // this is required by an optimization I made such that objects at rest no longer get small downward v at gravityUpdater.
    // if they have no v, we can skip useless propagate work here. the problem was that without downward v, the gap checker
    // logic wasn't working correctly. so the way it works now is, gap checker logic no longer cares about downward v, it
    // always checks (for horizontally moving objects). so an object will end a frame over a gap if it would have otherwise
    // passed over. then gravity will see nothing below that object at the start of next frame, and apply down v. so for this
    // frame, the object is ready to fall into the gap. if we would compute x propagate first, they would just move over the
    // gap and their down v would never be acted on. so compute y first so that we have a chance to act on this one-frame-only
    // downv. gaps in other directions are fine since they really do carry v in that direction (no gravity optimization special
    // case).
    
    if( YES )  // still check y even if v is 0, otherwise we miss downward collision detection.
    {
        [m_groupPropStack removeAllObjects];
        
        Emu targetOffset = (vSO.y + vOffset.y) * delta;
        [self doRecurseForNode:solidObject targetOffset:targetOffset isXAxis:NO isPerpProp:NO isOppParaProp:NO originSO:solidObject groupPropStack:m_groupPropStack depth:0];
    }
    if( (vSO.x + vOffset.x) != 0 )
    {
        [m_groupPropStack removeAllObjects];
        [self checkExemptGroupsForNode:solidObject forStack:m_groupPropStack];
        
        Emu targetOffset = (vSO.x + vOffset.x) * delta;
        [self doRecurseForNode:solidObject targetOffset:targetOffset isXAxis:YES isPerpProp:NO isOppParaProp:NO originSO:solidObject groupPropStack:m_groupPropStack depth:0];
    }
}

@end
