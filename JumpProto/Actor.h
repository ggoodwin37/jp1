//
//  Actor.h
//  JumpProto
//
//  Created by Gideon Goodwin on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Block.h"
#import "ElbowRoom.h"  // just for ERDirection. TODO: this isn't specific to ER anymore, should extract it.
#import "DpadInput.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorLifeState

enum ActorLifeStateEnum
{
    ActorLifeState_None,
    ActorLifeState_NotBornYet,
    ActorLifeState_BeingBorn,
    ActorLifeState_Alive,
    ActorLifeState_Dying,
    ActorLifeState_Dead,
    ActorLifeState_Winning,
    ActorLifeState_Won,
    
    ActorLifeState_Count,
};

typedef enum ActorLifeStateEnum ActorLifeState;


/////////////////////////////////////////////////////////////////////////////////////////////////////////// Actor

@class World;

@interface Actor : NSObject
{
@public
    World *m_world;
    ActorBlock *m_actorBlock;
    ActorLifeState m_lifeState;   // lifestate of the actor, not same as state of the block
    float m_lifeStateTimer;
    EmuPoint m_startingPoint;
}

@property (nonatomic, assign) World *world;  // weak
@property (nonatomic, retain) ActorBlock *actorBlock;
@property (nonatomic, assign) ActorLifeState lifeState;
@property (nonatomic, assign) EmuPoint startingPoint;
@property (nonatomic, assign) float lifeStateTimer;

-(id)initAtStartingPoint:(EmuPoint)p;

-(void)updateLifeStateWithTimeDelta:(float)delta;

-(void)onStartBeingBorn;
-(void)onBorn;
-(void)onStartDying;
-(void)onDead;
-(void)onTouchedHurty;
-(void)onTouchedGoal;

-(void)onFellOffWorld;
-(void)updateControlStateWithTimeDelta:(float)delta;
-(void)updateForWalkingStateWithTimeDelta:(float)delta;
-(void)updateForJumpingStateWithTimeDelta:(float)delta;

-(EmuPoint)getMotive;
-(EmuPoint)getMotiveAccel;

-(void)bouncedOnXAxis:(BOOL)xAxis;
-(void)collidedInto:(NSObject<ISolidObject> *)node inDir:(ERDirection)dir;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// CreatureActor

@interface CreatureActor : Actor
{
@public
    BOOL m_walkingLeft;
    BOOL m_walkingRight;
    Emu m_walkAccel;
    Emu m_walkMaxV;
    BOOL m_wantsToJump;       // does the actor want to be jumping right now?
    BOOL m_currentlyJumping;  // is the actor actually jumping right now?
    Emu m_jumpMaxV;
    int m_numJumpsAllowed;
    float m_jumpDuration;
    int m_jumpsRemaining;
    float m_currentJumpTimeRemaining;
    BOOL m_onGroundLastFrame;
}

@property (nonatomic, assign) BOOL walkingLeft;
@property (nonatomic, assign) BOOL walkingRight;

// jump info
@property (nonatomic, assign) BOOL currentlyJumping;   
@property (nonatomic, assign) float currentJumpTimeRemaining;


-(void)onJumpEvent:(BOOL)starting;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// PlayerActor

@interface PlayerActor : CreatureActor
{
    NSMutableArray *m_eventQueue;
    
    BOOL m_isDirLeftPressed;
    BOOL m_isDirRightPressed;
    BOOL m_isGibbed;
}


@property (nonatomic, assign) BOOL isDirLeftPressed;
@property (nonatomic, assign) BOOL isDirRightPressed;
@property (nonatomic, assign) BOOL isGibbed;

-(void)onDpadEvent:(DpadEvent *)event;
-(void)processNextInputEvent;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// BadGuyActor

@interface BadGuyActor : CreatureActor
{
}

-(void)updateCurrentAnimState;
-(EmuSize)getActorBlockSize;
-(void)setPropsForActorBlock;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TestMeanieBActor

@interface TestMeanieBActor : BadGuyActor
{
    BOOL m_facingLeft;
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// FaceboneActor

enum FaceboneStateEnum
{
    FaceboneState_Chillin,
    FaceboneState_GettingReadyToJump,
    FaceboneState_Jumping,
    FaceboneState_FakeOut,
    
};
typedef enum FaceboneStateEnum FaceboneState;

@interface FaceboneActor : BadGuyActor
{
    FaceboneState m_currentState;
    float m_timeRemainingInCurrentState;
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// Crumbles1Actor

enum Crumbles1StateEnum
{
    Crumbles1State_Chillin,
    Crumbles1State_Crumbling,
    Crumbles1State_Gone,
    Crumbles1State_Reappearing,
    
};
typedef enum Crumbles1StateEnum Crumbles1State;

@interface Crumbles1Actor : Actor
{
    Crumbles1State m_currentState;
    float m_timeRemainingInCurrentState;
}

@end
