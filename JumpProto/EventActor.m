//
//  EventActor.m
//  JumpProto
//
//  Created by Gideon iOS on 8/28/13.
//
//

#import "EventActor.h"
#import "World.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// TinyBtn1Actor

@interface TinyBtn1Actor (private)

-(void)spawnActorBlocks;

@end

@implementation TinyBtn1Actor

-(id)initAtStartingPoint:(EmuPoint)p triggerDirection:(ERDirection)triggerDirection
{
    if( self = [super initAtStartingPoint:p] )
    {
        m_triggerDir = triggerDirection;
        m_lifeState = ActorLifeState_BeingBorn;  // this actor doesn't use the typical life cycle.
        m_lifeStateTimer = 0.f;
        m_currentState = TinyBtn1State_Resting;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


// override
-(EmuPoint)getMotiveAccel
{
    // this is needed to make trigger block able to move. It should match the direction of travel for trigger blocks during Trigging phase.
    // (currently this is down).
    Emu xComponent = 0, yComponent = 0;
    
    // values are positive because they represent absolute acceleration (sign is handled separately in motive updater).
    switch( m_triggerDir )
    {
        case ERDirUp:
        case ERDirDown:
            yComponent = 5000;
            break;
        case ERDirLeft:
        case ERDirRight:
            xComponent = 5000;
            break;
        default: NSAssert( NO, @"Assume valid direction" ); break;
    }
    
    return EmuPointMake( xComponent, yComponent );
}


-(SpriteState *)getTriggerBlockSpriteState
{
    NSString *triggerSpriteName;
    switch( m_triggerDir )
    {
        case ERDirUp:
            triggerSpriteName = @"tiny-event-btn1-trigger-u";
            break;
        case ERDirLeft:
            triggerSpriteName = @"tiny-event-btn1-trigger-l";
            break;
        case ERDirRight:
            triggerSpriteName = @"tiny-event-btn1-trigger-r";
            break;
        case ERDirDown:
            triggerSpriteName = @"tiny-event-btn1-trigger-d";
            break;
        default:
            NSAssert( NO, @"Assume we have a valid direction." );
            return nil;
    }
    return [[[StaticSpriteState alloc] initWithSpriteName:triggerSpriteName] autorelease];
}


-(void)spawnActorBlocks
{
    // trigger is always same size regardless of direction
    EmuSize triggerSize = EmuSizeMake( 2 * ONE_BLOCK_SIZE_Emu, 2 * ONE_BLOCK_SIZE_Emu );
    
    // these values vary by direction.
    EmuPoint anchorPoint, stopperPoint, triggerPoint, platePoint;
    EmuSize plateSize;  // shared by stopper and anchor
    EmuPoint triggerVIntrinsic;
    BlockEdgeDirMask opposingDirMask;
    NSString *plateSpriteName;
    
    switch( m_triggerDir )
    {
        case ERDirUp:
            anchorPoint = EmuPointMake( m_startingPoint.x, m_startingPoint.y + (-3 * ONE_BLOCK_SIZE_Emu) );
            stopperPoint = EmuPointMake( m_startingPoint.x, m_startingPoint.y + (-1 * ONE_BLOCK_SIZE_Emu) );
            triggerPoint = EmuPointMake( m_startingPoint.x + (1 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y + (0 * ONE_BLOCK_SIZE_Emu) );
            platePoint = EmuPointMake( m_startingPoint.x, m_startingPoint.y );
            plateSize = EmuSizeMake( 4 * ONE_BLOCK_SIZE_Emu, 1 * ONE_BLOCK_SIZE_Emu );
            triggerVIntrinsic = EmuPointMake( 0, -10000 );
            opposingDirMask = BlockEdgeDirMask_Down;
            plateSpriteName = @"tiny-event-btn1-plate-ud";
            break;
        case ERDirLeft:
            anchorPoint = EmuPointMake( m_startingPoint.x + (6 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y );
            stopperPoint = EmuPointMake( m_startingPoint.x + (4 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y );
            triggerPoint = EmuPointMake( m_startingPoint.x + (2 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y + (1 * ONE_BLOCK_SIZE_Emu) );
            platePoint = EmuPointMake( m_startingPoint.x + (3 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y );
            plateSize = EmuSizeMake( 1 * ONE_BLOCK_SIZE_Emu, 4 * ONE_BLOCK_SIZE_Emu );
            triggerVIntrinsic = EmuPointMake( 10000, 0 );
            opposingDirMask = BlockEdgeDirMask_Right;
            plateSpriteName = @"tiny-event-btn1-plate-lr";
            break;
        case ERDirRight:
            anchorPoint = EmuPointMake( m_startingPoint.x + (-3 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y );
            stopperPoint = EmuPointMake( m_startingPoint.x + (-1 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y );
            triggerPoint = EmuPointMake( m_startingPoint.x + (0 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y + (1 * ONE_BLOCK_SIZE_Emu) );
            platePoint = EmuPointMake( m_startingPoint.x, m_startingPoint.y );
            plateSize = EmuSizeMake( 1 * ONE_BLOCK_SIZE_Emu, 4 * ONE_BLOCK_SIZE_Emu );
            triggerVIntrinsic = EmuPointMake( -10000, 0 );
            opposingDirMask = BlockEdgeDirMask_Left;
            plateSpriteName = @"tiny-event-btn1-plate-lr";
            break;
        case ERDirDown:
            anchorPoint = EmuPointMake( m_startingPoint.x, m_startingPoint.y + (6 * ONE_BLOCK_SIZE_Emu) );
            stopperPoint = EmuPointMake( m_startingPoint.x, m_startingPoint.y + (4 * ONE_BLOCK_SIZE_Emu) );
            triggerPoint = EmuPointMake( m_startingPoint.x + (1 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y + (2 * ONE_BLOCK_SIZE_Emu) );
            platePoint = EmuPointMake( m_startingPoint.x, m_startingPoint.y + (3 * ONE_BLOCK_SIZE_Emu) );
            plateSize = EmuSizeMake( 4 * ONE_BLOCK_SIZE_Emu, 1 * ONE_BLOCK_SIZE_Emu );
            triggerVIntrinsic = EmuPointMake( 0, 10000 );
            opposingDirMask = BlockEdgeDirMask_Up;
            plateSpriteName = @"tiny-event-btn1-plate-ud";
            break;
        default:
            NSAssert( NO, @"Assume we have a valid direction." );
            return;
    }
    
    m_anchorBlock = [[ActorBlock alloc] initAtPoint:anchorPoint];
    m_anchorBlock.state.d = plateSize;
    m_anchorBlock.owningActor = self;
    m_anchorBlock.props.solidMask = BlockEdgeDirMask_None;
    m_anchorBlock.props.eventSolidMask = BlockEdgeDirMask_Full;
    m_anchorBlock.defaultSpriteState = nil;  // bottom block doesn't have a visual representation.
    [m_actorBlockList addObject:m_anchorBlock];
    [m_world.elbowRoom addBlock:m_anchorBlock];

    m_stopperBlock = [[ActorBlock alloc] initAtPoint:stopperPoint];
    m_stopperBlock.state.d = plateSize;
    m_stopperBlock.owningActor = self;
    m_stopperBlock.props.canMoveFreely = YES;
    m_stopperBlock.props.weight = BUTTON_STOPPER_WEIGHT;
    m_stopperBlock.props.bounceFactor = 1.f;  // don't switch directions on bounce.
    m_stopperBlock.props.solidMask = BlockEdgeDirMask_None;
    m_stopperBlock.props.eventSolidMask = BlockEdgeDirMask_Full;
    m_stopperBlock.defaultSpriteState = nil;  // stopper block doesn't have a visual representation.
    [m_actorBlockList addObject:m_stopperBlock];
    [m_world.elbowRoom addBlock:m_stopperBlock];
    
    m_triggerBlock = [[ActorBlock alloc] initAtPoint:triggerPoint];
    m_triggerBlock.state.d = triggerSize;
    m_triggerBlock.owningActor = self;
    m_triggerBlock.props.canMoveFreely = YES;
    m_triggerBlock.props.weight = BUTTON_TRIGGER_WEIGHT;
    m_triggerBlock.props.bounceFactor = 1.f;  // don't switch directions on bounce.
    m_triggerBlock.state.vIntrinsic = triggerVIntrinsic;
    m_triggerBlock.props.solidMask = BlockEdgeDirMask_Full ^ opposingDirMask;
    m_triggerBlock.props.eventSolidMask = opposingDirMask;
    m_triggerBlock.defaultSpriteState = [self getTriggerBlockSpriteState];
    [m_actorBlockList addObject:m_triggerBlock];
    [m_world.elbowRoom addBlock:m_triggerBlock];

    m_plateBlock = [[ActorBlock alloc] initAtPoint:platePoint];
    m_plateBlock.state.d = plateSize;
    m_plateBlock.owningActor = self;
    m_plateBlock.props.eventSolidMask = opposingDirMask;
    m_plateBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:plateSpriteName] autorelease];
    [m_actorBlockList addObject:m_plateBlock];
    [m_world.elbowRoom addBlock:m_plateBlock];
}


// override
-(void)onBorn
{
    [self spawnActorBlocks];
    m_lifeState = ActorLifeState_Alive;  // actor remains alive indefinitely.
}


// override
-(void)updateControlStateWithTimeDelta:(float)delta
{
    [super updateControlStateWithTimeDelta:delta];
    
    if( m_currentState == TinyBtn1State_Resting || m_currentState == TinyBtn1State_Trigging || m_currentState == TinyBtn1State_Resetting )
    {
        return;
    }
    NSAssert( m_currentState == TinyBtn1State_Triggered, @"Assume we must be in triggered state since we already checked the others." );
    
    NSArray *abutters = [m_world.frameCache lazyGetAbuttListForSO:m_triggerBlock inER:m_world.elbowRoom direction:m_triggerDir];
    if( [abutters count] == 0 )
    {
        [self onUntriggered];
        m_currentState = TinyBtn1State_Resetting;
        [self updateForCurrentState];
    }
}


-(void)updateForCurrentState
{
    const Emu stopperVBase = 1600;
    Emu stopperVX, stopperVY;
    
    switch( m_triggerDir )
    {
        case ERDirUp:
            stopperVX = 0;
            stopperVY = -stopperVBase;
            break;
        case ERDirLeft:
            stopperVX = stopperVBase;
            stopperVY = 0;
            break;
        case ERDirRight:
            stopperVX = -stopperVBase;
            stopperVY = 0;
            break;
        case ERDirDown:
            stopperVX = 0;
            stopperVY = stopperVBase;
            break;
        default:
            NSAssert( NO, @"Assume we have a valid direction." );
            return;
    }
    
    if( m_currentState == TinyBtn1State_Triggered )
    {
        return;
    }
    else if( m_currentState == TinyBtn1State_Trigging )
    {
        [m_stopperBlock setV:EmuPointMake( stopperVX, stopperVY )];
    }
    else if( m_currentState == TinyBtn1State_Resetting )
    {
        [m_stopperBlock setV:EmuPointMake( -stopperVX, -stopperVY )];  // assuming that one of these is zero, so negating both is fine.
    }
    else if( m_currentState == TinyBtn1State_Resting )
    {
        [m_stopperBlock setV:EmuPointMake( 0, 0 )];
    }
    else
    {
        NSAssert( NO, @"What state is this?" );
    }
}


-(void)onTriggered
{
    // TODO: plug in gigantic event system here.
}


-(void)onUntriggered
{
    // TODO: event system
}


// override
-(void)collidedInto:(NSObject<ISolidObject> *)other inDir:(ERDirection)dir actorBlock:(ActorBlock *)origActorBlock props:(BlockProps *)props
{
    [super collidedInto:other inDir:dir actorBlock:origActorBlock props:props];
    if( m_currentState == TinyBtn1State_Triggered )
    {
        // don't care about collisions if we are in triggered stated.
        return;
    }
    
    ERDirection oppositeDirection;
    switch( m_triggerDir )
    {
        case ERDirUp:
            oppositeDirection = ERDirDown;
            break;
        case ERDirLeft:
            oppositeDirection = ERDirRight;
            break;
        case ERDirRight:
            oppositeDirection = ERDirLeft;
            break;
        case ERDirDown:
            oppositeDirection = ERDirUp;
            break;
        default:
            NSAssert( NO, @"Assume we have a valid direction." );
            return;
    }
    
    if( m_currentState == TinyBtn1State_Resting )
    {
        if( dir != m_triggerDir || origActorBlock != m_triggerBlock )
        {
            return;
        }
        m_currentState = TinyBtn1State_Trigging;
    }
    else if( m_currentState == TinyBtn1State_Trigging )
    {
        if( dir != m_triggerDir || origActorBlock != m_anchorBlock || other != m_stopperBlock )
        {
            return;
        }
        [self onTriggered];
        m_currentState = TinyBtn1State_Triggered;
    }
    else if( m_currentState == TinyBtn1State_Resetting )
    {
        if( dir != oppositeDirection || origActorBlock != m_plateBlock || other != m_stopperBlock )
        {
            return;
        }
        m_currentState = TinyBtn1State_Resting;
    }

    // handle the details of this actor's behavior.
    [self updateForCurrentState];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TinyRedBluBtnActor
@implementation TinyRedBluBtnActor

-(id)initAtStartingPoint:(EmuPoint)p triggerDirection:(ERDirection)triggerDirection redBluStateProvider:(NSObject<IRedBluStateProvider> *)redBluStateProvider
{
    if( self = [super initAtStartingPoint:p triggerDirection:triggerDirection] )
    {
        m_redBluStateProvider = redBluStateProvider;  // weak
    }
    return self;
}


-(void)dealloc
{
    m_redBluStateProvider = nil;  // weak
    [super dealloc];
}


// override
-(SpriteState *)getTriggerBlockSpriteState
{
    NSString *triggerDefName;
    switch( m_triggerDir )
    {
        case ERDirUp:
            triggerDefName = @"tiny-redblu-trigger-u";
            break;
        case ERDirLeft:
            triggerDefName = @"tiny-redblu-trigger-l";
            break;
        case ERDirRight:
            triggerDefName = @"tiny-redblu-trigger-r";
            break;
        case ERDirDown:
            triggerDefName = @"tiny-redblu-trigger-d";
            break;
        default:
            NSAssert( NO, @"Assume we have a valid direction." );
            return nil;
    }
    ToggleDef *toggleDef = [[SpriteManager instance] getToggleDef:triggerDefName];
    NSAssert( toggleDef != nil, @"Assume we have valid toggleDef names." );

    return [[[RedBluSpriteState alloc] initWithToggleDef:toggleDef asRed:NO stateProvider:m_redBluStateProvider] autorelease];
}


// override
-(void)onTriggered
{
    [m_redBluStateProvider toggleState];
}

@end
