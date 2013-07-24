//
//  Actor.m
//  JumpProto
//
//  Created by Gideon Goodwin on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Actor.h"
#import "World.h"
#import "constants.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// Actor

@implementation Actor

@synthesize world = m_world;
@synthesize actorBlock = m_actorBlock;
@synthesize lifeState = m_lifeState;
@synthesize startingPoint = m_startingPoint;
@synthesize lifeStateTimer = m_lifeStateTimer;

-(id)initAtStartingPoint:(EmuPoint)p
{
    if( self = [super init] )
    {
        m_world = nil;  // weak
        
        m_startingPoint = p;
        
        m_lifeState = ActorLifeState_None;
        m_lifeStateTimer = 0.f;
    }
    return self;
}


-(void)dealloc
{
    m_world = nil;
    [m_actorBlock release]; m_actorBlock = nil;
    [super dealloc];
}


-(void)onStartBeingBorn
{    
}


-(void)onBorn
{    
}


-(void)onStartDying
{    
}


-(void)onDead
{
}


-(void)onTouchedHurty
{
}


-(void)onTouchedGoal
{    
}


-(void)onFellOffWorld
{
}


-(void)updateLifeStateWithTimeDelta:(float)delta
{
    switch( m_lifeState )
    {
        case ActorLifeState_None:
        case ActorLifeState_Alive:
        case ActorLifeState_Dead:
            // no time-based events associated with these lifestates.
            break;
            
        case ActorLifeState_NotBornYet:
            m_lifeStateTimer -= delta;
            if( m_lifeStateTimer <= 0.f )
            {
                [self onStartBeingBorn];
            }
            break;

        case ActorLifeState_BeingBorn:
            m_lifeStateTimer -= delta;
            if( m_lifeStateTimer <= 0.f )
            {
                [self onBorn];
            }
            break;
            
        case ActorLifeState_Dying:
            m_lifeStateTimer -= delta;
            if( m_lifeStateTimer <= 0.f )
            {
                [self onDead];
            }
            break;

        default:
            NSLog( @"updateLifeState: unexpected state." );
            break;
    }
}


-(void)updateControlStateWithTimeDelta:(float)delta
{
}


-(void)updateForWalkingStateWithTimeDelta:(float)delta
{
}


-(void)updateForJumpingStateWithTimeDelta:(float)delta
{
}


-(EmuPoint)getMotive
{
    return EmuPointMake( 0, 0 );
}


-(EmuPoint)getMotiveAccel
{
    return EmuPointMake( 0, 0 );
}


-(void)bouncedOnXAxis:(BOOL)xAxis
{
}


