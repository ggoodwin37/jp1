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

-(id)initAtStartingPoint:(EmuPoint)p
{
    if( self = [super initAtStartingPoint:p] )
    {
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
    return EmuPointMake( 0, 5000 );   // this is positive because this represents absolute acceleration (sign is handled separately in motive updater).
}


-(void)spawnActorBlocks
{
    // some values have an offset so that the trigger block doesn't get fouled up on the level block beneath the button.
    // TODO: have a feeling I'm just off-by-a-quarter somewhere in the sublayout. smaller values don't retrig.
    const Emu foulOffset = ONE_BLOCK_SIZE_Emu / 4;

    EmuPoint bottomPoint = EmuPointMake( m_startingPoint.x + (3 * ONE_BLOCK_SIZE_Emu / 2), m_startingPoint.y - (3 * ONE_BLOCK_SIZE_Emu) );
    EmuSize bottomSize = EmuSizeMake( 1 * ONE_BLOCK_SIZE_Emu, 1 * ONE_BLOCK_SIZE_Emu );
    m_bottomBlock = [[ActorBlock alloc] initAtPoint:bottomPoint];
    m_bottomBlock.state.d = bottomSize;
    m_bottomBlock.owningActor = self;
    m_bottomBlock.props.solidMask = BlockEdgeDirMask_Up;
    m_bottomBlock.defaultSpriteState = nil;  // bottom block doesn't have a visual representation.
    //m_bottomBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"tiny-btn1-plate"] autorelease];  // TEST
    [m_actorBlockList addObject:m_bottomBlock];
    [m_world.elbowRoom addBlock:m_bottomBlock];

    EmuPoint stopperPoint = EmuPointMake( m_startingPoint.x + ONE_BLOCK_SIZE_Emu, m_startingPoint.y - ONE_BLOCK_SIZE_Emu - foulOffset );
    EmuSize stopperSize = EmuSizeMake( 2 * ONE_BLOCK_SIZE_Emu, 1 * ONE_BLOCK_SIZE_Emu );
    m_stopperBlock = [[ActorBlock alloc] initAtPoint:stopperPoint];
    m_stopperBlock.state.d = stopperSize;
    m_stopperBlock.owningActor = self;
    m_stopperBlock.props.canMoveFreely = YES;
    m_stopperBlock.props.weight = BUTTON_STOPPER_WEIGHT;
    m_stopperBlock.props.bounceFactor = 1.f;  // don't switch directions on bounce.
    m_stopperBlock.defaultSpriteState = nil;  // stopper block doesn't have a visual representation.
    //m_stopperBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"tiny-btn1-plate"] autorelease];  // TEST
    [m_actorBlockList addObject:m_stopperBlock];
    [m_world.elbowRoom addBlock:m_stopperBlock];
    
    EmuPoint triggerPoint = EmuPointMake( m_startingPoint.x + (3 * ONE_BLOCK_SIZE_Emu / 2), m_startingPoint.y - foulOffset );
    EmuSize triggerSize = EmuSizeMake( 1 * ONE_BLOCK_SIZE_Emu, 2 * ONE_BLOCK_SIZE_Emu );
    m_triggerBlock = [[ActorBlock alloc] initAtPoint:triggerPoint];
    m_triggerBlock.state.d = triggerSize;
    m_triggerBlock.owningActor = self;
    m_triggerBlock.props.canMoveFreely = YES;
    m_triggerBlock.props.weight = BUTTON_TRIGGER_WEIGHT;
    m_triggerBlock.props.bounceFactor = 1.f;  // don't switch directions on bounce.
    m_triggerBlock.state.vIntrinsic = EmuPointMake( 0, -10000 );
    m_triggerBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"tiny-btn1-trigger"] autorelease];
    [m_actorBlockList addObject:m_triggerBlock];
    [m_world.elbowRoom addBlock:m_triggerBlock];

    EmuPoint platePoint = EmuPointMake( m_startingPoint.x + (1 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y - foulOffset );
    EmuSize plateSize = EmuSizeMake( 2 * ONE_BLOCK_SIZE_Emu, 1 * ONE_BLOCK_SIZE_Emu + foulOffset );
    m_plateBlock = [[ActorBlock alloc] initAtPoint:platePoint];
    m_plateBlock.state.d = plateSize;
    m_plateBlock.owningActor = self;
    m_plateBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"tiny-btn1-plate"] autorelease];
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
    
    NSArray *abutters = [m_world.frameCache lazyGetAbuttListForSO:m_triggerBlock inER:m_world.elbowRoom direction:ERDirUp];
    if( [abutters count] == 0 )
    {
        [self onUntriggered];
        m_currentState = TinyBtn1State_Resetting;
        [self updateForCurrentState];
    }
}


-(void)updateForCurrentState
{
    const Emu stopperV = 1600;
    if( m_currentState == TinyBtn1State_Resting || m_currentState == TinyBtn1State_Triggered )
    {
        return;
    }
    else if( m_currentState == TinyBtn1State_Trigging )
    {
        [m_stopperBlock setV:EmuPointMake( 0, -stopperV )];
    }
    else if( m_currentState == TinyBtn1State_Resetting )
    {
        [m_stopperBlock setV:EmuPointMake( 0, stopperV )];
    }
    else
    {
        NSAssert( NO, @"What state is this?" );
    }
}


-(void)onTriggered
{
    NSLog( @"A button was triggered!" );
    // TODO: plug in gigantic event system here.
}


-(void)onUntriggered
{
    // TODO: event system
}


// override
-(void)collidedInto:(NSObject<ISolidObject> *)other inDir:(ERDirection)dir actorBlock:(ActorBlock *)origActorBlock
{
    [super collidedInto:other inDir:dir actorBlock:origActorBlock];
    if( m_currentState == TinyBtn1State_Triggered )
    {
        // don't care about collisions if we are in triggered stated.
        return;
    }
    
    if( m_currentState == TinyBtn1State_Resting )
    {
        if( dir != ERDirUp || origActorBlock != m_triggerBlock )
        {
            return;
        }
        m_currentState = TinyBtn1State_Trigging;
    }
    else if( m_currentState == TinyBtn1State_Trigging )
    {
        if( dir != ERDirUp || origActorBlock != m_bottomBlock || other != m_stopperBlock )
        {
            return;
        }
        [self onTriggered];
        m_currentState = TinyBtn1State_Triggered;
    }
    else if( m_currentState == TinyBtn1State_Resetting )
    {
        if( dir != ERDirDown || origActorBlock != m_plateBlock || other != m_stopperBlock )
        {
            return;
        }
        m_currentState = TinyBtn1State_Resting;
    }

    // handle the details of this actor's behavior.
    [self updateForCurrentState];
}

@end
