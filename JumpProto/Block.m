//
//  Block.m
//  JumpProto
//
//  Created by gideong on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Block.h"
#import "constants.h"
#import "BlockUpdater.h"
#import "Actor.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// BlockState

@implementation BlockState

@synthesize vIntrinsic;


-(id)init
{
    if( self = [super init] )
    {
        self.vIntrinsic = EmuPointMake( 0, 0 );
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(void)setRect:(EmuRect)rect
{
    m_p = rect.origin;
    m_d = rect.size;
}


-(EmuPoint)getP
{
    return m_p;
}


-(void)setP:(EmuPoint)p
{
    m_p = p;
}


-(EmuPoint)getV
{
    return m_v;
}


-(void)setV:(EmuPoint)v
{
    m_v = v;
}


-(EmuSize)getD
{
    return m_d;
}


-(void)setD:(EmuSize)d
{
    m_d = d;
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EvStateCache

@implementation EvStateCache
@synthesize lastTriggerTime, isOn;

-(id)init
{
    if( self = [super init] )
    {
        self.lastTriggerTime = 0;
        self.isOn = 0;
    }
    return self;
}
@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EvBlockState

@implementation EvBlockState

-(id)initFromBlockState:(BlockState *)blockStateIn fx:(WorldEventFX *)fxIn
{
    if( self = [super init] )
    {
        self.p = blockStateIn.p;
        self.v = blockStateIn.v;
        self.d = blockStateIn.d;
        m_stateCache = [[EvStateCache alloc] init];
        m_fx = [fxIn retain];
    }
    return self;
}


-(void)dealloc
{
    [m_fx release]; m_fx = nil;
    [m_stateCache release]; m_stateCache = nil;
    [super dealloc];
}


// WorldEventHandler
-(void)onWorldEvent:(WorldEvent *)event
{
    switch( event.type )
    {
        case WEDown:
            m_stateCache.lastTriggerTime = getUpTimeMs();
            m_stateCache.isOn = YES;
            break;
        case WEUp:
            m_stateCache.isOn = NO;
            break;
        default:
            break;
    }
}


-(EmuPoint)getOffsetV
{
    Emu vx = 0, vy = 0;
    if( m_fx.type == WFXTest )
    {
        // basic test: just give me some velocity if I'm triggered.
        if( m_stateCache.lastTriggerTime != 0 )
        {
            long deltaT = getUpTimeMs() - m_stateCache.lastTriggerTime;
            const int moveTime = 500;
            const int restTime = 1500;
            if( deltaT < moveTime )
            {
                vy = TEST_EVENT_V;
            }
            else if( deltaT >= (moveTime + restTime) && deltaT < (moveTime + restTime + moveTime) )
            {
                vy = -TEST_EVENT_V;
            }
        }
    }
    return EmuPointMake( vx, vy );
}


// override
-(EmuPoint)getV
{
    EmuPoint base = [super getV];
    EmuPoint offset = [self getOffsetV];
    return EmuPointMake( base.x + offset.x, base.y + offset.y );
}

// TODO: support more property overrides as other event types require them.

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////// BlockProps

@implementation BlockProps

@synthesize token = m_token, canMoveFreely = m_canMoveFreely, affectedByGravity = m_affectedByGravity;
@synthesize bounceFactor = m_bounceFactor, affectedByFriction = m_affectedByFriction;
@synthesize initialVelocity = m_initialVelocity, solidMask = m_solidMask, hurtyMask = m_hurtyMask;
@synthesize isWallJumpable;
@synthesize isGoalBlock = m_isGoalBlock;
@synthesize isPlayerBlock = m_isPlayerBlock;
@synthesize isActorBlock;
@synthesize isAiHint, followsAiHints;
@synthesize xConveyor = m_xConveyor;
@synthesize springyMask;
@synthesize weight;
@synthesize eventSolidMask;
@synthesize redBluState;
@synthesize bModeActive;
@synthesize isHopBlock;

-(id)init
{
    if( self = [super init] )
    {
        m_token = [BlockProps nextToken];
        
        m_solidMask = BlockEdgeDirMask_Full;
        
        m_tokenAsString = nil;  // lazy
        
        self.weight = DEFAULT_WEIGHT;
        self.eventSolidMask = BlockEdgeDirMask_None;
        self.redBluState = BlockRedBlueState_None;
        self.bModeActive = NO;
    }
    return self;
}


-(void)dealloc
{
    [m_tokenAsString release]; m_tokenAsString = nil;
    [super dealloc];
}


+(BlockToken)nextToken
{
    static BlockToken nextToken = 256;
    BlockToken result = nextToken;
    nextToken++;
    return result;
}


// a string representation of the token, instantiated lazily (since we don't want hundreds of strings sitting around for inert blocks)
-(NSString *)getTokenAsString
{
    if( m_tokenAsString == nil )
    {
        m_tokenAsString = [[NSString stringWithFormat:@"%u", (unsigned int)m_token] retain];
    }
    return m_tokenAsString;
}


-(void)copyFrom:(BlockProps *)other
{
    self.canMoveFreely = other.canMoveFreely;
    self.affectedByGravity = other.affectedByGravity;
    self.bounceFactor = other.bounceFactor;
    self.affectedByFriction = other.affectedByFriction;
    self.initialVelocity = other.initialVelocity;
    self.solidMask = other.solidMask;
    self.xConveyor = other.xConveyor;
    self.hurtyMask = other.hurtyMask;
    self.isGoalBlock = other.isGoalBlock;
    self.isPlayerBlock = other.isPlayerBlock;
    self.springyMask = other.springyMask;
    self.isAiHint = other.isAiHint;
    self.followsAiHints = other.followsAiHints;
    self.isWallJumpable = other.isWallJumpable;
    self.weight = other.weight;
    self.eventSolidMask = other.eventSolidMask;
    self.redBluState = other.redBluState;
    self.bModeActive = other.bModeActive;
    self.isHopBlock = other.isHopBlock;
    // lol is this method even getting used anywhere?
}


-(bool)equalTo:(BlockProps *)other
{
    return (
                self.canMoveFreely == other.canMoveFreely &&
                self.affectedByGravity == other.affectedByGravity &&
                self.bounceFactor == other.bounceFactor &&
                self.affectedByFriction == other.affectedByFriction &&
                self.initialVelocity.x == other.initialVelocity.x &&
                self.initialVelocity.y == other.initialVelocity.y &&
                self.solidMask == other.solidMask &&
                self.xConveyor == other.xConveyor &&
                self.hurtyMask == other.hurtyMask &&
                self.isGoalBlock == other.isGoalBlock &&
                self.isPlayerBlock == other.isPlayerBlock &&
                self.springyMask == other.springyMask &&
                self.isAiHint == other.isAiHint &&
                self.followsAiHints == other.followsAiHints &&
                self.isWallJumpable == other.isWallJumpable &&
                self.weight == other.weight &&
                self.eventSolidMask == other.eventSolidMask &&
                self.redBluState == other.redBluState &&
                self.bModeActive == other.bModeActive &&
                self.isHopBlock == isHopBlock
            );
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// Block

@interface Block (private)
@end

@implementation Block

@synthesize state = m_state, props = m_props, key = m_key, groupId = m_groupId;
@synthesize owningGroup;
@synthesize shortCircuitER;


-(id)init
{
    if( self = [super init] )
    {
        m_state = [[BlockState alloc] init];
        m_props = [[BlockProps alloc] init];
        m_key = [[NSString stringWithFormat:@"b%u", (unsigned int)m_props.token ] retain];
        self.groupId = GROUPID_NONE;
        self.owningGroup = nil;
        self.shortCircuitER = 0;
        self.props.isActorBlock = NO;
        self.props.isPlayerBlock = NO;
    }
    return self;
}


-(void)dealloc
{
    self.owningGroup = nil;
    [m_key release]; m_key = nil;
    [m_state release]; m_state = nil;
    [m_props release]; m_props = nil;
    [super dealloc];
}


-(Emu)getX
{
    return m_state.p.x;
}


-(Emu)getY
{
    return m_state.p.y;
}


-(Emu)getW
{
    return m_state.d.width;
}


-(Emu)getH
{
    return self.state.d.height;
}


-(BlockToken)getToken
{
    return self.props.token;
}


-(BOOL)isGroup
{
    return NO;
}


-(BOOL)isGroupElement
{
    return self.owningGroup != nil;
}


-(BlockProps *)getProps
{
    return self.props;
}


-(EmuPoint)getV
{
    if( self.owningGroup != nil )
    {
        return [self.owningGroup getV];
    }
    return self.state.v;
}


-(void)setV:(EmuPoint)v
{
    self.state.v = v;
}


-(EmuPoint)getMotive
{
    return self.state.vIntrinsic;
}


-(EmuPoint)getMotiveAccel
{
    const Emu c_default = PLAYERINPUT_LR_ACCEL;
    return EmuPointMake( c_default, c_default );
}


-(NSString *)getKey
{
    return self.key;
}


-(void)bouncedOnXAxis:(BOOL)xAxis
{
    // don't process the player block here because we never want to do a normal bounce on player block. This
    //  can break things and/or act unexpectedly. The specific reason I am adding this bailout is for up-gaps.
    //  when we bounce upward trying to jump into an up-gap, we'd try to zero y velocity at the bottom of this
    //  function, which means player can't ever jump up into y-gaps.
    // Conceptually it would be more correct to not care about player block here, and just use [self getMotive]
    //  instead of self.state.vIntrinsic, then just do the right thing. But getMotive doesn't work that way currently.
    if( m_props.isPlayerBlock )
    {
        return;
    }
    
    Emu oldVal;
    BOOL fIntrinsicChanged = NO;
    EmuPoint vIntrinsic = self.state.vIntrinsic;  // TODO: this should really be motive instead (which is implemented as vIntrinsic for plain blocks).
    BOOL fHasIntrinsic = (vIntrinsic.x != 0) || (vIntrinsic.y != 0);
    if( xAxis )
    {
        oldVal = vIntrinsic.x;
        self.state.vIntrinsic = EmuPointMake( self.props.bounceFactor * vIntrinsic.x, vIntrinsic.y );
        fIntrinsicChanged = self.state.vIntrinsic.x != oldVal;
    }
    else
    {
        oldVal = vIntrinsic.y;
        self.state.vIntrinsic = EmuPointMake( vIntrinsic.x, self.props.bounceFactor * vIntrinsic.y );
        fIntrinsicChanged = self.state.vIntrinsic.y != oldVal;
    }
    
    if( !fHasIntrinsic || fIntrinsicChanged )
    {
        // zero the bounced velocity component so that we have a chance to accelerate in the
        // new direction before bouncing again.
        // future: it's actually more realistic for this to just flip sign sometimes (think bouncing ball)
        EmuPoint oldV = [self getV];
        Emu xComponent = xAxis ? 0 : oldV.x;
        Emu yComponent = xAxis ? oldV.y : 0;
        [self setV:EmuPointMake(xComponent, yComponent) ];
    }
}


-(BOOL)collidedInto:(NSObject<ISolidObject> *)node inDir:(ERDirection)dir props:(BlockProps *)props
{
    UInt32 springyMask = (props != nil) ? props.springyMask : [node getProps].springyMask;
    BOOL didBounce = NO;
    if( springyMask > 0 )
    {
        BlockEdgeDirMask otherMask = [Block getOpposingEdgeMaskForDir:dir];
        
        if( ([node getProps].springyMask & otherMask) > 0 )
        {
            EmuPoint oldV = [self getV];
            EmuPoint newV = EmuPointMake( oldV.x, SPRING_VY );
            [self setV:newV];
            didBounce = YES;
        }
    }
    return didBounce;
}


-(void)changePositionOnXAxis:(BOOL)onXAxis signedMoveOffset:(Emu)didMoveOffset elbowRoom:(id)elbowRoomIn
{
    NSObject<IElbowRoom> *elbowRoom = (NSObject<IElbowRoom> *)elbowRoomIn;
    Emu targetX, targetY;
    
    // move as far as possible in this direction
    if( onXAxis )
    {
        targetX = self.x + didMoveOffset;
        targetY = self.y;
    }
    else
    {
        targetX = self.x;
        targetY = self.y + didMoveOffset;
    }
    
    // clip to hard limits
    targetX = MIN( MAX( WORLD_MIN_X, targetX ), WORLD_MAX_X );
    targetY = MIN( MAX( WORLD_MIN_Y, targetY ), WORLD_MAX_Y );
    
    // perform the actual move. let ER do this for us so it can update its state correctly.
    EmuPoint offset = EmuPointMake( targetX - self.x, targetY - self.y );
    [elbowRoom moveBlock:self byOffset:offset];
}


+(BlockEdgeDirMask)getOpposingEdgeMaskForDir:(ERDirection)dir
{
    switch( dir )
    {
        case ERDirUp: return BlockEdgeDirMask_Down;
        case ERDirLeft: return BlockEdgeDirMask_Right;
        case ERDirRight: return BlockEdgeDirMask_Left;
        case ERDirDown: return BlockEdgeDirMask_Up;
        default: NSAssert( NO, @"getOpposingEdgeMaskForDir: bad dir" ); return 0;
    }
}


-(void)listenToEventTargetId:(NSString *)targetId fx:(WorldEventFX *)fx dispatcher:(WorldEventDispatcher *)dispatcher
{
    EvBlockState *evBlockState = [[[EvBlockState alloc] initFromBlockState:m_state fx:fx] autorelease];
    [m_state release];
    m_state = [evBlockState retain];

    [dispatcher registerListener:evBlockState forTargetId:targetId];
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteStateMap
@implementation SpriteStateMap
@synthesize size = m_size;

-(id)initWithSize:(CGSize)size
{
    if( self = [super init] )
    {
        m_size = size;
        size_t len = m_size.width * m_size.height * sizeof(SpriteState *);
        m_data = (SpriteState **)malloc( len );
        memset( m_data, 0, len );
    }
    return self;
}


-(void)dealloc
{
    // release all states in map.
    for( int y = 0; y < m_size.height; ++y )
    {
        for( int x = 0; x < m_size.width; ++x )
        {
            [self setSpriteStateAtX:x y:y to:nil];
        }
    }
    free( m_data ); m_data = nil;
    [super dealloc];
}


-(SpriteState *)getSpriteStateAtX:(int)x y:(int)y
{
    int index = y * m_size.width + x;
    return m_data[index];
}


-(void)setSpriteStateAtX:(int)x y:(int)y to:(SpriteState *)spriteState
{
    int index = y * m_size.width + x;
    SpriteState *oldValue = m_data[index];
    m_data[index] = spriteState;
    [spriteState retain];
    [oldValue release];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteBlock
@implementation SpriteBlock

@synthesize spriteStateMap;

-(id)initWithRect:(EmuRect)rect spriteStateMap:(SpriteStateMap *)spriteStateMapIn
{
    if( self = [super init] )
    {
        self.state.p = rect.origin;
        self.state.d = rect.size;
        self.spriteStateMap = spriteStateMapIn;
    }
    return self;
}


-(void)dealloc
{
    self.spriteStateMap = nil;
    [super dealloc];
}


-(SpriteState *)getDefaultSpriteState
{
    return [self.spriteStateMap getSpriteStateAtX:0 y:0];
}


-(void)setDefaultSpriteState:(SpriteState *)spriteState
{
    [self.spriteStateMap setSpriteStateAtX:0 y:0 to:spriteState];
}


-(void)setAllSpritesTo:(SpriteState *)spriteState
{
    CGSize size = self.spriteStateMap.size;
    for( int j = 0; j < size.height; ++j )
    {
        for( int i = 0; i < size.width; ++i )
        {
            [self.spriteStateMap setSpriteStateAtX:i y:j to:spriteState];
        }
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorBlock
@implementation ActorBlock

@synthesize owningActor;

-(id)initAtPoint:(EmuPoint)p spriteStateMap:(SpriteStateMap *)spriteStateMap
{
    EmuRect r = EmuRectMake( p.x, p.y, 0, 0 );  // size set later.
    if( self = [super initWithRect:r spriteStateMap:spriteStateMap] )
    {
        self.owningActor = nil;  // weak
        
        self.state.p = p;
        
        self.props.isActorBlock = YES;
        
        // subclasses or owning Actors should provide dimension and spriteState
    }
    return self;
}


-(id)initAtPoint:(EmuPoint)p
{
    SpriteStateMap *spriteStateMap = [[[SpriteStateMap alloc] initWithSize:CGSizeMake( 1.f, 1.f )] autorelease];
    return [self initAtPoint:p spriteStateMap:spriteStateMap];
}


-(void)dealloc
{
    self.owningActor = nil;
    [super dealloc];
}


// override
-(EmuPoint)getMotive
{
    if( self.owningActor != nil )
    {
        EmuPoint blockNativeMotive = [super getMotive];
        EmuPoint actorMotive = [self.owningActor getMotive];
        return EmuPointMake( blockNativeMotive.x + actorMotive.x, blockNativeMotive.y + actorMotive.y );
    }
    NSAssert( NO, @"unexpected" );
    return EmuPointMake( 0, 0 );
}


// override
-(EmuPoint)getMotiveAccel
{
    if( self.owningActor != nil )
    {
        return [self.owningActor getMotiveAccel];
    }
    NSAssert( NO, @"unexpected" );
    return EmuPointMake( 0, 0 );
}


// override
-(void)bouncedOnXAxis:(BOOL)xAxis
{
    [super bouncedOnXAxis:xAxis];
    [self.owningActor bouncedOnXAxis:xAxis];
}


// override
-(BOOL)collidedInto:(NSObject<ISolidObject> *)node inDir:(ERDirection)dir props:(BlockProps *)props
{
    BOOL didBounce = [super collidedInto:node inDir:dir props:props];
    [self.owningActor collidedInto:node inDir:dir actorBlock:self props:props];
    return didBounce;
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// GibBlock
@implementation GibBlock

// override
-(EmuPoint)getMotiveAccel
{
    return EmuPointMake( GIB_ACCEL, GIB_ACCEL );
}

@end
