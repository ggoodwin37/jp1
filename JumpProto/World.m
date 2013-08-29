//
//  World.m
//  JumpProto
//
//  Created by gideong on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "World.h"
#import "DebugLogLayerView.h"
#import "gutil.h"
#import "GlobalCommand.h"
#import "AspectController.h"
#import "constants.h"
#import "ElbowRoomGrid.h"   // concrete impl
#import "PropagateMovementUpdater.h"

// TODO: remove/debug only
#import "WorldTest.h"

@interface World (private)

-(void)initBlockUpdaters;
-(void)initActorUpdaters;
-(void)onGlobalCommand_resetWorld;
-(void)onWorldStarting;

@end


@implementation World

@synthesize levelName = m_levelName, levelDescription = m_levelDescription;
@synthesize elbowRoom = m_elbowRoom;
@synthesize frameCache = m_worldFrameCache;
@synthesize yBottom;

-(id)init
{
    if( self = [super init] )
    {
        [BUStats initStaticInstance];
        
        m_playerActor = nil;
        
        m_worldSOs = [[NSMutableArray arrayWithCapacity:100] retain];
        m_frameStateBlockUpdaters = [[NSMutableArray arrayWithCapacity:10] retain];
        m_updateGraphWorkers = [[NSMutableArray arrayWithCapacity:10] retain];
        m_worldStateBlockUpdaters = [[NSMutableArray arrayWithCapacity:10] retain];
        m_elbowRoom = [[ElbowRoomGrid alloc] init];
        m_groupTable = [[NSMutableDictionary dictionaryWithCapacity:20] retain];
        
        m_worldFrameCache = [[WorldFrameCache alloc] init];
        
        m_npcActors = [[NSMutableArray arrayWithCapacity:10] retain];
        
        m_playerActorUpdaters = [[NSMutableArray arrayWithCapacity:10] retain];
        m_actorUpdaters = [[NSMutableArray arrayWithCapacity:10] retain];
        
        [self initBlockUpdaters];
        [self initActorUpdaters];

        // listen for Reset commands
        [GlobalCommand registerObject:self forNotification:GLOBAL_COMMAND_NOTIFICATION_RESETWORLD   withSel:@selector(onGlobalCommand_resetWorld)];
        [GlobalCommand registerObject:self forNotification:GLOBAL_COMMAND_NOTIFICATION_ADVANCEWORLD withSel:@selector(onGlobalCommand_advanceWorld)];
        
        m_totalDur = 0;
        m_totalUpdates = 0;
        m_timeUntilNextSpeedReport = TIME_BETWEEN_WORLDUPDATE_SPEED_REPORTS;
        
        m_burnFrames = BURN_FRAMES_ON_WORLD_RESET;
        
        m_deadActorsThisFrame = [[NSMutableArray arrayWithCapacity:8] retain];
        m_deadSOsThisFrame = [[NSMutableArray arrayWithCapacity:8] retain];
     }
    return self;
}


-(void)dealloc
{
    self.levelName = nil;
    self.levelDescription = nil;
    
    [m_deadActorsThisFrame release]; m_deadActorsThisFrame = nil;
    [m_deadSOsThisFrame release]; m_deadSOsThisFrame = nil;
    
    [GlobalCommand unregisterObject:self];
    
    [m_actorUpdaters release]; m_actorUpdaters = nil;
    [m_playerActorUpdaters release]; m_playerActorUpdaters = nil;
    
    [m_npcActors release]; m_npcActors = nil;
    
    [m_worldFrameCache release]; m_worldFrameCache = nil;
    [m_groupTable release]; m_groupTable = nil;
    [m_playerActor release]; m_playerActor = nil;
    [m_elbowRoom release]; m_elbowRoom = nil;
    [m_worldStateBlockUpdaters release]; m_worldStateBlockUpdaters = nil;
    [m_updateGraphWorkers release]; m_updateGraphWorkers = nil;
    [m_frameStateBlockUpdaters release]; m_frameStateBlockUpdaters = nil;
    [m_worldSOs release]; m_worldSOs = nil;
    
    [BUStats releaseStaticInstance];
    [super dealloc];
}