-(void)collidedInto:(NSObject<ISolidObject> *)node inDir:(ERDirection)dir
{
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// CreatureActor

@implementation CreatureActor

@synthesize walkingLeft = m_walkingLeft, walkingRight = m_walkingRight;

@synthesize currentlyJumping = m_currentlyJumping;
@synthesize currentJumpTimeRemaining = m_currentJumpTimeRemaining;


-(id)initAtStartingPoint:(EmuPoint)p
{
    if( self = [super initAtStartingPoint:p] )
    {
        m_walkingLeft = NO;
        m_walkingRight = NO;
        
        m_currentlyJumping = NO;
        m_jumpMaxV = 0;
        m_numJumpsAllowed = 0;
        m_jumpDuration = 0;
        m_jumpsRemaining = 0;
        m_currentJumpTimeRemaining = 0;
        m_onGroundLastFrame = NO;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(void)onJumpEvent:(BOOL)starting
{
    if( starting )
    {
        if( m_wantsToJump )
        {
            return;
        }
        
        if( m_jumpsRemaining <= 0 )
        {
            return;
        }
        
        m_currentJumpTimeRemaining = m_jumpDuration;
        m_wantsToJump = YES;
        --m_jumpsRemaining;
    }
    else
    {
        m_wantsToJump = NO;
    }
}


// override
-(void)updateForJumpingStateWithTimeDelta:(float)delta
{
    [super updateForJumpingStateWithTimeDelta:delta];
    
    if( m_actorBlock == nil )
    {
        return;
    }
    
    if( m_wantsToJump )
    {
        m_currentJumpTimeRemaining -= delta;
        m_currentlyJumping = (m_currentJumpTimeRemaining > 0.f);
    }
    else
    {
        m_currentlyJumping = NO;
    }
    
    // if they are standing on solid ground, reset the jump counter
    NSArray *downEdgeList = [m_world.frameCache lazyGetAbuttListForSO:m_actorBlock inER:m_world.elbowRoom direction:ERDirDown];
    BOOL fOnGround = ( [downEdgeList count] > 0 );
    if( fOnGround )
    {
        m_jumpsRemaining = m_numJumpsAllowed;
    }
    else
    {        
        if( m_onGroundLastFrame )
        {
            m_jumpsRemaining = MAX( 0, (m_jumpsRemaining - 1) );
        }
    }
    
    m_onGroundLastFrame = fOnGround;
}


// override
-(EmuPoint)getMotive
{
    Emu xMotive = 0;
    Emu yMotive = 0;
    
    if( m_walkingLeft )
    {
        xMotive = -1 * m_walkMaxV;
    }
    else if( m_walkingRight )
    {
        xMotive =  1 * m_walkMaxV;
    }
    
    if( m_currentlyJumping )
    {
        yMotive = m_jumpMaxV;
    }
    
    return EmuPointMake( xMotive, yMotive );
}


// override
-(EmuPoint)getMotiveAccel
{
    // we want y motive to accelerate to full instantly, since a jumping character doesn't really accelerate, they just pop.
    const Emu fullAccelInOneFrame = 60 * PLAYERINPUT_JUMP_MAX_V;
    
    return EmuPointMake( m_walkAccel, fullAccelInOneFrame );
}

@end


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
    static const float runningAnimDur = 0.25f;
    if( m_actorBlock != nil )
    {
        m_actorBlock.defaultSpriteState = [[[AnimSpriteState alloc] initWithAnimName:@"pr2_walking" animDur:runningAnimDur] autorelease];
    }
}


-(void)setStillAnimState
{
    if( m_actorBlock != nil )
    {
        m_actorBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"pr2_still"] autorelease];
    }
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


-(void)spawnGibsOnDeath
{
    m_isGibbed = YES;

    const EmuSize gibSize = EmuSizeMake( 2 * ONE_BLOCK_SIZE_Emu, 2 * ONE_BLOCK_SIZE_Emu );
    for( int i = 0; i < PLAYER_DEAD_GIB_COUNT; ++i )
    {
        EmuRect thisRect = EmuRectMake( m_actorBlock.x, m_actorBlock.y, gibSize.width, gibSize.height );
        
        NSString *thisSpriteDefName = @"";
        int randomSprite = (int)floorf( frand() * 4.f );
        switch( randomSprite )
        {
            case 0: thisSpriteDefName = @"gib_pl0_a"; break;
            case 1: thisSpriteDefName = @"gib_pl0_b"; break;
            case 2: thisSpriteDefName = @"gib_pl0_c"; break;
            case 3: thisSpriteDefName = @"gib_pl0_d"; break;
            default: NSAssert( NO, @"basic fail" ); thisSpriteDefName = @""; break;
        }
        
        Emu vMag = PLAYER_DEAD_GIB_V;
        float thisTheta = frand() * 2 * M_PI;
        EmuPoint thisV = EmuPointMake( vMag * cosf( thisTheta ), vMag * sinf( thisTheta ) );
        
        SpriteStateMap *spriteStateMap = [[[SpriteStateMap alloc] initWithSize:CGSizeMake( 1.f, 1.f)] autorelease];
        SpriteBlock *thisGibBlock = [[SpriteBlock alloc] initWithRect:thisRect spriteStateMap:spriteStateMap];
        thisGibBlock.props.canMoveFreely = YES;
        thisGibBlock.props.affectedByGravity = NO;
        thisGibBlock.props.initialVelocity = thisV;

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

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// BadGuyActor

@implementation BadGuyActor

-(id)initAtStartingPoint:(EmuPoint)p
{
    if( self = [super initAtStartingPoint:p] )
    {
        m_actorBlock = nil;
        m_lifeState = ActorLifeState_NotBornYet;
        m_lifeStateTimer = BADGUY_NOTBORNYET_TIME;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
    NSAssert( m_actorBlock == nil, @"expected actorBlock to get cleared." );
}


-(void)updateCurrentAnimState
{
    // anim state set by subclasses
}


// override
-(void)onStartBeingBorn
{
    [super onStartBeingBorn];

    m_lifeState = ActorLifeState_BeingBorn;
    m_lifeStateTimer = BADGUY_BEINGBORN_TIME;
}


-(EmuSize)getActorBlockSize
{
    // can be overridden by subclasses
    return EmuSizeMake( 4 * ONE_BLOCK_SIZE_Emu, 4 * ONE_BLOCK_SIZE_Emu );
}


-(void)setPropsForActorBlock
{
    m_actorBlock.props.canMoveFreely = YES;
    m_actorBlock.props.affectedByGravity = YES;
    m_actorBlock.props.affectedByFriction = NO; // walking friction handled specially.

    // by default, badGuys are hurty on every edge except top edge (so player can stand on them). This can be overridden by subclasses.
    m_actorBlock.props.hurtyMask = BlockEdgeDirMask_Left | BlockEdgeDirMask_Right | BlockEdgeDirMask_Down;
}


// override
-(void)onBorn
{
    [super onBorn];
    
    m_lifeState = ActorLifeState_Alive;
    
    m_actorBlock = [[ActorBlock alloc] initAtPoint:m_startingPoint];
    m_actorBlock.owningActor = self;
    m_actorBlock.state.d = [self getActorBlockSize];
    
    [self setPropsForActorBlock];
    
    // must come after dimensions have been set.
    [m_world.elbowRoom addBlock:m_actorBlock];
    
    [self updateCurrentAnimState];
}


// override
-(void)onStartDying
{
    [super onStartDying];
    
    m_lifeState = ActorLifeState_Dying;
    m_lifeStateTimer = BADGUY_DYING_TIME;
    
    // remove the ER representation of this actor so that we don't continue to clip during death
    NSAssert( m_actorBlock != nil, @"need actorBlock removed from ER." );
    [m_world.elbowRoom removeBlock:m_actorBlock];
    
    [m_actorBlock release];
    m_actorBlock = nil;  // don't allow world to continue to update our block.
}


// override
-(void)onDead
{
    [super onDead];
    
    m_lifeState = ActorLifeState_Dead;
    
    if( m_world != nil )
    {
        [m_world onActorDied:self];
    }
}


// override
-(void)onFellOffWorld
{
    [super onFellOffWorld];
    if( m_lifeState == ActorLifeState_Alive )
    {
        [self onStartDying];
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TestMeanieBActor

@implementation TestMeanieBActor

-(id)initAtStartingPoint:(EmuPoint)p
{
    if( self = [super initAtStartingPoint:p] )
    {
        m_facingLeft = YES;
        
        m_walkAccel = TESTMEANIEB_LR_ACCEL;
        m_walkMaxV = TESTMEANIEB_LR_MAX_V;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


// override
-(void)updateCurrentAnimState
{
    [super updateCurrentAnimState];
    
    static const float runningAnimDur = 0.5f;
    if( m_actorBlock != nil )
    {
        m_actorBlock.defaultSpriteState = [[[AnimSpriteState alloc] initWithAnimName:@"testMeanieB" animDur:runningAnimDur] autorelease];
    }
}


// override
-(void)onStartDying
{
    [super onStartDying];
    
    // TODO particle effects can be initialized here.
}


// override
-(void)updateControlStateWithTimeDelta:(float)delta
{
    [super updateControlStateWithTimeDelta:delta];
    
    // update CreatureActor state.
    if( m_facingLeft )
    {
        m_walkingLeft = YES;
        m_walkingRight = NO;
        m_actorBlock.defaultSpriteState.isFlipped = YES;
    }
    else
    {
        m_walkingLeft = NO;
        m_walkingRight = YES;
        m_actorBlock.defaultSpriteState.isFlipped = NO;
    }
}


// override
-(void)bouncedOnXAxis:(BOOL)xAxis
{
    [super bouncedOnXAxis:xAxis];
    if( xAxis )
    {
        m_facingLeft = !m_facingLeft;
    }
    
    // since our block doesn't have intrinsic velocity, bounce it ourselves here.
    // zero the bounced velocity component so that we have a chance to accelerate in the
    // new direction before bouncing again.
    // future: it's actually more realisitic for this to just flip sign sometimes (think bouncing ball)
    EmuPoint oldV = [m_actorBlock getV];
    Emu xComponent = xAxis ? 0 : oldV.x;
    Emu yComponent = xAxis ? oldV.y : 0;
    [m_actorBlock setV:EmuPointMake(xComponent, yComponent) ];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// FaceboneActor

@implementation FaceboneActor

-(id)initAtStartingPoint:(EmuPoint)p
{
    if( self = [super initAtStartingPoint:p] )
    {
        m_currentState = FaceboneState_Chillin;
        
        float factor = ( frand() * 0.4f + 0.8f);  // fuzzy
        m_timeRemainingInCurrentState = factor * FACEBONE_CHILLTIME;
        
        m_jumpMaxV = BADGUY_JUMP_MAX_V;
        m_numJumpsAllowed = 1;
        m_jumpDuration = BADGUY_MAX_JUMP_DURATION;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


// override
-(void)updateCurrentAnimState
{
    [super updateCurrentAnimState];
    
    if( m_actorBlock == nil )
    {
        return;
    }

    static const float menaceAnimDur = 0.1f;

    switch( m_currentState )
    {
        case FaceboneState_Chillin:
        case FaceboneState_Jumping:
            m_actorBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"badguy_faceBone0"] autorelease];
            break;
            
        case FaceboneState_FakeOut:
        case FaceboneState_GettingReadyToJump:
            m_actorBlock.defaultSpriteState = [[[AnimSpriteState alloc] initWithAnimName:@"faceBoneMenace" animDur:menaceAnimDur] autorelease];
            break;
            
        default:
            NSLog( @"updateCurrentAnimState: unrecognized facebone state." );
            break;
    }
    
    BOOL playerToLeft = [m_world getPlayerActor].actorBlock.x < m_actorBlock.x;
    m_actorBlock.defaultSpriteState.isFlipped = playerToLeft;
}

// override
-(void)onStartDying
{
    [super onStartDying];
    // TODO particle effects can be initialized here.
}


-(void)goNextState
{
    m_currentlyJumping = NO;
    
    float factor;
    switch( m_currentState )
    {
        case FaceboneState_Chillin:
            // either go to fakeout or getReady
            m_currentState = (frand() < FACEBONE_FAKEOUT_CHANCE) ? FaceboneState_FakeOut : FaceboneState_GettingReadyToJump;
            m_timeRemainingInCurrentState = FACEBONE_PREJUMP_TIME;
            break;
            
        case FaceboneState_FakeOut:
            m_currentState = FaceboneState_Chillin;
            factor = ( frand() * 0.4f + 0.8f) * 0.5f;  // fuzzy, half
            m_timeRemainingInCurrentState = factor * FACEBONE_CHILLTIME;
            break;
            
        case FaceboneState_Jumping:
            [self onJumpEvent:NO];
            m_currentState = FaceboneState_Chillin;
            factor = ( frand() * 0.4f + 0.8f);  // fuzzy
            m_timeRemainingInCurrentState = factor * FACEBONE_CHILLTIME;
            break;
            
        case FaceboneState_GettingReadyToJump:
            m_currentState = FaceboneState_Jumping;
            m_timeRemainingInCurrentState = FACEBONE_JUMPTIME;  // may be different than actual jump time, as defined by actor.jumpDuration
            [self onJumpEvent:YES];
            break;
            
        default:
            NSLog( @"goNextState: unrecognized facebone state." );
            break;
    }
    [self updateCurrentAnimState];
}


// override
-(void)updateControlStateWithTimeDelta:(float)delta
{
    [super updateControlStateWithTimeDelta:delta];
    
    m_timeRemainingInCurrentState -= delta;
    if( m_timeRemainingInCurrentState <= 0.f )
    {
        [self goNextState];
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// Crumbles1Actor

@interface Crumbles1Actor (private)

-(void)spawnActorBlock;

@end

@implementation Crumbles1Actor


-(id)initAtStartingPoint:(EmuPoint)p
{
    if( self = [super initAtStartingPoint:p] )
    {
        m_lifeState = ActorLifeState_BeingBorn;  // this actor doesn't use the typical life cycle.
        m_lifeStateTimer = 0.f;
        m_currentState = Crumbles1State_Chillin;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(void)updateCurrentAnimState
{
    if( m_actorBlock == nil )
    {
        return;
    }

    AnimSpriteState *animSpriteState;
    
    switch( m_currentState )
    {
        case Crumbles1State_Chillin:
            m_actorBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"bl_crumbles1_full"] autorelease];
            break;

        case Crumbles1State_Crumbling:
            animSpriteState = [[[AnimSpriteState alloc] initWithAnimName:@"bl_crumbles1_crumbling" animDur:CRUMBLES1_CRUMBLETIME] autorelease];
            m_actorBlock.defaultSpriteState = animSpriteState;
            animSpriteState.wrap = NO;
            break;
            
        case Crumbles1State_Gone:
            // no block
            break;
            
        case Crumbles1State_Reappearing:
            animSpriteState = [[[AnimSpriteState alloc] initWithAnimName:@"bl_crumbles1_reappearing" animDur:CRUMBLES1_REAPPEARTIME] autorelease];
            m_actorBlock.defaultSpriteState = animSpriteState;
            animSpriteState.wrap = NO;
            break;

        default:
            NSLog( @"updateCurrentAnimState: unrecognized crumbles state." );
            break;
    }
    m_actorBlock.defaultSpriteState.isFlipped = NO;
}


-(void)spawnActorBlock
{
    m_actorBlock = [[ActorBlock alloc] initAtPoint:m_startingPoint];
    m_actorBlock.owningActor = self;
    m_actorBlock.props.canMoveFreely = NO;
    m_actorBlock.props.affectedByGravity = NO;
    m_actorBlock.props.affectedByFriction = NO;
    m_actorBlock.props.bounceDampFactor = 0.f;    
    m_actorBlock.props.initialVelocity = EmuPointMake( 0, 0 );
    m_actorBlock.props.solidMask = BlockEdgeDirMask_Full;
    m_actorBlock.props.xConveyor = 0.f;
    m_actorBlock.props.hurtyMask = BlockEdgeDirMask_None;
    m_actorBlock.props.isGoalBlock = NO;
    m_actorBlock.props.isPlayerBlock = NO;

    m_actorBlock.state.d = EmuSizeMake( 4 * ONE_BLOCK_SIZE_Emu, 4 * ONE_BLOCK_SIZE_Emu );

    NSAssert( m_actorBlock.state.d.width != 0 && m_actorBlock.state.d.height != 0, @"must come after dimensions have been set" );
    NSAssert( m_world != nil, @"need world's ER at spawn time" );
    [m_world.elbowRoom addBlock:m_actorBlock];
    
    [self updateCurrentAnimState];
}


// override
-(void)onBorn
{
    [self spawnActorBlock];
    m_lifeState = ActorLifeState_Alive;  // actor remains alive indefinitely, even when the actorBlock is temporarily gone.
}


-(void)onGone
{
    [m_world.elbowRoom removeBlock:m_actorBlock];
    m_actorBlock.defaultSpriteState = nil;
    [m_actorBlock release]; m_actorBlock = nil;
}


-(void)onReappear
{
    [self spawnActorBlock];
}


-(void)goNextState
{
    switch( m_currentState )
    {
        case Crumbles1State_Crumbling:
            m_currentState = Crumbles1State_Gone;
            m_timeRemainingInCurrentState = CRUMBLES1_GONETIME;
            [self onGone];
            break;
        case Crumbles1State_Gone:
            m_currentState = Crumbles1State_Reappearing;
            m_timeRemainingInCurrentState = CRUMBLES1_REAPPEARTIME;
            [self onReappear];
            break;
        case Crumbles1State_Reappearing:
            m_currentState = Crumbles1State_Chillin;
            break;
            
        case Crumbles1State_Chillin:
            NSAssert( NO, @"no state updates for Chillin" );
            break;

        default:
            NSLog( @"goNextState: unrecognized crumbles state." );
            break;
    }
    [self updateCurrentAnimState];
}


// override
-(void)updateControlStateWithTimeDelta:(float)delta
{
    [super updateControlStateWithTimeDelta:delta];
    
    if( m_currentState == Crumbles1State_Chillin )
    {
        return;
    }
    
    m_timeRemainingInCurrentState -= delta;
    if( m_timeRemainingInCurrentState <= 0.f )
    {
        [self goNextState];
    }
}


// override
-(void)collidedInto:(NSObject<ISolidObject> *)node inDir:(ERDirection)dir
{
    [super collidedInto:node inDir:dir];

    if( m_currentState != Crumbles1State_Chillin )
    {
        return;
    }

    // since crumbles doesn't move, we only get collision events from other SOs that
    // moved into us. so this method will be getting called from their perspective,
    // meaning we're actually listening for the Up direction to trigger us.
    if( dir == ERDirUp )
    {
        m_currentState = Crumbles1State_Crumbling;
        m_timeRemainingInCurrentState = CRUMBLES1_CRUMBLETIME;
        [self updateCurrentAnimState];
    }
}

@end
