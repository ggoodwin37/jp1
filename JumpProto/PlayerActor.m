//
//  PlayerActor.m
//  JumpProto
//
//  Created by Gideon iOS on 7/28/13.
//
//

#import "PlayerActor.h"
#import "World.h"
#import "constants.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// PlayerActor

@interface PlayerActor (private)
-(void)setStillAnimState;
-(void)setRunningAnimState;
@end


@implementation PlayerActor

@synthesize isDirLeftPressed = m_isDirLeftPressed, isDirRightPressed = m_isDirRightPressed;
@synthesize isGibbed = m_isGibbed;

-(id)initAtStartingPoint:(EmuPoint)startingPoint
{
    if( self = [super initAtStartingPoint:startingPoint] )
    {
        m_eventQueue = [[NSMutableArray arrayWithCapacity:5] retain];
        m_actorBlock = nil;
        
        m_walkAccel = PLAYERINPUT_LR_ACCEL;
        m_walkMaxV = PLAYERINPUT_LR_MAX_V;
        
        m_jumpMaxV = PLAYERINPUT_JUMP_MAX_V;
        m_numJumpsAllowed = NUM_JUMPS_ALLOWED;
        m_jumpDuration = MAX_JUMP_DURATION;
        
        m_lifeState = ActorLifeState_NotBornYet;
        m_lifeStateTimer = PLAYER_NOTBORNYET_TIME;
        
        m_isGibbed = NO;
    }
    return self;
}


-(void)dealloc
{
    [m_eventQueue release]; m_eventQueue = nil;
    [super dealloc];
}


-(void)onDpadEvent:(DpadEvent *)event
{
    [m_eventQueue addObject:event];
}


-(void)setRunningAnimState
{
    NSAssert( NO, @"Don't call base PlayerActor version of this method." );
}


-(void)setStillAnimState
{
    NSAssert( NO, @"Don't call base PlayerActor version of this method." );
}


-(void)updateCurrentAnimState
{
    if( m_actorBlock == nil )
    {
        return;
    }
    
    if( m_isDirLeftPressed )
    {
        [self setRunningAnimState];
        m_actorBlock.defaultSpriteState.isFlipped = YES;
    }
    else if( m_isDirRightPressed )
    {
        [self setRunningAnimState];
    }
    else
    {
        [self setStillAnimState];
    }
}


-(void)processNextInputEvent
{
    if( [m_eventQueue count] == 0 )
        return;
    
    DpadEvent *event = (DpadEvent *)[m_eventQueue objectAtIndex:0];
    [m_eventQueue removeObjectAtIndex:0];
    if( event.touchZone == LeftTouchZone )
    {
        // left touch zone, look for movingLeft/Right events.
        switch( event.button )
        {
            case DpadLeftButton:
                m_isDirLeftPressed = (event.type == DpadPressed);
                if( m_isDirLeftPressed )
                {
                    m_isDirRightPressed = NO;
                    [self setRunningAnimState];
                }
                else
                {
                    [self setStillAnimState];
                }
                m_actorBlock.defaultSpriteState.isFlipped = YES;
                break;
            case DpadRightButton:
                m_isDirRightPressed = (event.type == DpadPressed);
                if( m_isDirRightPressed )
                {
                    m_isDirLeftPressed = NO;
                    [self setRunningAnimState];
                }
                else
                {
                    [self setStillAnimState];
                }
                m_actorBlock.defaultSpriteState.isFlipped = NO;
                break;
            default:
                break;
        }
    }
    else
    {
        // right touch zone, look for jump events
        switch( event.button )
        {
            case DpadLeftButton:
                // not currently used
                break;
            case DpadRightButton:
                [self onJumpEvent:(event.type == DpadPressed)];
                break;
            default:
                break;
        }
    }
}


// override
-(void)onStartBeingBorn
{
    NSLog( @"playerActor: onStartBeingBorn" );
    m_lifeState = ActorLifeState_BeingBorn;
    m_lifeStateTimer = PLAYER_BEINGBORN_TIME;
    
    // TODO: some visual effects
}


