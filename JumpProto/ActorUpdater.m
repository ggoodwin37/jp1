//
//  ActorUpdater.m
//  JumpProto
//
//  Created by Gideon Goodwin on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ActorUpdater.h"
#import "World.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorUpdater

@implementation ActorUpdater

-(void)updateActor:(Actor *)actor withTimeDelta:(float)delta
{
    
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldActorUpdater

@implementation WorldActorUpdater

@synthesize world;

-(id)initWithWorld:(World *)worldIn
{
    if( self = [super init] )
    {
        self.world = worldIn;  // weak
    }
    return self;
}


-(void)dealloc
{
    self.world = nil;
    [super dealloc];
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorWalkingUpdater

@implementation ActorWalkingUpdater

// override
-(void)updateActor:(Actor *)actor withTimeDelta:(float)delta
{
    [actor updateForWalkingStateWithTimeDelta:delta];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorJumpingUpdater

@implementation ActorJumpingUpdater

// override
-(void)updateActor:(Actor *)actor withTimeDelta:(float)delta
{
    [actor updateForJumpingStateWithTimeDelta:delta];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// PlayerInputUpdater

@implementation PlayerInputUpdater

// override
-(void)updateActor:(Actor *)actor withTimeDelta:(float)delta
{
    PlayerActor *playerActor = (PlayerActor *)actor;
    
    if( playerActor.lifeState != ActorLifeState_Alive )
    {
        // I wonder if this is how God does it...
        playerActor.walkingLeft = NO;
        playerActor.walkingRight = NO;
        playerActor.currentlyJumping = NO;
        return;
    }
    
    // events are queued to mitigate lag.
    [playerActor processNextInputEvent];

    // these are turned into velocity updates by other actorUpdaters
    playerActor.walkingLeft = playerActor.isDirLeftPressed;
    playerActor.walkingRight = playerActor.isDirRightPressed;
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// PlayerHeadBumpUpdater

@implementation PlayerHeadBumpUpdater

// override
-(void)updateActor:(Actor *)actor withTimeDelta:(float)delta
{
    // this updater just sort of leeches time off the player's jump height if they are bumping their head.
    
    PlayerActor *playerActor = (PlayerActor *)actor;
    ActorBlock *playerBlock = playerActor.actorBlock;    
    if( playerActor.currentJumpTimeRemaining > 0.f || playerBlock.state.v.y > 0 )
    {
        Emu upRoom = [self.world.elbowRoom getElbowRoomForSO:playerBlock inDirection:ERDirUp];
        if( upRoom == 0 )
        {
            // phase 1: directly dampen their upward velocity with a gravity-like calculation
            if( playerBlock.state.v.y > 0 )
            {
                EmuPoint v = playerBlock.state.v;
                const float dampenFactor = GRAVITY_CONSTANT * 3;
                Emu gravVelocityAmount = delta * dampenFactor;
                Emu newV = MAX( 0, v.y + gravVelocityAmount );
                [playerBlock setV:EmuPointMake( v.x, newV )];
            }
            
            // phase 2: reduce their remaining jump time
            const float cFactor = 1.1f;  // higher values make it harder to jump up into gaps.
            playerActor.currentJumpTimeRemaining = fmaxf( 0.f, playerActor.currentJumpTimeRemaining - (delta * cFactor) );
        }
    }
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorLifeStateUpdater

@implementation ActorLifeStateUpdater

// override
-(void)updateActor:(Actor *)actor withTimeDelta:(float)delta
{
    [actor updateLifeStateWithTimeDelta:delta];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////// ActorAIUpdater

@implementation ActorAIUpdater

// override
-(void)updateActor:(Actor *)actor withTimeDelta:(float)delta
{
    [actor updateControlStateWithTimeDelta:delta];
}

@end