-(void)initPlayerAt:(EmuPoint)p fromPreset:(EBlockPreset)preset
{
    NSAssert( m_playerActor == nil, @"World initPlayerAt: player already exists!" );
    
    switch( preset )
    {
        case EBlockPreset_PlayerStart:
            m_playerActor = [[PR2PlayerActor alloc] initAtStartingPoint:p];
            break;
        case EBlockPreset_tiny_playerStart:
            m_playerActor = [[Rob16PlayerActor alloc] initAtStartingPoint:p];
            break;
        default:
            NSAssert( NO, @"Unexpected player start type." );
            return;
    }
    m_playerActor.world = self;
}


-(PlayerActor *)getPlayerActor
{
    return m_playerActor;
}


-(NSMutableArray *)getNpcActors
{
    return m_npcActors;
}


-(void)setupElbowRoom
{
    // first, calculate world bounding box.
    Emu xMin = WORLD_MAX_X;
    Emu yMin = WORLD_MAX_Y;
    Emu xMax = WORLD_MIN_X;
    Emu yMax = WORLD_MIN_Y;
    for( int i = 0; i < [m_npcActors count]; ++i )
    {
        Actor *thisActor = (Actor *)[m_npcActors objectAtIndex:i];
        for( int j = 0; j < [thisActor.actorBlockList count]; ++j )
        {
            Block *thisBlock = (Block *)[thisActor.actorBlockList objectAtIndex:j];
            if( thisBlock == nil ) continue;
            xMin = MIN( xMin, thisBlock.x );
            yMin = MIN( yMin, thisBlock.y );
            xMax = MAX( xMax, thisBlock.x + thisBlock.w );
            yMax = MAX( yMax, thisBlock.y + thisBlock.h );
        }
    }
    for( int i = 0; i < [m_worldSOs count]; ++i )
    {
        ASolidObject *thisSO = (ASolidObject *)[m_worldSOs objectAtIndex:i];
        if( [thisSO isGroup] )
        {
            BlockGroup *thisGroup = (BlockGroup *)thisSO;
            for( int i = 0; i < [thisGroup.blocks count]; ++i )
            {
                Block *thisBlock = (Block *)[thisGroup.blocks objectAtIndex:i];
                xMin = MIN( xMin, thisBlock.x );
                yMin = MIN( yMin, thisBlock.y );
                xMax = MAX( xMax, thisBlock.x + thisBlock.w );
                yMax = MAX( yMax, thisBlock.y + thisBlock.h );
            }
        }
        else
        {
            Block *thisBlock = (Block *)thisSO;
            xMin = MIN( xMin, thisBlock.x );
            yMin = MIN( yMin, thisBlock.y );
            xMax = MAX( xMax, thisBlock.x + thisBlock.w );
            yMax = MAX( yMax, thisBlock.y + thisBlock.h );
        }
    }
    Emu padding = 20 * ONE_BLOCK_SIZE_Emu;
    xMin -= padding;
    yMin -= padding;
    xMax += padding;
    yMax += padding;
    [m_elbowRoom resetWithWorldMin:EmuPointMake(xMin, yMin) worldMax:EmuPointMake(xMax, yMax)];

    // now that ER is set with right size, add everything.
    for( int i = 0; i < [m_npcActors count]; ++i )
    {
        Actor *thisActor = (Actor *)[m_npcActors objectAtIndex:i];
        for( int j = 0; j < [thisActor.actorBlockList count]; ++j )
        {
            Block *thisBlock = (Block *)[thisActor.actorBlockList objectAtIndex:j];
            if( thisBlock != nil )
            {
                [m_elbowRoom addBlock:thisBlock];
            }
        }
    }
    for( int i = 0; i < [m_worldSOs count]; ++i )
    {
        ASolidObject *thisSO = (ASolidObject *)[m_worldSOs objectAtIndex:i];
        if( [thisSO isGroup] )
        {
            BlockGroup *thisGroup = (BlockGroup *)thisSO;
            for( int i = 0; i < [thisGroup.blocks count]; ++i )
            {
                Block *thisBlock = (Block *)[thisGroup.blocks objectAtIndex:i];
                [m_elbowRoom addBlock:thisBlock];
            }
        }
        else
        {
            Block *thisBlock = (Block *)thisSO;
            [m_elbowRoom addBlock:thisBlock];
        }
    }
}