// override
-(void)onBorn
{
    NSLog( @"playerActor: onBorn" );
    m_lifeState = ActorLifeState_Alive;
    
    m_actorBlock = [[ActorBlock alloc] initAtPoint:m_startingPoint];
    m_actorBlock.props.canMoveFreely = YES;
    m_actorBlock.props.affectedByGravity = YES;
    m_actorBlock.props.affectedByFriction = YES;  // TODO: we used to handle this separately, still needed?
    m_actorBlock.props.isPlayerBlock = YES;
    
    NSLog( @"created player's actorBlock, token=%u", (unsigned int)[m_actorBlock getProps].token );
    
    m_actorBlock.owningActor = self;
    m_actorBlock.state.d = EmuSizeMake( PLAYER_WIDTH, PLAYER_HEIGHT );
    
    // must come after dimensions have been set.
    [m_world.elbowRoom addBlock:m_actorBlock];
    
    [self updateCurrentAnimState];
}


-(NSString *)getRandomGibName
{
    NSAssert( NO, @"Don't call base PlayerActor version of this method." );
    return nil;
}


-(void)spawnGibsOnDeath
{
    m_isGibbed = YES;
    
    const EmuSize gibSize = EmuSizeMake( ONE_BLOCK_SIZE_Emu * 2, ONE_BLOCK_SIZE_Emu * 2 );
    for( int i = 0; i < PLAYER_DEAD_GIB_COUNT; ++i )
    {
        EmuRect thisRect = EmuRectMake( m_actorBlock.x, m_actorBlock.y, gibSize.width, gibSize.height );
        
        NSString *thisSpriteDefName = [self getRandomGibName];
        SpriteState *thisSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:thisSpriteDefName] autorelease];
        
        Emu vMag = PLAYER_DEAD_GIB_V;
        float thisTheta = frand() * 2 * M_PI;
        EmuPoint thisV = EmuPointMake( vMag * cosf( thisTheta ), vMag * sinf( thisTheta ) );
        
        SpriteStateMap *spriteStateMap = [[[SpriteStateMap alloc] initWithSize:CGSizeMake( 1.f, 1.f)] autorelease];
        [spriteStateMap setSpriteStateAtX:0 y:0 to:thisSpriteState];
        SpriteBlock *thisGibBlock = [[SpriteBlock alloc] initWithRect:thisRect spriteStateMap:spriteStateMap];
        thisGibBlock.props.canMoveFreely = YES;
        thisGibBlock.props.affectedByGravity = YES;
        thisGibBlock.props.initialVelocity = thisV;
        
        [m_world addWorldBlock:thisGibBlock];
    }
    [m_world.elbowRoom removeBlock:m_actorBlock];  // don't let the (dead) player's edges mess up gib collision.
}


// override
-(void)onStartDying
{
    if( m_lifeState != ActorLifeState_Dying )
    {
        NSLog( @"playerActor: onStartDying" );
        m_lifeState = ActorLifeState_Dying;
        m_lifeStateTimer = PLAYER_DYING_TIME;
        
        [self spawnGibsOnDeath];
        
        if( m_world != nil )
        {
            [m_world onPlayerDying];
        }
    }
}


// override
-(void)onDead
{
    NSLog( @"playerActor: onDead" );
    m_lifeState = ActorLifeState_Dead;
    
    if( m_world != nil )
    {
        [m_world onPlayerDied];
    }
}


// override
-(void)onWinning
{
    NSLog( @"playerActor: onWinning" );
    m_lifeState = ActorLifeState_Winning;
    m_lifeStateTimer = PLAYER_WINNING_TIME;
}


// override
-(void)onWon
{
    NSLog( @"playerActor: onWon" );
    m_lifeState = ActorLifeState_Won;
    
    m_actorBlock = nil;
    if( m_world != nil )
    {
        [m_world onPlayerWon];
    }
    
}


// override
-(void)onTouchedHurty
{
    [super onTouchedHurty];
    
    if( m_lifeState == ActorLifeState_Alive )
    {
        [self onStartDying];
    }
}


