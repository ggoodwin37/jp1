//
//  BadGuyActor.m
//  JumpProto
//
//  Created by Gideon iOS on 7/28/13.
//
//

#import "BadGuyActor.h"
#import "World.h"
#import "constants.h"

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