-(void)onDpadEvent:(DpadEvent *)event
{
    [m_playerActor onDpadEvent:event];
}


-(void)showTestWorld:(NSString *)preferredStartingWorld loadFromDisk:(BOOL)loadFromDisk
{
    m_loadTestWorldFromDisk = loadFromDisk;
    [self reset];
    [WorldTest loadTestWorldTo:self loadFromDisk:m_loadTestWorldFromDisk startingWith:preferredStartingWorld];
    [self onWorldStarting];
}


-(void)resetTestWorld
{
    [self reset];
    [WorldTest loadTestWorldTo:self loadFromDisk:m_loadTestWorldFromDisk nextWorld:NO];
    [self onWorldStarting];
}


-(void)advanceTestWorld
{
    [self reset];
    [WorldTest loadTestWorldTo:self loadFromDisk:m_loadTestWorldFromDisk nextWorld:YES];
    [self onWorldStarting];
}


-(void)initActorUpdaters
{
    id updater;
    
    // player-related updaters
    
    updater = [[PlayerInputUpdater alloc] initWithWorld:self];
    [m_playerActorUpdaters addObject:updater];
    [updater release];
    
    updater = [[PlayerHeadBumpUpdater alloc] initWithWorld:self];
    [m_playerActorUpdaters addObject:updater];
    [updater release];
    
    // general actor updaters
    
    updater = [[ActorLifeStateUpdater alloc] initWithWorld:self];
    [m_actorUpdaters addObject:updater];
    [updater release];
    
    updater = [[ActorAIUpdater alloc] initWithWorld:self];
    [m_actorUpdaters addObject:updater];
    [updater release];
    
    updater = [[ActorWalkingUpdater alloc] initWithWorld:self];
    [m_actorUpdaters addObject:updater];
    [updater release];

    updater = [[ActorJumpingUpdater alloc] initWithWorld:self];
    [m_actorUpdaters addObject:updater];
    [updater release];
}


-(void)initBlockUpdaters
{
    // add all block updaters. order matters.
    
    id updater;
    
    // frame cache updaters

    updater = [[FrameCacheClearerUpdater alloc] initWithElbowRoom:m_elbowRoom frameCache:m_worldFrameCache];
    [m_frameStateBlockUpdaters addObject:updater];
    [updater release];
    

    // world state updaters

    updater = [[OpposingMotiveUpdater alloc] initWithElbowRoom:m_elbowRoom frameCache:m_worldFrameCache];
    [m_worldStateBlockUpdaters addObject:updater];
    [updater release];
    
    updater = [[ApplyMotiveUpdater alloc] initWithElbowRoom:m_elbowRoom frameCache:m_worldFrameCache];
    [m_frameStateBlockUpdaters addObject:updater];
    [updater release];
    
    updater = [[ApplyGravityMotiveUpdater alloc] initWithElbowRoom:m_elbowRoom frameCache:m_worldFrameCache];
    [m_frameStateBlockUpdaters addObject:updater];
    [updater release];
    
    // at this point, velocity is set for all blocks. we use it to initiate move propagation.
    updater = [[PropagateMovementUpdater alloc] initWithElbowRoom:m_elbowRoom frameCache:m_worldFrameCache];
    [m_frameStateBlockUpdaters addObject:updater];
    [updater release];
    
    updater = [[GravFrictionUpdater alloc] initWithElbowRoom:m_elbowRoom frameCache:m_worldFrameCache];
    [m_worldStateBlockUpdaters addObject:updater];
    [updater release];
    
    
    // game state updaters
    
    updater = [[BottomOfTheWorldUpdater alloc] initWithWorld:self];
    [m_worldStateBlockUpdaters addObject:updater];
    [updater release];

    updater = [[SpriteStateUpdater alloc] init];
    [m_worldStateBlockUpdaters addObject:updater];
    [updater release];
}