// override
-(void)onTouchedGoal
{
    [super onTouchedGoal];
    
    if( m_lifeState == ActorLifeState_Alive )
    {
        [self onWinning];
    }
}


// override
-(void)onFellOffWorld
{
    [super onFellOffWorld];
    if( m_lifeState == ActorLifeState_Alive )
    {
        NSLog( @"playerActor fell off world." );
        [self onStartDying];
    }
}


// override
-(void)updateLifeStateWithTimeDelta:(float)delta
{
    switch( m_lifeState )
    {
        case ActorLifeState_Winning:
            m_lifeStateTimer -= delta;
            if( m_lifeStateTimer <= 0.f )
            {
                [self onWon];
            }
            break;
            
        case ActorLifeState_Won:
            // TODO
            break;
            
        default:
            [super updateLifeStateWithTimeDelta:delta];
            break;
    }
}


-(void)handleCollisionWithSO:(ASolidObject *)solidObject edgeMask:(BlockEdgeDirMask)mask
{
    // check various properties to see if colliding into this SO should trigger any actor events.
    
    // hurt?
    if( ([solidObject getProps].hurtyMask & mask) > 0 )
    {
        [self onTouchedHurty];
    }
    
    // won?
    if( [solidObject getProps].isGoalBlock )
    {
        [self onTouchedGoal];
    }
}


// override
-(void)collidedInto:(NSObject<ISolidObject> *)node inDir:(ERDirection)dir
{
    [super collidedInto:node inDir:dir];
    
    if( m_lifeState != ActorLifeState_Alive )
    {
        return;
    }
    
    BlockEdgeDirMask mask = [Block getOpposingEdgeMaskForDir:dir];
    [self handleCollisionWithSO:node edgeMask:mask];
}


// used by worldView to draw something when player is in a state that doesn't have a true sprite associated.
//  (e.g. before they are born, so player's block hasn't been created yet)
-(NSString *)getStaticFrameName
{
    NSAssert( NO, @"Don't call base PlayerActor version of this method." );
    return nil;
};

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// PR2PlayerActor

@implementation PR2PlayerActor

// override
-(void)setRunningAnimState
{
    static const float runningAnimDur = 0.25f;
    if( m_actorBlock != nil )
    {
        m_actorBlock.defaultSpriteState = [[[AnimSpriteState alloc] initWithAnimName:@"pr2_walking" animDur:runningAnimDur] autorelease];
    }
}


// override
-(void)setStillAnimState
{
    if( m_actorBlock != nil )
    {
        m_actorBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"pr2_still"] autorelease];
    }
}


// override
-(NSString *)getRandomGibName
{
    int randomSprite = (int)floorf( frand() * 4.f );
    switch( randomSprite )
    {
        case 0: return @"gib_pl0_a";
        case 1: return @"gib_pl0_b";
        case 2: return @"gib_pl0_c";
        case 3: return @"gib_pl0_d";
        default: NSAssert( NO, @"basic fail" ); return nil;
    }
}


// override
-(NSString *)getStaticFrameName
{
    return @"pr2_still";
};

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// Rob16PlayerActor

@implementation Rob16PlayerActor

// override
-(void)setRunningAnimState
{
    static const float runningAnimDur = 0.25f;
    if( m_actorBlock != nil )
    {
        m_actorBlock.defaultSpriteState = [[[AnimSpriteState alloc] initWithAnimName:@"rob16-walking" animDur:runningAnimDur] autorelease];
    }
}


// override
-(void)setStillAnimState
{
    if( m_actorBlock != nil )
    {
        m_actorBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"rob16-idle"] autorelease];
    }
}


// override
-(NSString *)getRandomGibName
{
    int randomSprite = (int)floorf( frand() * 4.f );
    switch( randomSprite )
    {
        case 0: return @"rob16-gib-0";
        case 1: return @"rob16-gib-1";
        case 2: return @"rob16-gib-2";
        case 3: return @"rob16-gib-3";
        default: NSAssert( NO, @"basic fail" ); return nil;
    }
}


// override
-(NSString *)getStaticFrameName
{
    return @"rob16-idle";
};

@end
