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


-(BOOL)shouldReverseWalkDirection
{
    return NO;
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


// this name is so awkward. this runs every frame if the actor is standing on solid ground.
//  (useful for baselining jump-related counters)
-(void)updateStateForStandingOnGround
{
    m_jumpsRemaining = m_numJumpsAllowed;
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
        [self updateStateForStandingOnGround];
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
    
    BOOL lSignal;
    BOOL rSignal;
    if( [self shouldReverseWalkDirection] )
    {
        lSignal = m_walkingRight;
        rSignal = m_walkingLeft;
    }
    else
    {
        lSignal = m_walkingLeft;
        rSignal = m_walkingRight;
    }
    
    if( lSignal )
    {
        xMotive = -1 * m_walkMaxV;
    }
    else if( rSignal )
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


-(NSString *)getSpriteResourceNameForCurrentState
{
    switch( m_currentState )
    {
        case Crumbles1State_Chillin:
            return @"bl_crumbles1_full";
            
        case Crumbles1State_Crumbling:
            return @"bl_crumbles1_crumbling";
            
        case Crumbles1State_Gone:
            return nil;
            
        case Crumbles1State_Reappearing:
            return @"bl_crumbles1_reappearing";
            
        default:
            NSLog( @"getResourceNameForCurrentState: unrecognized crumbles state." );
            break;
    }
}


-(void)updateCurrentAnimStateForCrumbles1
{
    if( m_actorBlock == nil )
    {
        return;
    }

    AnimSpriteState *animSpriteState;
    NSString *spriteResourceName = [self getSpriteResourceNameForCurrentState];
    
    switch( m_currentState )
    {
        case Crumbles1State_Chillin:
            m_actorBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:spriteResourceName] autorelease];
            break;

        case Crumbles1State_Crumbling:
            animSpriteState = [[[AnimSpriteState alloc] initWithAnimName:spriteResourceName animDur:CRUMBLES1_CRUMBLETIME] autorelease];
            m_actorBlock.defaultSpriteState = animSpriteState;
            animSpriteState.wrap = NO;
            break;
            
        case Crumbles1State_Gone:
            // no block
            break;
            
        case Crumbles1State_Reappearing:
            animSpriteState = [[[AnimSpriteState alloc] initWithAnimName:spriteResourceName animDur:CRUMBLES1_REAPPEARTIME] autorelease];
            m_actorBlock.defaultSpriteState = animSpriteState;
            animSpriteState.wrap = NO;
            break;

        default:
            NSLog( @"updateCurrentAnimStateForCrumbles1: unrecognized crumbles state." );
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
    
    [self updateCurrentAnimStateForCrumbles1];
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
    [self updateCurrentAnimStateForCrumbles1];
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

    BOOL triggered;
#if 0
    // since crumbles doesn't move, we only get collision events from other SOs that
    // moved into us. so this method will be getting called from their perspective,
    // meaning we're actually listening for the Up direction to trigger us.
    triggered = (dir == ERDirUp);
#else
    // on second thought, just trigger it from any direction.
    triggered = YES;
#endif
    if( triggered )
    {
        m_currentState = Crumbles1State_Crumbling;
        m_timeRemainingInCurrentState = CRUMBLES1_CRUMBLETIME;
        [self updateCurrentAnimStateForCrumbles1];
    }
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////// TinyCrumActor

@implementation TinyCrumActor

// override
-(NSString *)getSpriteResourceNameForCurrentState
{
    switch( m_currentState )
    {
        case Crumbles1State_Chillin:
            return @"tiny-crum-0";
            
        case Crumbles1State_Crumbling:
            return @"tiny-crum-crumbling";
            
        case Crumbles1State_Gone:
            return nil;
            
        case Crumbles1State_Reappearing:
            return @"tiny-crum-reappearing";
            
        default:
            NSLog( @"getResourceNameForCurrentState: unrecognized crumbles state." );
            break;
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TinyAutoLiftActor

@implementation TinyAutoLiftActor

-(id)initAtStartingPoint:(EmuPoint)p withSizeInUnits:(EmuPoint)sizeInUnits
{
    if( self = [super initAtStartingPoint:p] )
    {
        m_lifeState = ActorLifeState_BeingBorn;  // this actor doesn't use the typical life cycle.
        m_lifeStateTimer = 0.f;
        m_currentState = TinyAutoLiftActor_Idle;
        
        m_idleSpriteState = [[StaticSpriteState alloc] initWithSpriteName:@"tiny-autolift-0"];
        m_activeSpriteState = [[StaticSpriteState alloc] initWithSpriteName:@"tiny-autolift-1"];
        
        m_lastRecordedY = p.y + 123;  // trigger update first frame.
        
        m_blockSizeInUnits = sizeInUnits;
    }
    return self;
}


-(void)dealloc
{
    [m_activeSpriteState release]; m_activeSpriteState = nil;
    [m_idleSpriteState release]; m_idleSpriteState = nil;
    [super dealloc];
}


-(void)updateCurrentAnimStateForTinyAutoLift
{
    if( m_actorBlock == nil )
    {
        return;
    }
    switch( m_currentState )
    {
        case TinyAutoLiftActor_Idle:
        case TinyAutoLiftActor_Coming:
            [m_actorBlock setAllSpritesTo:m_idleSpriteState];
            break;
            
        case TinyAutoLiftActor_Trigged:
        case TinyAutoLiftActor_Going:
            [m_actorBlock setAllSpritesTo:m_activeSpriteState];
            break;
            
        default:
            NSLog( @"updateCurrentAnimStateForTinyAutoLift: unrecognized crumbles state." );
            break;
    }
}



-(void)spawnActorBlock
{
    // TODO: this assumes the sprite->world factor is 4, should actually check although it would have to be
    //       the same for all sprites used by the actor I guess (true in this case).
    CGSize spriteStateMapSize = CGSizeMake( m_blockSizeInUnits.x / 4, m_blockSizeInUnits.y / 4 );
    
    SpriteStateMap *spriteStateMap = [[[SpriteStateMap alloc] initWithSize:spriteStateMapSize] autorelease];
    m_actorBlock = [[ActorBlock alloc] initAtPoint:m_startingPoint spriteStateMap:spriteStateMap];
    m_actorBlock.owningActor = self;
    m_actorBlock.props.canMoveFreely = YES;
    m_actorBlock.props.affectedByGravity = NO;
    m_actorBlock.props.affectedByFriction = NO;
    m_actorBlock.props.bounceDampFactor = 0.f;
    m_actorBlock.props.initialVelocity = EmuPointMake( 0, 0 );
    m_actorBlock.props.solidMask = BlockEdgeDirMask_Full;
    m_actorBlock.props.xConveyor = 0.f;
    m_actorBlock.props.hurtyMask = BlockEdgeDirMask_None;
    m_actorBlock.props.isGoalBlock = NO;
    m_actorBlock.props.isPlayerBlock = NO;
    m_actorBlock.props.immovable = YES;  // can't be moved by other blocks.
    
    m_actorBlock.state.d = EmuSizeMake( m_blockSizeInUnits.x * ONE_BLOCK_SIZE_Emu, m_blockSizeInUnits.y * ONE_BLOCK_SIZE_Emu );
    
    NSAssert( m_world != nil, @"need world's ER at spawn time" );
    [m_world.elbowRoom addBlock:m_actorBlock];
    
    [self updateCurrentAnimStateForTinyAutoLift];
}


// override
-(void)onBorn
{
    [self spawnActorBlock];
    m_lifeState = ActorLifeState_Alive;  // actor remains alive indefinitely, even when the actorBlock is temporarily gone.
}


// override
-(EmuPoint)getMotive
{
    if( m_currentState == TinyAutoLiftActor_Going )
    {
        return EmuPointMake( 0, TINYAUTOLIFT_GOING_V );
    }
    else if( m_currentState == TinyAutoLiftActor_Coming )
    {
        return EmuPointMake( 0, TINYAUTOLIFT_COMING_V );
    }
    return EmuPointMake( 0, 0 );
}


// override
-(EmuPoint)getMotiveAccel
{
    return EmuPointMake( 0, TINYAUTOLIFT_ACCEL );
}


-(void)goNextState
{
    switch( m_currentState )
    {
        case TinyAutoLiftActor_Trigged:
            m_currentState = TinyAutoLiftActor_Going;
            // taking off (fire some sweet particle effects...one day)
            break;
            
        default:
            NSLog( @"goNextState: unrecognized tinyAutoLift state." );
            break;
    }
    [self updateCurrentAnimStateForTinyAutoLift];
}


-(BOOL)checkIfVerticalMotionStoppedWithDelta:(float)delta
{
    if( m_actorBlock == nil )
    {
        return NO;
    }
    Emu currentY = m_actorBlock.y;
    if( currentY != m_lastRecordedY )
    {
        m_lastRecordedY = currentY;
        m_lastRecordedYTimeRemaining = (m_currentState == TinyAutoLiftActor_Going ? TINYAUTOLIFT_RESETTIME : 0);
        return NO;
    }
    m_lastRecordedYTimeRemaining -= delta;
    return m_lastRecordedYTimeRemaining <= 0.f;
}


// override
-(void)updateControlStateWithTimeDelta:(float)delta
{
    [super updateControlStateWithTimeDelta:delta];
    
    if( m_currentState == TinyAutoLiftActor_Idle )
    {
        return;
    }

    if( m_currentState == TinyAutoLiftActor_Coming || m_currentState == TinyAutoLiftActor_Going )
    {
        if( [self checkIfVerticalMotionStoppedWithDelta:delta] )
        {
            if( m_currentState == TinyAutoLiftActor_Going )
            {
                m_currentState = TinyAutoLiftActor_Coming;
                m_lastRecordedY = m_lastRecordedY + 123;
            }
            else
            {
                m_currentState = TinyAutoLiftActor_Idle;
                m_lastRecordedY = m_lastRecordedY - 123;
            }
            [m_actorBlock setV:EmuPointMake( 0, 0 )];
            [self updateCurrentAnimStateForTinyAutoLift];
        }
    }

    // only trigged state needs time update
    if( m_currentState != TinyAutoLiftActor_Trigged )
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

    if( m_currentState != TinyAutoLiftActor_Idle )
    {
        return;
    }
    
    BOOL triggered;
    // since this actor doesn't move while idle, we only get collision events from other SOs that
    // moved into us. so this method will be getting called from their perspective,
    // meaning we're actually listening for the Up direction to trigger us.
    triggered = (dir == ERDirUp);
    if( triggered )
    {
        m_currentState = TinyAutoLiftActor_Trigged;;
        m_timeRemainingInCurrentState = TINYAUTOLIFT_TRIGTIME;
        [self updateCurrentAnimStateForTinyAutoLift];
    }
}

@end