-(int)worldSOCount
{
    return [m_worldSOs count];
}


-(Block *)getWorldSO:(int)i
{
    return (Block *)[m_worldSOs objectAtIndex:i];
}


-(void)sweepDeadObjects
{
    if( [m_deadActorsThisFrame count] != 0 )
    {
        NSLog( @"removing %d actor(s) this frame", [m_deadActorsThisFrame count] );
        for( int i = 0; i < [m_deadActorsThisFrame count]; ++i )
        {
            Actor *thisActor = (Actor *)[m_deadActorsThisFrame objectAtIndex:i];
            [m_npcActors removeObject:thisActor];
        }
        
        [m_deadActorsThisFrame removeAllObjects];
    }

    if( [m_deadSOsThisFrame count] != 0 )
    {
        NSLog( @"removing %d SO(s) this frame", [m_deadSOsThisFrame count] );
        for( int i = 0; i < [m_deadSOsThisFrame count]; ++i )
        {
            ASolidObject *thisSO = (ASolidObject *)[m_deadSOsThisFrame objectAtIndex:i];
            [self removeWorldSO:thisSO];
        }
        
        [m_deadSOsThisFrame removeAllObjects];
    }
}


-(void)runBlockUpdaterList:(NSArray *)listOfUpdaters forTimeDelta:(float)timeDelta
{
    // do all blocks for each updater (instead of all updaters for each block),
    //  since the order of updaters across the world is important.    
    BOOL updatePlayer = (m_playerActor != nil);

    for( int i = 0; i < [listOfUpdaters count]; ++i )
    {
        BlockUpdater *thisUpdater = (BlockUpdater *)[listOfUpdaters objectAtIndex:i];
        
        // actors own their actorblocks, so we need to update each of those in addition to the worldSO list.
        for( int j = 0; j < [m_npcActors count]; ++j )
        {
            Actor *thisActor = (Actor *)[m_npcActors objectAtIndex:j];
            for( int k = 0; k < [thisActor.actorBlockList count]; ++k )
            {
                ASolidObject *thisBlock = (ASolidObject *)[thisActor.actorBlockList objectAtIndex:k];
                if( thisBlock != nil )
                {
                    [thisUpdater updateSolidObject:thisBlock withTimeDelta:timeDelta];
                }
            }
        }
        
        // update all worldSOs (which aren't owned by actors or groups)
        for( int j = 0; j < [m_worldSOs count]; ++j )
        {
            ASolidObject *thisSO = (ASolidObject *)[m_worldSOs objectAtIndex:j];
            [thisUpdater updateSolidObject:thisSO withTimeDelta:timeDelta];
        }

        // the player's block is not in the worldSO list so update it now.
        if( updatePlayer )
        {
            ASolidObject *playerSO = [m_playerActor.actorBlockList objectAtIndex:0];
            if( playerSO != nil )
            {
                [thisUpdater updateSolidObject:playerSO withTimeDelta:timeDelta];
            }
        }
    }
}


