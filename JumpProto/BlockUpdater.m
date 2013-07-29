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
        
        // walljumping players have different maxV
        if( blockProps.isPlayerBlock )
        {
            ActorBlock *playerBlock = (ActorBlock *)solidObject;
            PlayerActor *player = (PlayerActor *)playerBlock.owningActor;
            if( player.isWallJumping )
            {
                maxVDueToGravity = TERMINAL_VELOCITY_WALLJUMP;
            }
            
        }

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
    const Emu cScreenShiftFactor = FlToEmu( 3072.f );  // TODO: cheezy, not resolution safe
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


