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


-(void)spawnActorBlocks
{
    // each button owns three blocks: the stopper, trigger, and plate.
    EmuPoint stopperPoint = EmuPointMake( m_startingPoint.x + ONE_BLOCK_SIZE_Emu, m_startingPoint.y - ONE_BLOCK_SIZE_Emu );
    m_stopperBlock = [[ActorBlock alloc] initAtPoint:stopperPoint];
    m_stopperBlock.state.d = EmuSizeMake( 2 * ONE_BLOCK_SIZE_Emu, 1 * ONE_BLOCK_SIZE_Emu );
    m_stopperBlock.owningActor = self;
    m_stopperBlock.props.canMoveFreely = YES;
    m_stopperBlock.props.immovable = YES;
    m_stopperBlock.props.affectedByGravity = NO;
    m_stopperBlock.props.affectedByFriction = NO;
    m_stopperBlock.props.initialVelocity = EmuPointMake( 0, 0 );
    m_stopperBlock.props.solidMask = BlockEdgeDirMask_Up;
    m_stopperBlock.defaultSpriteState = nil;  // stopper block doesn't have a visual representation.
    [m_actorBlockList addObject:m_stopperBlock];
    [m_world.elbowRoom addBlock:m_stopperBlock];
    
    EmuPoint triggerPoint = EmuPointMake( m_startingPoint.x + (3 * ONE_BLOCK_SIZE_Emu / 2), m_startingPoint.y );
    m_triggerBlock = [[ActorBlock alloc] initAtPoint:triggerPoint];
    m_triggerBlock.state.d = EmuSizeMake( 1 * ONE_BLOCK_SIZE_Emu, 2 * ONE_BLOCK_SIZE_Emu );
    m_triggerBlock.owningActor = self;
    m_triggerBlock.props.canMoveFreely = YES;
    m_triggerBlock.props.immovable = YES;
    m_triggerBlock.props.affectedByGravity = YES;
    m_triggerBlock.props.affectedByFriction = NO;
    m_triggerBlock.props.initialVelocity = EmuPointMake( 0, 0 );
    m_triggerBlock.props.solidMask = BlockEdgeDirMask_Full;
    m_triggerBlock.defaultSpriteState = [[[StaticSpriteState alloc] initWithSpriteName:@"tiny-btn1-trigger"] autorelease];
    [m_actorBlockList addObject:m_triggerBlock];
    [m_world.elbowRoom addBlock:m_triggerBlock];

    EmuPoint platePoint = EmuPointMake( m_startingPoint.x + (1 * ONE_BLOCK_SIZE_Emu), m_startingPoint.y );
    m_plateBlock = [[ActorBlock alloc] initAtPoint:platePoint];
    m_plateBlock.state.d = EmuSizeMake( 2 * ONE_BLOCK_SIZE_Emu, 1 * ONE_BLOCK_SIZE_Emu );
    m_plateBlock.owningActor = self;
    m_plateBlock.props.canMoveFreely = NO;
    m_plateBlock.props.affectedByGravity = NO;
    m_plateBlock.props.affectedByFriction = NO;
    m_plateBlock.props.solidMask = BlockEdgeDirMask_Full;
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


-(void)goNextState
{
//    switch( m_currentState )
//    {
//        case Crumbles1State_Crumbling:
//            m_currentState = Crumbles1State_Gone;
//            m_timeRemainingInCurrentState = CRUMBLES1_GONETIME;
//            [self onGone];
//            break;
//        case Crumbles1State_Gone:
//            m_currentState = Crumbles1State_Reappearing;
//            m_timeRemainingInCurrentState = CRUMBLES1_REAPPEARTIME;
//            [self onReappear];
//            break;
//        case Crumbles1State_Reappearing:
//            m_currentState = Crumbles1State_Chillin;
//            break;
//            
//        case Crumbles1State_Chillin:
//            NSAssert( NO, @"no state updates for Chillin" );
//            break;
//            
//        default:
//            NSLog( @"goNextState: unrecognized crumbles state." );
//            break;
//    }
//    [self updateCurrentAnimStateForCrumbles1];
}


// override
-(void)updateControlStateWithTimeDelta:(float)delta
{
    [super updateControlStateWithTimeDelta:delta];
    
    if( m_currentState == TinyBtn1State_Resting )
    {
        return;
    }
    
    if( m_currentState == TinyBtn1State_Triggered )
    {
        // TODO: check if trigger block has any up abutters still, and if not, go to resetting state.
        return;
    }
    
    NSAssert( m_currentState == TinyBtn1State_Resetting, @"Assume we must be in resetting state since we already checked the others." );

    // TODO
//    m_timeRemainingInCurrentState -= delta;
//    if( m_timeRemainingInCurrentState <= 0.f )
//    {
//        [self goNextState];
//    }
}


// override
-(void)collidedInto:(NSObject<ISolidObject> *)other inDir:(ERDirection)dir actorBlock:(ActorBlock *)origActorBlock
{
    [super collidedInto:other inDir:dir actorBlock:origActorBlock];
    if( m_currentState != TinyBtn1State_Resting )
    {
        // only care about collisions if we are waiting to get trig'd.
        return;
    }
    if( dir != ERDirUp )
    {
        // only care about up collisions (things landing on us).
        return;
    }
    if( origActorBlock != m_triggerBlock )
    {
        // only care about collisions on the trigger block.
        return;
    }
    NSLog( @"tiny-btn1 collidedInto triggerBlock!" );
    
    
    
//    BOOL triggered;
//#if 0
//    // since crumbles doesn't move, we only get collision events from other SOs that
//    // moved into us. so this method will be getting called from their perspective,
//    // meaning we're actually listening for the Up direction to trigger us.
//    triggered = (dir == ERDirUp);
//#else
//    // on second thought, just trigger it from any direction.
//    triggered = YES;
//#endif
//    if( triggered )
//    {
//        m_currentState = Crumbles1State_Crumbling;
//        m_timeRemainingInCurrentState = CRUMBLES1_CRUMBLETIME;
//        [self updateCurrentAnimStateForCrumbles1];
//    }
}



@end