-(void)updateWithTimeDelta:(float)timeDelta
{
#ifdef LOG_FRAMES    
    NSLog( @"++ frame ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" );
#endif

    if( m_burnFrames > 0 )
    {
        --m_burnFrames;
        return;
    }
    
    [[BUStats instance] updateWithTimeDelta:timeDelta];

    long startTime = getUpTimeMs();
    BOOL updatePlayer = (m_playerActor != nil);
    
    // updaters specifically for the player actor
    if( updatePlayer )
    {
        for( int i = 0; i < [m_playerActorUpdaters count]; ++i )
        {
            ActorUpdater *thisUpdater = (ActorUpdater *)[m_playerActorUpdaters objectAtIndex:i];
            [thisUpdater updateActor:m_playerActor withTimeDelta:timeDelta];
        }
    }

    // updaters for all types of actor
    for( int i = 0; i < [m_actorUpdaters count]; ++i )
    {
        ActorUpdater *thisUpdater = (ActorUpdater *)[m_actorUpdaters objectAtIndex:i];
        
        // the player actor is not in the npcActor list
        if( updatePlayer )
        {
            [thisUpdater updateActor:m_playerActor withTimeDelta:timeDelta];
        }
        
        for( int j = 0; j < [m_npcActors count]; ++j )
        {
            Actor *thisActor = (Actor *)[m_npcActors objectAtIndex:j];
            [thisUpdater updateActor:thisActor withTimeDelta:timeDelta];
        }
    }
    
    // updaters related to frame physics state
    [self runBlockUpdaterList:m_frameStateBlockUpdaters forTimeDelta:timeDelta];
  
    // post-processing updaters
    [self runBlockUpdaterList:m_worldStateBlockUpdaters forTimeDelta:timeDelta];
    
    // after all updaters are done, sweep for dead blocks and actors
    [self sweepDeadObjects];

    // display timing information for the world update every so often.
    UInt32 thisDur = (UInt32)(getUpTimeMs() - startTime);
    m_totalDur += thisDur;
    ++m_totalUpdates;
    m_timeUntilNextSpeedReport -= timeDelta;
    if( m_timeUntilNextSpeedReport <= 0.f )
    {
        m_timeUntilNextSpeedReport = TIME_BETWEEN_WORLDUPDATE_SPEED_REPORTS;
        float averageUpdateDur = (float)m_totalDur / (float)m_totalUpdates;
        NSString *speedReportString = [NSString stringWithFormat:@"updating world average duration is %f ms.", averageUpdateDur ];
        DebugOut( speedReportString );
    }
}


-(void)addWorldBlock:(Block *)block
{
    block.state.vIntrinsic = block.props.initialVelocity;
    [m_worldSOs addObject:block];
}


-(void)removeWorldSO:(ASolidObject *)solidObject
{
    if( [solidObject isGroup] )
    {
        BlockGroup *thisGroup = (BlockGroup *)solidObject;
        NSLog( @"removing group SO from world, contains %d elements.", [thisGroup.blocks count] );
        for( int i = 0; i < [thisGroup.blocks count]; ++i )
        {
            Block *thisBlock = (Block *)[thisGroup.blocks objectAtIndex:i];
            [m_elbowRoom removeBlock:thisBlock];
        }
        [m_worldSOs removeObject:thisGroup];
    }
    else
    {
        Block *thisBlock = (Block *)solidObject;
        [m_elbowRoom removeBlock:thisBlock];
        [m_worldSOs removeObject:thisBlock];
    }
}


-(BlockGroup *)ensureGroupForId:(GroupId)groupId
{
    NSNumber *groupKey = [NSNumber numberWithUnsignedInt:(unsigned int)groupId];
    BlockGroup *group = (BlockGroup *)[m_groupTable objectForKey:groupKey];
    if( nil == group )
    {
        group = [[BlockGroup alloc] initWithGroupId:groupId];
        [m_groupTable setObject:group forKey:groupKey];
        [m_worldSOs addObject:group];
    }
    return group;
}


