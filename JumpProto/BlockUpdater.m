//
//  BlockUpdater.m
//  JumpProto
//
//  Created by gideong on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockUpdater.h"
#import "constants.h"
#import "DebugLogLayerView.h"
#import "gutil.h"
#import "BlockGroup.h"
#import "World.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// BlockUpdater

@implementation BlockUpdater

-(void)updateSolidObject:(ASolidObject *)solidObject withTimeDelta:(float)delta
{
    
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ERBlockUpdater

@implementation ERBlockUpdater

@synthesize elbowRoom = m_elbowRoom;

-(id)initWithElbowRoom:(NSObject<IElbowRoom> *)elbowRoomIn
{
    if( self = [super init] )
    {
        self.elbowRoom = elbowRoomIn;
    }
    return self;
}


-(void)dealloc
{
    self.elbowRoom = nil;
    [super dealloc];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ERFrameCacheBlockUpdater

@implementation ERFrameCacheBlockUpdater

@synthesize frameCache = m_worldFrameCache;

-(id)initWithElbowRoom:(NSObject<IElbowRoom> *)elbowRoomIn frameCache:(WorldFrameCache *)frameCacheIn
{
    if( self = [super initWithElbowRoom:elbowRoomIn] )
    {
        self.frameCache = frameCacheIn;
    }
    return self;
}


-(void)dealloc
{
    self.frameCache = nil;
    [super dealloc];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldBlockUpdater

@implementation WorldBlockUpdater

@synthesize world;

-(id)initWithWorld:(World *)worldIn
{
    if( self = [super init] )
    {
        self.world = worldIn;  // weak
    }
    return self;
}


-(void)dealloc
{
    self.world = nil;
    [super dealloc];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// FrameCacheClearerUpdater

@implementation FrameCacheClearerUpdater

// override
-(void)updateSolidObject:(ASolidObject *)solidObject withTimeDelta:(float)delta
{
    if( ![solidObject getProps].canMoveFreely )
    {
        return;
    }
    [m_worldFrameCache resetForSO:solidObject];
    
    // since we also record abutters for individual elements (for gap check purposes), clear those lists too.
    if( [solidObject isGroup] )
    {
        BlockGroup *thisGroup = (BlockGroup *)solidObject;
        for( int i = 0; i < [thisGroup.blocks count]; ++i )
        {
            Block *thisElement = (Block *)[thisGroup.blocks objectAtIndex:i];
            [m_worldFrameCache resetForSO:thisElement];
        }
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ApplyMotiveUpdater

@implementation ApplyMotiveUpdater

// override
-(void)updateSolidObject:(ASolidObject *)solidObject withTimeDelta:(float)delta
{
    if( ![solidObject getProps].canMoveFreely )
    {
        return;
    }

    EmuPoint maxVDueToMotive = [solidObject getMotive];  // signed, includes actors (via actorBlock)
    if( maxVDueToMotive.x == 0 && maxVDueToMotive.y == 0 )
    {
        return;
    }
    
    const EmuPoint vOrig = [solidObject getV];
    const EmuPoint motiveAccel = [solidObject getMotiveAccel];
    
    Emu xComponent = vOrig.x;
    if( maxVDueToMotive.x > 0 )
    {
        if( vOrig.x < maxVDueToMotive.x )
        {
            xComponent = MIN( maxVDueToMotive.x, delta * motiveAccel.x + vOrig.x );
        }
    }
    else if( maxVDueToMotive.x < 0 )
    {
        if( vOrig.x > maxVDueToMotive.x )
        {
            xComponent = MAX( maxVDueToMotive.x, -1 * delta * motiveAccel.x + vOrig.x );
        }
    }
    
    Emu yComponent = vOrig.y;
    if( maxVDueToMotive.y > 0 )
    {
        if( vOrig.y < maxVDueToMotive.y )
        {
            yComponent = MIN( maxVDueToMotive.y, delta * motiveAccel.y + vOrig.y );
        }
    }
    else if( maxVDueToMotive.y < 0 )
    {
        if( vOrig.y > maxVDueToMotive.y )
        {
            yComponent = MAX( maxVDueToMotive.y, -1 * delta * motiveAccel.y + vOrig.y );
        }
    }

    [solidObject setV:EmuPointMake( xComponent, yComponent ) ];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ApplyGravityMotiveUpdater

@implementation ApplyGravityMotiveUpdater

// override
-(void)updateSolidObject:(ASolidObject *)solidObject withTimeDelta:(float)delta
{
    const BlockProps *blockProps = [solidObject getProps];
    if( !blockProps.canMoveFreely || !blockProps.affectedByGravity )
    {
        return;
    }
    
    const EmuPoint vOrig = [solidObject getV];
    NSArray *downAbutters = [m_worldFrameCache lazyGetAbuttListForSO:solidObject inER:m_elbowRoom direction:ERDirDown];
    
    Emu yComponent = 0;  // default to vy = 0 unless there's nothing stopping us from falling.
    if( [downAbutters count] == 0 || vOrig.y > 0 )
    {
        Emu maxVDueToGravity = TERMINAL_VELOCITY;

        // this may change if we have flippable/offable gravity
        NSAssert( GRAVITY_CONSTANT <  0, @"for now I assume gravity goes downward" );
        NSAssert( maxVDueToGravity <= 0, @"for now I assume gravity goes downward" );
        yComponent = vOrig.y;
        if( vOrig.y > maxVDueToGravity )
        {
            yComponent = delta * GRAVITY_CONSTANT + vOrig.y;
        }
        else
        {
            yComponent = maxVDueToGravity;
        }
    }
    
    [solidObject setV:EmuPointMake( vOrig.x, yComponent ) ];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// GravFrictionUpdater

@implementation GravFrictionUpdater

// override
-(void)updateSolidObject:(ASolidObject *)solidObject withTimeDelta:(float)delta
{
    if( ![solidObject getProps].affectedByFriction )
    {
        //NSLog( @"!affectedByFriction for block %u.", (unsigned int)[solidObject getProps].token );
        return;
    }

    // select friction coefficient. Still apply friction in air (only less)
    float decel = GROUND_FRICTION_DECEL;  // could depend on downBlock props (e.g. ice)
    NSArray *downBlockList = [m_worldFrameCache lazyGetAbuttListForSO:solidObject inER:m_elbowRoom direction:ERDirDown];
    if( [downBlockList count] == 0 )
    {
        decel = AIR_FRICTION_DECEL;
    }
    
    Emu newVX;

    EmuPoint v = [solidObject getV];
    newVX = ABS( v.x );
    newVX = MAX( newVX - (decel * delta), 0 );
    newVX = newVX * (v.x > 0 ? 1 : -1 );
    [solidObject setV:EmuPointMake( newVX, v.y )];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// PropagateMovementUpdater

@implementation PropagateMovementUpdater

-(id)initWithElbowRoom:(NSObject<IElbowRoom> *)elbowRoom frameCache:(WorldFrameCache *)frameCacheIn
{
    if( self = [super initWithElbowRoom:elbowRoom frameCache:frameCacheIn] )
    {
        m_groupPropStack = [[NSMutableArray arrayWithCapacity:4] retain];
    }
    return self;
}


-(void)dealloc
{
    [m_groupPropStack release]; m_groupPropStack = nil;
    [super dealloc];
}


-(BOOL)collisionBetween:(ASolidObject *)nodeA and:(ASolidObject *)nodeB inDir:(ERDirection)dir
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
    BOOL didABounce = [nodeA collidedInto:nodeB inDir:dir];
    BOOL didBBounce = [nodeB collidedInto:nodeA inDir:opposingDir];
    return didABounce || didBBounce;
}


// implement "gap check" (aka one-hole-down) logic. this is required so that we can avoid skipping entirely
//  over small gaps in the opposing axis. we detect if we are on the edge of a gap, and if so, limit the
//  target offset so that we end the turn directly over the gap, instead of moving beyond it.
// this method makes a distinction between group SOs and their element blocks. we only want to check
//  gaps against elements.
-(Emu)checkPerpGapsForNode:(ASolidObject *)node targetOffset:(Emu)targetOffset isXAxis:(BOOL)xAxis
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
    switch( gapDirection )
    {
        case ERDirDown:
        case ERDirUp:
            if( targetOffset < 0 )  // left
            {
                return MAX( targetOffset, MIN( 0, gapBlock.x - (thisBlock.x + thisBlock.w) ) );
            }
            else                    // right
            {
                return MIN( targetOffset, MAX( 0, gapBlock.x + gapBlock.w - thisBlock.x ) );
            }
        case ERDirLeft:
        case ERDirRight:
            if( targetOffset < 0 )  // down
            {
                return MAX( targetOffset, MIN( 0, gapBlock.y - (thisBlock.y + thisBlock.h) ) );
            }
            else                    // up
            {
                return MIN( targetOffset, MAX( 0, gapBlock.y + gapBlock.h - thisBlock.y ) );
            }
        default: NSAssert( NO, @"unknown direction." ); return 0;
    }
}


-(Emu)performMoveForNode:(ASolidObject *)node targetOffset:(Emu)targetOffset isXAxis:(BOOL)xAxis
{
    NSAssert( [node getProps].canMoveFreely, @"only moveable blocks allowed." );
    
    ERDirection dir = xAxis ? ( targetOffset > 0 ? ERDirRight : ERDirLeft ) :
                              ( targetOffset > 0 ? ERDirUp : ERDirDown );

    NSArray *abuttList;
    Emu elbowRoomThisDir = [self.elbowRoom getElbowRoomForSO:node inDirection:dir
                                           outCollidingEdgeList:&abuttList];             // unsigned
    Emu actualMoveThisFrame = MIN( ABS( targetOffset ), elbowRoomThisDir );              // unsigned
    Emu actualOffsetThisFrame = actualMoveThisFrame * ( (targetOffset < 0) ? -1 : 1 );   // signed
    
    // TODO revisit this. as written this doesn't account for all cases where there could be new abutters.
    //                    example: player walks horizontally onto a new block, they were moving in x only
    //                    but now have a new down abutter. not sure if this matters or not.
    BOOL fNewAbutters = (actualMoveThisFrame == elbowRoomThisDir) && (actualMoveThisFrame != 0);
    if( fNewAbutters )
    {
        for( int i = 0; i < [abuttList count]; ++i )
        {
            Block *thisAbutter = ((EREdge *)[abuttList objectAtIndex:i]).block;
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
            actualOffsetThisFrame = [self checkPerpGapsForNode:thisBlock targetOffset:actualOffsetThisFrame isXAxis:xAxis];
        }
    }
    else
    {
        actualOffsetThisFrame = [self checkPerpGapsForNode:node targetOffset:actualOffsetThisFrame isXAxis:xAxis];
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


// returns actual move offset
// parameter isPerpProp controls whether we are handling the perpendicular drag propagation
//   (if so, avoid doing parallel propagation again to cut down on weird jittery effects...still not perfect)
-(Emu)doRecurseForNode:(ASolidObject *)node targetOffset:(Emu)targetOffset isXAxis:(BOOL)xAxis isPerpProp:(BOOL)perpProp
                                            originSO:(ASolidObject *)originSO groupPropStack:(NSMutableArray *)groupPropStack
{
    if( ![node getProps].canMoveFreely || targetOffset == 0 )
    {
        return 0;
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
    
    BOOL didBounce = NO;
    if( !perpProp )
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
            dir = xAxis ? ERDirLeft : ERDirDown;
            paraAbuttList = [m_worldFrameCache lazyGetAbuttListForSO:node inER:m_elbowRoom direction:dir];
        }
        Emu attTargetOffset = targetOffset * 1;  // future: some attenuation here?
        for( int i = 0; i < [paraAbuttList count]; ++i )
        {
            ASolidObject *thisAbutter = (ASolidObject *)[paraAbuttList objectAtIndex:i];
            
            // skip group elements since they'll be handled via owning group.
            if( [thisAbutter isGroupElement] ) continue;
            
            // don't push things on y if they aren't affected by gravity (e.g. floating platforms, which should stay floating).
            if( xAxis || [thisAbutter getProps].affectedByGravity )
            {
                [self doRecurseForNode:thisAbutter targetOffset:attTargetOffset isXAxis:xAxis isPerpProp:NO
                              originSO:originSO groupPropStack:groupPropStack];
            }

            didBounce = didBounce || [self collisionBetween:node and:thisAbutter inDir:dir];
        }
    }

    Emu didMoveOffset = [self performMoveForNode:node targetOffset:targetOffset isXAxis:xAxis];

    // if we newly gain abutters, wait a frame before bouncing. This allows us to observe an "opposing motive"
    //  bounce with higher priority (by checking earlier next frame than "true" bounce).
    if( didMoveOffset == 0 && ![m_worldFrameCache ensureEntryForSO:node].newAbuttersThisFrame )
    {
        if( !didBounce )
        {
            [node bouncedOnXAxis:xAxis];
        }
        
        // no movement, so nothing to propagate to perpendicular.
        return 0;
    }
    
    // special logic for x movement "dragging" things stacked on top.
    // doesn't apply to player because it's annoying.
    if( !xAxis || [node getProps].isPlayerBlock )
    {
        return didMoveOffset;
    }
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
            thisAbutterDidMove = [self doRecurseForNode:thisAbutter targetOffset:moveOffsetDifference isXAxis:YES isPerpProp:YES
                                               originSO:originSO groupPropStack:groupPropStack];
        }
    }
    
    return didMoveOffset;
}


// handle fixed (non-accelerating, non-accumulating) velocity adjustments here.
// main example is conveyors.
// TODO: moving platforms currently are affected by conveyors, probably need a props.affectByGravity check in here.
-(EmuPoint)getVOffsetForSO:(ASolidObject *)solidObject
{
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
    
    if( (vSO.y + vOffset.y) != 0 )
    {
        [m_groupPropStack removeAllObjects];

        Emu targetOffset = (vSO.y + vOffset.y) * delta;
        [self doRecurseForNode:solidObject targetOffset:targetOffset isXAxis:NO isPerpProp:NO originSO:solidObject groupPropStack:m_groupPropStack];
    }
    if( (vSO.x + vOffset.x) != 0 )
    {
        [m_groupPropStack removeAllObjects];
        [self checkExemptGroupsForNode:solidObject forStack:m_groupPropStack];
        
        Emu targetOffset = (vSO.x + vOffset.x) * delta;
        [self doRecurseForNode:solidObject targetOffset:targetOffset isXAxis:YES isPerpProp:NO originSO:solidObject groupPropStack:m_groupPropStack];
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// OpposingMotiveUpdater

@implementation OpposingMotiveUpdater

-(void)checkSolidObject:(ASolidObject *)solidObject dir:(ERDirection)dir
{
    NSArray *abutters = [m_worldFrameCache lazyGetAbuttListForSO:solidObject inER:m_elbowRoom direction:dir];
    for( int i = 0; i < [abutters count]; ++i )
    {
        ASolidObject *thisAbutter = (ASolidObject *)[abutters objectAtIndex:i];
        EmuPoint abutterMotive = [thisAbutter getMotive];

        // note: this check is vague about sign because we may have already
        //  flipped one of the two SOs earlier in the updater loop, but we still need
        //  to handle the other side of the collision correctly.
        BOOL fOpposingMotive = NO;
        switch( dir )
        {
            case ERDirLeft:  fOpposingMotive = (abutterMotive.x != 0); break;
            case ERDirRight: fOpposingMotive = (abutterMotive.x != 0); break;
            case ERDirUp:    fOpposingMotive = (abutterMotive.y != 0); break;
            case ERDirDown:  fOpposingMotive = (abutterMotive.y != 0); break;
            default: NSAssert( NO, @"unexpected" ); break;
        }
        if( fOpposingMotive )
        {
            // note: assume that the opposee will take care of this check from its perspective, during its turn.
            BOOL xAxis = (dir == ERDirLeft || dir == ERDirRight);
            [solidObject bouncedOnXAxis:xAxis];
            return;  // only bounce at most once per frame.
        }
    }
}


// override
-(void)updateSolidObject:(ASolidObject *)solidObject withTimeDelta:(float)delta
{
    EmuPoint motive = [solidObject getMotive];
    if( motive.x == 0 && motive.y == 0 )
    {
        return;
    }

    if( motive.x != 0 )
    {
        [self checkSolidObject:solidObject dir:(motive.x < 0 ? ERDirLeft : ERDirRight)];
    }
    if( motive.y != 0 )
    {
        [self checkSolidObject:solidObject dir:(motive.y < 0 ? ERDirDown : ERDirUp)];
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteStateUpdater

@implementation SpriteStateUpdater

// just update every individual spriteState in the map.
+(void)updateSpriteMapForBlock:(SpriteBlock *)block withTimeDelta:(float)delta
{
    for( int y = 0; y < block.spriteStateMap.size.height; ++y )
        for( int x = 0; x < block.spriteStateMap.size.width; ++x )
            [[block.spriteStateMap getSpriteStateAtX:x y:y] updateWithTimeDelta:delta];
}


// override
-(void)updateSolidObject:(ASolidObject *)solidObject withTimeDelta:(float)delta
{
    if( [solidObject isGroup] )
    {
        BlockGroup *group = (BlockGroup *)solidObject;
        for( int i = 0; i < [group.blocks count]; ++i )
        {
            SpriteBlock *block = (SpriteBlock *)[group.blocks objectAtIndex:i];
            [SpriteStateUpdater updateSpriteMapForBlock:block withTimeDelta:delta];
        }
    }
    else
    {
        SpriteBlock *block = (SpriteBlock *)solidObject;
        [SpriteStateUpdater updateSpriteMapForBlock:block withTimeDelta:delta];
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// BottomOfTheWorldUpdater

@implementation BottomOfTheWorldUpdater

-(BOOL)hasBlockFallenOffWorld:(Block *)block
{
    const Emu cScreenShiftFactor = FlToEmu( 768.f );  // TODO: cheezy, not resolution safe
    return ( block.y + block.h < self.world.yBottom - cScreenShiftFactor );
}


-(void)removeSOFromWorld:(ASolidObject *)solidObject
{
    if( [solidObject getProps].isActorBlock )
    {
        // actor is responsible for cleaning up its block.
        ActorBlock *thisActorBlock = (ActorBlock *)solidObject;
        [thisActorBlock.owningActor onFellOffWorld];
    }
    else
    {
        // let world dispose of us (asynchronously)
        [self.world onSODied:solidObject];
    }
}


// override
-(void)updateSolidObject:(ASolidObject *)solidObject withTimeDelta:(float)delta
{
    if( [solidObject isGroup] )
    {
        BlockGroup *thisGroup = (BlockGroup *)solidObject;
        BOOL allFell = YES;
        for( int i = 0; i < [thisGroup.blocks count]; ++i )
        {
            Block *thisBlock = (Block *)[thisGroup.blocks objectAtIndex:i];
            if( ![self hasBlockFallenOffWorld:thisBlock] )
            {
                allFell = NO;
                break;
            }
        }
        
        // only remove the group if all elements are off bottom.
        // if so, remove everything at once.
        if( allFell )
        {
            [self removeSOFromWorld:thisGroup];  // handles all element blocks.
        }
    }
    else
    {
        Block *thisBlock = (Block *)solidObject;
        if( [self hasBlockFallenOffWorld:thisBlock] )
        {
            [self removeSOFromWorld:thisBlock];
        }
    }
    
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////// BUStats
@implementation BUStats

static BUStats *buStatsStaticInstance = nil;

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
    NSAssert( buStatsStaticInstance == nil, @"BUStats: singleton already initialized." );
    buStatsStaticInstance = [[BUStats alloc] init];
}


+(void)releaseStaticInstance
{
    [buStatsStaticInstance release]; buStatsStaticInstance = nil;    
}


+(BUStats *)instance
{
    return buStatsStaticInstance;
}


-(void)reset
{
    time_velocityUpdater = 0;
    m_timeRemainingBeforeReport = BUSTATS_REPORT_INTERVAL_S;
}


-(void)report
{
    // report all counts in terms of hertz
    // report all times in terms of average ms per second
    int avgTime_velocityUpdater  = (int)roundf( time_velocityUpdater / BUSTATS_REPORT_INTERVAL_S );
    
    NSString *report = [NSString stringWithFormat:@"tVel=%d", avgTime_velocityUpdater];
    
    DebugOut( report );
}


-(void)updateWithTimeDelta:(float)delta
{
#ifdef LOG_BU_STATS
    m_timeRemainingBeforeReport -= delta;
    if( m_timeRemainingBeforeReport <= 0.f )
    {
        [self report];
        [self reset];
    }
#endif
}


-(void)startTimer
{
    m_timerStart = getUpTimeMs();
}


-(int)stopTimer
{
    return (getUpTimeMs() - m_timerStart);    
}


-(void)stopTimer_velocityUpdater
{
    time_velocityUpdater += [self stopTimer];
}


@end


