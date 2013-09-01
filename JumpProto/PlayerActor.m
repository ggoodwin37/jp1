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

@implementation PlayerActor

@synthesize isDirLeftPressed = m_isDirLeftPressed, isDirRightPressed = m_isDirRightPressed;
@synthesize isGibbed = m_isGibbed;
@synthesize isWallJumping = m_isWallJumping;

-(id)initAtStartingPoint:(EmuPoint)startingPoint
{
    if( self = [super initAtStartingPoint:startingPoint] )
    {
        m_eventQueue = [[NSMutableArray arrayWithCapacity:5] retain];
        
        m_walkAccel = PLAYERINPUT_LR_ACCEL;
        m_walkMaxV = PLAYERINPUT_LR_MAX_V;
        
        m_jumpMaxV = PLAYERINPUT_JUMP_MAX_V;
        m_numJumpsAllowed = NUM_JUMPS_ALLOWED;
        m_jumpDuration = MAX_JUMP_DURATION;
        
        m_lifeState = ActorLifeState_NotBornYet;
        m_lifeStateTimer = PLAYER_NOTBORNYET_TIME;
        
        m_isGibbed = NO;
        m_isWallJumping = NO;
        m_postWallJumpFlip = NO;
        
        m_stillSpriteState = nil;
        m_runningSpriteState = nil;
        m_jumpUpSpriteState = nil;
        m_jumpDownSpriteState = nil;
        m_wallJumpSpriteState = nil;
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


-(void)updateCurrentAnimStateForPlayer
{
    ActorBlock *actorBlock = [self getDefaultActorBlock];
    if( actorBlock == nil )
    {
        return;
    }

    BOOL isFlipped = actorBlock.defaultSpriteState.isFlipped;
    SpriteState *targetState = nil;
    
    // I almost wanted to reuse this code but it's only used in a few places,
    //  including base class with different vars, and this is perf sensitive
    //  so excessive method calls are bad.
    BOOL lSignal;
    BOOL rSignal;
    if( [self shouldReverseWalkDirection] )
    {
        lSignal = m_isDirRightPressed;
        rSignal = m_isDirLeftPressed;
    }
    else
    {
        lSignal = m_isDirLeftPressed;
        rSignal = m_isDirRightPressed;
    }
    
    // assumes that art is facing right, umad?
    if( lSignal )
    {
        isFlipped = YES;
    }
    else if( rSignal )
    {
        isFlipped = NO;
    }
    // else don't change.
    
    NSArray *downAbutters =  [m_world.frameCache lazyGetAbuttListForSO:actorBlock inER:m_world.elbowRoom direction:ERDirDown];
    if( [downAbutters count] == 0 ) { // mid-air
        if( lSignal ) {
            NSArray *leftAbutters =  [m_world.frameCache lazyGetAbuttListForSO:actorBlock inER:m_world.elbowRoom direction:ERDirLeft];
            for( int i = 0; i < [leftAbutters count]; ++i ) {
                ASolidObject *thisSO = (ASolidObject *)[leftAbutters objectAtIndex:i];
                if( [thisSO getProps].isWallJumpable ) {
                    targetState = m_wallJumpSpriteState;
                    break;
                }
            }
            
        } else if( rSignal ) {
            NSArray *rightAbutters =  [m_world.frameCache lazyGetAbuttListForSO:actorBlock inER:m_world.elbowRoom direction:ERDirRight];
            for( int i = 0; i < [rightAbutters count]; ++i ) {
                ASolidObject *thisSO = (ASolidObject *)[rightAbutters objectAtIndex:i];
                if( [thisSO getProps].isWallJumpable ) {
                    targetState = m_wallJumpSpriteState;
                    break;
                }
            }
        }
        if( targetState == nil ) { // didn't find one yet
            Emu vY = [actorBlock getV].y;
            if( vY > 0 ) {
                targetState = m_jumpUpSpriteState;
            } else {
                targetState = m_jumpDownSpriteState;
            }
        }
    } else {
        if( lSignal || rSignal ) {
            targetState = m_runningSpriteState;
        } else {
            targetState = m_stillSpriteState;
        }
    }
    
    actorBlock.defaultSpriteState = targetState;
    actorBlock.defaultSpriteState.isFlipped = isFlipped;
}


-(void)processNextInputEvent
{
    if( [m_eventQueue count] == 0 )
        return;
    
    DpadEvent *event = (DpadEvent *)[m_eventQueue objectAtIndex:0];
    [m_eventQueue removeObjectAtIndex:0];
    if( event.touchZone == LeftTouchZone )
    {
        // any movement event cancels the post-walljump phase
        m_postWallJumpFlip = NO;
        
        // left touch zone, look for movingLeft/Right events.
        switch( event.button )
        {
            case DpadLeftButton:
                m_isDirLeftPressed = (event.type == DpadPressed);
                if( m_isDirLeftPressed )
                {
                    m_isDirRightPressed = NO;
                }
                break;
            case DpadRightButton:
                m_isDirRightPressed = (event.type == DpadPressed);
                if( m_isDirRightPressed )
                {
                    m_isDirLeftPressed = NO;
                }
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
    
    ActorBlock *actorBlock = [[ActorBlock alloc] initAtPoint:m_startingPoint];
    [m_actorBlockList addObject:actorBlock];
    
    actorBlock.props.canMoveFreely = YES;
    actorBlock.props.affectedByGravity = YES;
    actorBlock.props.affectedByFriction = YES;  // TODO: we used to handle this separately, still needed?
    actorBlock.props.isPlayerBlock = YES;
    actorBlock.props.weight = PLAYER_WEIGHT;
    
    NSLog( @"created player's actorBlock, token=%u", (unsigned int)[actorBlock getProps].token );
    
    actorBlock.owningActor = self;
    actorBlock.state.d = EmuSizeMake( PLAYER_WIDTH, PLAYER_HEIGHT );
    
    // must come after dimensions have been set.
    [m_world.elbowRoom addBlock:actorBlock];
    
    [self updateCurrentAnimStateForPlayer];
}


-(NSString *)getRandomGibName
{
    NSAssert( NO, @"Don't call base PlayerActor version of this method." );
    return nil;
}


-(void)spawnGibsOnDeath
{
    m_isGibbed = YES;
    ActorBlock *actorBlock = [self getDefaultActorBlock];
    
    const EmuSize gibSize = EmuSizeMake( ONE_BLOCK_SIZE_Emu * 2, ONE_BLOCK_SIZE_Emu * 2 );
    for( int i = 0; i < PLAYER_DEAD_GIB_COUNT; ++i )
    {
        EmuRect thisRect = EmuRectMake( actorBlock.x, actorBlock.y, gibSize.width, gibSize.height );
        
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
        thisGibBlock.props.bounceFactor = -1.f;
        thisGibBlock.props.weight = DEFAULT_WEIGHT;
        
        [m_world addWorldBlock:thisGibBlock];
    }
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
    [m_actorBlockList removeObjectAtIndex:0];
    
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
-(void)updateControlStateWithTimeDelta:(float)delta
{
    // wall jumping can be cancelled through no event of the players' (sliding off end)
    if( m_isWallJumping )
    {
        BOOL lSignal;
        BOOL rSignal;
        if( [self shouldReverseWalkDirection] )
        {
            lSignal = m_isDirRightPressed;
            rSignal = m_isDirLeftPressed;
        }
        else
        {
            lSignal = m_isDirLeftPressed;
            rSignal = m_isDirRightPressed;
        }
        
        ActorBlock *actorBlock = [self getDefaultActorBlock];
        BOOL stillWallJumping = NO;
        if( lSignal )
        {
            NSArray *abutters = [m_world.frameCache lazyGetAbuttListForSO:actorBlock inER:m_world.elbowRoom direction:ERDirLeft];
            for( int i = 0; i < [abutters count]; ++i )
            {
                ASolidObject *thisSO = (ASolidObject *)[abutters objectAtIndex:i];
                if( [thisSO getProps].isWallJumpable )
                {
                    stillWallJumping = YES;
                    break;
                }
            }
        }
        else if( rSignal )
        {
            NSArray *abutters = [m_world.frameCache lazyGetAbuttListForSO:actorBlock inER:m_world.elbowRoom direction:ERDirRight];
            for( int i = 0; i < [abutters count]; ++i )
            {
                ASolidObject *thisSO = (ASolidObject *)[abutters objectAtIndex:i];
                if( [thisSO getProps].isWallJumpable )
                {
                    stillWallJumping = YES;
                    break;
                }
            }
        }
        m_isWallJumping = stillWallJumping;
    }

    // calculates the player's spritestate for the current frame, given all known input states.
    // since this operation requires knowledge of lots of different state (abutters, input, velocity),
    // it's better to do this in one place as opposed to trying to sync state on the fly like
    // simpler actors can.
    [self updateCurrentAnimStateForPlayer];
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


// override
-(void)onJumpEvent:(BOOL)starting
{
    if( m_isWallJumping && starting )
    {
        m_jumpsRemaining = m_numJumpsAllowed;
        m_postWallJumpFlip = !m_postWallJumpFlip;  // this could be second flip in a row.
        m_isWallJumping = NO;
    }

    [super onJumpEvent:starting];
}


// override
-(void)updateStateForStandingOnGround
{
    [super updateStateForStandingOnGround];
    m_postWallJumpFlip = NO;
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
    
    // wall jumping?
    if( [solidObject getProps].isWallJumpable && !m_isWallJumping )
    {
        BOOL lSignal;
        BOOL rSignal;
        if( [self shouldReverseWalkDirection] )
        {
            lSignal = m_isDirRightPressed;
            rSignal = m_isDirLeftPressed;
        }
        else
        {
            lSignal = m_isDirLeftPressed;
            rSignal = m_isDirRightPressed;
        }
        
        if( mask & BlockEdgeDirMask_Right )
        {
            if( lSignal )
            {
                m_isWallJumping = YES;
            }
        }
        else if( mask & BlockEdgeDirMask_Left )
        {
            if( rSignal )
            {
                m_isWallJumping = YES;
            }
        }
    }
}


// override
-(void)collidedInto:(NSObject<ISolidObject> *)other inDir:(ERDirection)dir actorBlock:(ActorBlock *)origActorBlock
{
    [super collidedInto:other inDir:dir actorBlock:origActorBlock];
    
    if( m_lifeState != ActorLifeState_Alive )
    {
        return;
    }
    
    BlockEdgeDirMask mask = [Block getOpposingEdgeMaskForDir:dir];
    [self handleCollisionWithSO:other edgeMask:mask];
}


// used by worldView to draw something when player is in a state that doesn't have a true sprite associated.
//  (e.g. before they are born, so player's block hasn't been created yet)
-(NSString *)getStaticFrameName
{
    NSAssert( NO, @"Don't call base PlayerActor version of this method." );
    return nil;
};


-(BOOL)shouldReverseWalkDirection
{
    return m_postWallJumpFlip;
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// PR2PlayerActor

@implementation PR2PlayerActor

-(id)initAtStartingPoint:(EmuPoint)p
{
    if( self = [super initAtStartingPoint:p] )
    {
        static const float runningAnimDur = 0.25f;
        m_stillSpriteState = [[StaticSpriteState alloc] initWithSpriteName:@"pr2_still"];
        m_runningSpriteState = [[AnimSpriteState alloc] initWithAnimName:@"pr2_walking" animDur:runningAnimDur];
        
        m_jumpUpSpriteState = m_runningSpriteState;
        m_jumpDownSpriteState = m_runningSpriteState;
        m_wallJumpSpriteState = m_runningSpriteState;
    }
    return self;
}


-(void)dealloc
{
    m_jumpUpSpriteState = nil;
    m_jumpDownSpriteState = nil;
    m_wallJumpSpriteState = nil;
    [m_runningSpriteState release]; m_runningSpriteState = nil;
    [m_stillSpriteState release]; m_stillSpriteState = nil;
    [super dealloc];
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

-(id)initAtStartingPoint:(EmuPoint)p
{
    if( self = [super initAtStartingPoint:p] )
    {
        static const float runningAnimDur = 0.5f;
        m_stillSpriteState = [[StaticSpriteState alloc] initWithSpriteName:@"rob16-idle"];
        m_runningSpriteState = [[AnimSpriteState alloc] initWithAnimName:@"rob16-walking" animDur:runningAnimDur];
        m_jumpUpSpriteState = [[StaticSpriteState alloc] initWithSpriteName:@"rob16-jump-u"];
        m_jumpDownSpriteState = [[StaticSpriteState alloc] initWithSpriteName:@"rob16-jump-d"];
        m_wallJumpSpriteState = [[StaticSpriteState alloc] initWithSpriteName:@"rob16-wallclimb"];
    }
    return self;
}


-(void)dealloc
{
    [m_wallJumpSpriteState release]; m_wallJumpSpriteState = nil;
    [m_jumpDownSpriteState release]; m_jumpDownSpriteState = nil;
    [m_jumpUpSpriteState release]; m_jumpUpSpriteState = nil;
    [m_runningSpriteState release]; m_runningSpriteState = nil;
    [m_stillSpriteState release]; m_stillSpriteState = nil;
    [super dealloc];
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