// TODO: refactor this, shouldn't have to removeWorldSO, that's dumb. Need to make sure we are consistent
//       with adding/removing ER refs.
-(void)addBlock:(Block *)block toGroup:(BlockGroup *)group
{
    // the intent is that the ER ref to this block should move along with the block
    //  when transferring ownership in the World. So when we removeBlock, we also
    //  remove the ER ref. Then we add the ER ref back when we add to the group.
    //  this should be the cleanest design since we do the same thing regardless of
    //  whether we removed it from worldSOs before adding to group.
    
    if( [m_worldSOs containsObject:block] )
    {
        NSAssert( NO, @"this case is no longer doing the right thing because we're losing the ER ref" );
        //[self removeWorldSO:block];  // removes ER ref too.
    }
    
    [group addBlock:block];
}


-(void)addNPCActor:(Actor *)actor
{
    [m_npcActors addObject:actor];
    actor.world = self;
}


-(BlockEdgeDirMask)getShortCircuitHintForBlock:(Block *)block
{
    BlockEdgeDirMask result = BlockEdgeDirMask_None;

    Emu er;
    BOOL hitOwnGroup;
    
    hitOwnGroup = NO;
    er = [m_elbowRoom getElbowRoomForSO:block inDirection:ERDirUp];
    if( er == 0 )
    {
        while( YES )
        {
            Block *thisBlock = [m_elbowRoom popCollider];
            if( thisBlock == nil ) break;
            if( thisBlock.groupId == block.groupId )
            {
                hitOwnGroup = YES;
                break;
            }
        }
    }
    if( hitOwnGroup )
    {
        result |= BlockEdgeDirMask_Up;
    }

    hitOwnGroup = NO;
    er = [m_elbowRoom getElbowRoomForSO:block inDirection:ERDirLeft];
    if( er == 0 )
    {
        while( YES )
        {
            Block *thisBlock = [m_elbowRoom popCollider];
            if( thisBlock == nil ) break;
            if( thisBlock.groupId == block.groupId )
            {
                hitOwnGroup = YES;
                break;
            }
        }
    }
    if( hitOwnGroup )
    {
        result |= BlockEdgeDirMask_Left;
    }

    hitOwnGroup = NO;
    er = [m_elbowRoom getElbowRoomForSO:block inDirection:ERDirRight];
    if( er == 0 )
    {
        while( YES )
        {
            Block *thisBlock = [m_elbowRoom popCollider];
            if( thisBlock == nil ) break;
            if( thisBlock.groupId == block.groupId )
            {
                hitOwnGroup = YES;
                break;
            }
        }
    }
    if( hitOwnGroup )
    {
        result |= BlockEdgeDirMask_Right;
    }

    hitOwnGroup = NO;
    er = [m_elbowRoom getElbowRoomForSO:block inDirection:ERDirDown];
    if( er == 0 )
    {
        while( YES )
        {
            Block *thisBlock = [m_elbowRoom popCollider];
            if( thisBlock == nil ) break;
            if( thisBlock.groupId == block.groupId )
            {
                hitOwnGroup = YES;
                break;
            }
        }
    }
    if( hitOwnGroup )
    {
        result |= BlockEdgeDirMask_Down;
    }
    
    return result;    
}


-(void)updateGroupShortCircuitHints
{
    // loop through each block in each group and update the shortCircuitER hint, which allows ER to skip work
    //   for blocks that would just hit a group sibling.
    NSArray *groupList = [m_groupTable allValues];
    for( int iGroup = 0; iGroup < [groupList count]; ++iGroup )
    {
        BlockGroup *thisGroup = (BlockGroup *)[groupList objectAtIndex:iGroup];
        for( int iBlock = 0; iBlock < [thisGroup.blocks count]; ++iBlock )
        {
            Block *thisBlock = (Block *)[thisGroup.blocks objectAtIndex:iBlock];
            thisBlock.shortCircuitER = [self getShortCircuitHintForBlock:thisBlock];
        }
    }
}


