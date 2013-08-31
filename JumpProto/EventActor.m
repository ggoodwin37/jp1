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
    // each button owns four blocks: the bottom, the stopper, the trigger, and the plate.
    // some values have an offset of 1 so that the trigger block doesn't get fouled up on the level block beneath the button.
    
    EmuPoint bottomPoint = EmuPointMake( m_startingPoint.x + (3 * ONE_BLOCK_SIZE_Emu / 2), m_startingPoint.y - (3 * ONE_BLOCK_SIZE_Emu) );
    m_bottomBlock = [[ActorBlock alloc] initAtPoint:bottomPoint];
    m_bottomBlock.state.d = EmuSizeMake( 1 * ONE_BLOCK_SIZE_Emu, 1 * ONE_BLOCK_SIZE_Emu );
    m_bottomBlock.owningActor = self;
    m_bottomBlock.props.solidMask = BlockEdgeDirMask_Up;
    //m_bottomBlock.defaultSpriteState = nil;  // bottom block doesn't have a visual representation.
    m_bottomBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"tiny-btn1-plate"] autorelease];  // TEST
    [m_actorBlockList addObject:m_bottomBlock];
    [m_world.elbowRoom addBlock:m_bottomBlock];

    EmuPoint stopperPoint = EmuPointMake( m_startingPoint.x + ONE_BLOCK_SIZE_Emu, m_startingPoint.y - ONE_BLOCK_SIZE_Emu );
    m_stopperBlock = [[ActorBlock alloc] initAtPoint:stopperPoint];
    m_stopperBlock.state.d = EmuSizeMake( 2 * ONE_BLOCK_SIZE_Emu, 1 * ONE_BLOCK_SIZE_Emu - 1 );
    m_stopperBlock.owningActor = self;
    m_stopperBlock.props.canMoveFreely = YES;
    m_stopperBlock.props.immovable = YES;
    m_stopperBlock.props.initialVelocity = EmuPointMake( 0, 0 );
    m_stopperBlock.props.solidMask = BlockEdgeDirMask_Up | BlockEdgeDirMask_Down;
    //m_stopperBlock.defaultSpriteState = nil;  // stopper block doesn't have a visual representation.
    m_stopperBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"tiny-btn1-plate"] autorelease];  // TEST
    [m_actorBlockList addObject:m_stopperBlock];
    [m_world.elbowRoom addBlock:m_stopperBlock];
    
    EmuPoint triggerPoint = EmuPointMake( m_startingPoint.x + (3 * ONE_BLOCK_SIZE_Emu / 2), m_startingPoint.y - 1 );
    m_triggerBlock = [[ActorBlock alloc] initAtPoint:triggerPoint];
    m_triggerBlock.state.d = EmuSizeMake( 1 * ONE_BLOCK_SIZE_Emu, 2 * ONE_BLOCK_SIZE_Emu + 1 );
    m_triggerBlock.owningActor = self;
    m_triggerBlock.props.canMoveFreely = YES;
    m_triggerBlock.props.immovable = YES;
    m_triggerBlock.props.bounceFactor = 1.f;  // don't switch directions on bounce.
    m_triggerBlock.state.vIntrinsic = EmuPointMake( 0, -10000 );
    m_triggerBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"tiny-btn1-trigger"] autorelease];
    [m_actorBlockList addObject:m_triggerBlock];
    [m_world.elbowRoom addBlock:m_triggerBlock];

    EmuPoint platePoint = EmuPointMake( m_startingPoint.x + (1 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y - 1 );
    m_plateBlock = [[ActorBlock alloc] initAtPoint:platePoint];
    m_plateBlock.state.d = EmuSizeMake( 2 * ONE_BLOCK_SIZE_Emu, 1 * ONE_BLOCK_SIZE_Emu + 1 );
    m_plateBlock.owningActor = self;
    m_plateBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"tiny-btn1-plate"] autorelease];
    [m_actorBlockList addObject:m_plateBlock];
    [m_world.elbowRoom addBlock:m_plateBlock];
}


// override
-(void)onBorn
{
    [self spawnActorBlocks];
    m_lifeState = ActorLifeState_Alive;  // actor remains alive indefinitely, even when the actorBlock is temporarily gone.
}


// override
-(void)updateControlStateWithTimeDelta:(float)delta
{
    [super updateControlStateWithTimeDelta:delta];
    
    if( m_currentState == TinyBtn1State_Resting || m_currentState == TinyBtn1State_Trigging )
    {
        return;
    }

    if( m_currentState == TinyBtn1State_Triggered )
    {
        // TODO: check if trigger block has any up abutters still, and if not, go to resetting state.
        return;
    }
    
    NSAssert( m_currentState == TinyBtn1State_Resetting, @"Assume we must be in resetting state since we already checked the others." );

    // TODO (if we don't need any special handling for resetting, move the resetting state check to the no-op at top)
}


-(void)updateForCurrentState
{
    if( m_currentState == TinyBtn1State_Resting )
    {
        return;
    }
    if( m_currentState == TinyBtn1State_Trigging )
    {
        // set stopper block to down velocity.
        const Emu stopperDown = -1600;
        [m_stopperBlock setV:EmuPointMake( 0, stopperDown )];
        return;
    }
    if( m_currentState == TinyBtn1State_Triggered )
    {
        // TODO
    }
    if( m_currentState == TinyBtn1State_Resetting )
    {
        // TODO
    }
}

-(void)onTriggered
{
    NSLog( @"A button was triggered!" );
    // TODO: plug in gigantic event system here.
}


// override
-(void)collidedInto:(NSObject<ISolidObject> *)other inDir:(ERDirection)dir actorBlock:(ActorBlock *)origActorBlock
{
    [super collidedInto:other inDir:dir actorBlock:origActorBlock];
    if( m_currentState != TinyBtn1State_Resting && m_currentState != TinyBtn1State_Trigging )
    {
        // only care about collisions if we are resting or trigging.
        return;
    }
    if( dir != ERDirUp )
    {
        // only care about up collisions (things landing on us).
        // TODO: this assumes an up-facing button.
        return;
    }
    
    if( m_currentState == TinyBtn1State_Resting )
    {
        if( origActorBlock != m_triggerBlock )
        {
            // in resting state, only listen for collisions on the trigger.
            return;
        }
        m_currentState = TinyBtn1State_Trigging;
    }
    else if( m_currentState == TinyBtn1State_Trigging )
    {
        if( origActorBlock != m_bottomBlock || other != m_stopperBlock )
        {
            // in trigging state, only listen for collisions of the stopper onto the bottom blocker.
            return;
        }
        // hook into the event system.
        [self onTriggered];
        m_currentState = TinyBtn1State_Triggered;
    }

    // handle the details of this actor's behavior.
    [self updateForCurrentState];
}

@end
