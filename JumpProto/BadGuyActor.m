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
        m_lifeState = ActorLifeState_NotBornYet;
        m_lifeStateTimer = BADGUY_NOTBORNYET_TIME;
    }
    return self;
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
    ActorBlock *actorBlock = [self getDefaultActorBlock];
    actorBlock.props.canMoveFreely = YES;
    actorBlock.props.affectedByGravity = YES;
    actorBlock.props.affectedByFriction = NO; // walking friction handled specially.
    actorBlock.props.followsAiHints = YES;
    actorBlock.props.weight = BADGUY_WEIGHT;
    
    // by default, badGuys are hurty on every edge except top edge (so player can stand on them). This can be overridden by subclasses.
    actorBlock.props.hurtyMask = BlockEdgeDirMask_Left | BlockEdgeDirMask_Right | BlockEdgeDirMask_Down;
}


// override
-(void)onBorn
{
    [super onBorn];
    
    m_lifeState = ActorLifeState_Alive;
    
    ActorBlock *actorBlock = [[ActorBlock alloc] initAtPoint:m_startingPoint];
    [m_actorBlockList addObject:actorBlock];
    
    actorBlock.owningActor = self;
    actorBlock.state.d = [self getActorBlockSize];
    
    [self setPropsForActorBlock];
    
    // must come after dimensions have been set.
    [m_world.elbowRoom addBlock:actorBlock];
    
    [self updateCurrentAnimState];
}


// override
-(void)onStartDying
{
    [super onStartDying];
    
    m_lifeState = ActorLifeState_Dying;
    m_lifeStateTimer = BADGUY_DYING_TIME;
    
    ActorBlock *actorBlock = [self getDefaultActorBlock];
    // remove the ER representation of this actor so that we don't continue to clip during death
    NSAssert( actorBlock != nil, @"need actorBlock removed from ER." );
    [m_world.elbowRoom removeBlock:actorBlock];
    [m_actorBlockList removeObjectAtIndex:0];
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

        m_jumpMaxV = GENERIC_HOP_JUMP_MAX_V;
        m_numJumpsAllowed = 1;
        m_jumpDuration = GENERIC_HOP_MAX_JUMP_DURATION;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(NSString *)getAnimDefName
{
    return @"testMeanieB";
}


// override
-(void)updateCurrentAnimState
{
    [super updateCurrentAnimState];
    
    static const float runningAnimDur = 0.5f;
    ActorBlock *actorBlock = [self getDefaultActorBlock];
    if( actorBlock != nil )
    {
        actorBlock.defaultSpriteState = [[[AnimSpriteState alloc] initWithAnimName:[self getAnimDefName] animDur:runningAnimDur] autorelease];
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
        [self getDefaultActorBlock].defaultSpriteState.isFlipped = YES;
    }
    else
    {
        m_walkingLeft = NO;
        m_walkingRight = YES;
        [self getDefaultActorBlock].defaultSpriteState.isFlipped = NO;
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
    ActorBlock *actorBlock = [self getDefaultActorBlock];
    EmuPoint oldV = [actorBlock getV];
    Emu xComponent = xAxis ? 0 : oldV.x;
    Emu yComponent = xAxis ? oldV.y : 0;
    [actorBlock setV:EmuPointMake(xComponent, yComponent) ];
}


// override
-(BOOL)canHop
{
    return YES;
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TinyFuzzActor

@implementation TinyFuzzActor

-(id)initAtStartingPoint:(EmuPoint)p goingLeft:(BOOL)goingLeft
{
    if( self = [super initAtStartingPoint:p] )
    {
        m_facingLeft = goingLeft;
        m_walkAccel = TINYFUZZ_LR_ACCEL;
        m_walkMaxV = TINYFUZZ_LR_MAX_V;
    }
    return self;
}


// override
-(NSString *)getAnimDefName
{
    return @"tiny-creep-fuzz-walking";
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
    
    ActorBlock *actorBlock = [self getDefaultActorBlock];
    if( actorBlock == nil )
    {
        return;
    }
    
    static const float menaceAnimDur = 0.1f;
    
    switch( m_currentState )
    {
        case FaceboneState_Chillin:
        case FaceboneState_Jumping:
            actorBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"badguy_faceBone0"] autorelease];
            break;
            
        case FaceboneState_FakeOut:
        case FaceboneState_GettingReadyToJump:
            actorBlock.defaultSpriteState = [[[AnimSpriteState alloc] initWithAnimName:@"faceBoneMenace" animDur:menaceAnimDur] autorelease];
            break;
            
        default:
            NSLog( @"updateCurrentAnimState: unrecognized facebone state." );
            break;
    }
    
    ActorBlock *playerActorBlock = [[m_world getPlayerActor] getDefaultActorBlock];
    BOOL playerToLeft = playerActorBlock.x < actorBlock.x;
    actorBlock.defaultSpriteState.isFlipped = playerToLeft;
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


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TinyJellyActor

@implementation TinyJellyActor

-(id)initAtStartingPoint:(EmuPoint)p onXAxis:(BOOL)xAxis
{
    if( self = [super initAtStartingPoint:p] )
    {
        m_xAxis = xAxis;
        m_facingPositive = YES;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


// override
-(void)setPropsForActorBlock
{
    [super setPropsForActorBlock];
    ActorBlock *actorBlock = [self getDefaultActorBlock];
    actorBlock.props.affectedByGravity = NO;
    actorBlock.props.hurtyMask = BlockEdgeDirMask_Full;
    actorBlock.props.weight = IMMOVABLE_WEIGHT;
    actorBlock.props.bounceFactor = -1.f;

    int sign = m_facingPositive ? 1 : -1;
    Emu xComponent = m_xAxis ? (sign * TINYJELLY_V) : 0;
    Emu yComponent = m_xAxis ? 0 : (sign * TINYJELLY_V);
    actorBlock.state.vIntrinsic = EmuPointMake(xComponent, yComponent);
}


// override
-(void)updateCurrentAnimState
{
    [super updateCurrentAnimState];
    
    static const float animDur = 0.5f;
    ActorBlock *actorBlock = [self getDefaultActorBlock];
    if( actorBlock != nil )
    {
        NSString *animName = @"tiny-creep-jelly-wobble";
        actorBlock.defaultSpriteState = [[[AnimSpriteState alloc] initWithAnimName:animName animDur:animDur] autorelease];
    }
}


// override
-(void)bouncedOnXAxis:(BOOL)xAxis
{
    [super bouncedOnXAxis:xAxis];
    if( xAxis != m_xAxis ) return;  // if we bounced on the other axis than our primary motion axis, do nothing.
    
    ActorBlock *actorBlock = [self getDefaultActorBlock];
    EmuPoint oldV = [actorBlock getV];
    Emu xComponent = m_xAxis ? -oldV.x : 0;
    Emu yComponent = m_xAxis ? 0 : -oldV.y;
    [actorBlock setV:EmuPointMake(xComponent, yComponent) ];
}


// override, required for vIntrinsic to work.
-(EmuPoint)getMotiveAccel
{
    const Emu fullAccelInOneFrame = 60 * PLAYERINPUT_JUMP_MAX_V;
    return EmuPointMake( fullAccelInOneFrame, fullAccelInOneFrame );
}

@end