-(void)findWorldBottom
{
    Emu lowest = (Emu)INT_MAX;
    
    // check blocks in group
    NSArray *groupList = [m_groupTable allValues];
    for( int iGroup = 0; iGroup < [groupList count]; ++iGroup )
    {
        BlockGroup *thisGroup = (BlockGroup *)[groupList objectAtIndex:iGroup];
        for( int iBlock = 0; iBlock < [thisGroup.blocks count]; ++iBlock )
        {
            Block *thisBlock = (Block *)[thisGroup.blocks objectAtIndex:iBlock];
            if( thisBlock.y < lowest )
            {
                lowest = thisBlock.y;
            }
        }
    }

    // check blocks in worldSO list
    for( int j = 0; j < [m_worldSOs count]; ++j )
    {
        ASolidObject *thisSO = (ASolidObject *)[m_worldSOs objectAtIndex:j];
        if( ![thisSO isGroup] )
        {
            Block *thisBlock = (Block *)thisSO;
            if( thisBlock.y < lowest )
            {
                lowest = thisBlock.y;
            }
        }
    }
    
    // also check actor blocks (since some "actors" are similar to static blocks, e.g. crumbles.
    for( int j = 0; j < [m_npcActors count]; ++j )
    {
        Actor *thisActor = (Actor *)[m_npcActors objectAtIndex:j];
        for( int k = 0; k < [thisActor.actorBlockList count]; ++k )
        {
            ASolidObject *thisSO = [thisActor.actorBlockList objectAtIndex:k];
            NSAssert( ![thisSO isGroup], @"since when do we have group actors?" );
            Block *thisBlock = (Block *)thisSO;
            if( thisBlock.y < lowest )
            {
                lowest = thisBlock.y;
            }
        }
    }
    
    self.yBottom = lowest;
    NSLog( @"world bottom is at %d", self.yBottom );
}


-(void)onWorldStarting
{
    // the world has been loaded and is going into play state, do any start-time processing now.
    
    // this is where we do any dynamic generation of world stuff.
    //  I'd picture an event processing loop starting here, various dynamic group stuff getting arranged, etc.
    
    [self updateGroupShortCircuitHints];
    
    [self findWorldBottom];
}


-(void)reset
{
    [[BUStats instance] reset];
    
    self.levelName = nil;
    self.levelDescription = nil;
    
    [m_worldFrameCache hardReset];
    [m_worldSOs removeAllObjects];
    [m_playerActor release]; m_playerActor = nil;
    [m_groupTable removeAllObjects];
    [m_npcActors removeAllObjects];

    // reset timing statistics too.
    m_totalDur = 0;
    m_totalUpdates = 0;
    m_timeUntilNextSpeedReport = TIME_BETWEEN_WORLDUPDATE_SPEED_REPORTS;
    
    m_burnFrames = BURN_FRAMES_ON_WORLD_RESET;
}


// handles global reset commands
-(void)onGlobalCommand_resetWorld
{
    [self resetTestWorld];
}


// handles global reset commands
-(void)onGlobalCommand_advanceWorld
{
    [self advanceTestWorld];
}


-(void)onPlayerDying
{
    // TODO: want to remove the playerBlock's edge info so we don't continue to track
    //  player even when they blow up, but this causes crashes later in the frame. does
    //  this need to be handled asynchronously?
    // don't allow playerBlock to clip or move during death.
    //[self.elbowRoom removeBlock:m_playerActor.actorBlock];
}


-(void)onPlayerDied
{
    [m_playerActor release]; m_playerActor = nil;
    [self resetTestWorld];
}


-(void)onPlayerWon
{
    [self advanceTestWorld];
}


-(void)onActorDied:(Actor *)actor
{
    NSLog( @"World: actor died. RIP." );
    [m_deadActorsThisFrame addObject:actor];
}


-(void)onSODied:(ASolidObject *)solidObject
{
    [m_deadSOsThisFrame addObject:solidObject];
}


@end

