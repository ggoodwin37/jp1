//
//  ActorUpdater.h
//  JumpProto
//
//  Created by Gideon Goodwin on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Actor.h"
#import "ElbowRoom.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorUpdater

@interface ActorUpdater : NSObject {
    
}

-(void)updateActor:(Actor *)actor withTimeDelta:(float)delta;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldActorUpdater

@class World;

@interface WorldActorUpdater : ActorUpdater {
}
@property (nonatomic, assign) World *world;  // weak

-(id)initWithWorld:(World *)world;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorWalkingUpdater

// converts actor walking states to physics updates.
@interface ActorWalkingUpdater : WorldActorUpdater {
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorJumpingUpdater

// converts actor jumping state to physics updates.
@interface ActorJumpingUpdater : WorldActorUpdater {
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// PlayerInputUpdater

// converts player control states to common actor states.
@interface PlayerInputUpdater : WorldActorUpdater {
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// PlayerHeadBumpUpdater

// handles the case where player has upward velocity but no upward elbow room.
@interface PlayerHeadBumpUpdater : WorldActorUpdater {
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorLifeStateUpdater

// converts player control states to common actor states.
@interface ActorLifeStateUpdater : WorldActorUpdater {
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorAIUpdater

// gives actors a chance to run any AI and update their control state.
@interface ActorAIUpdater : WorldActorUpdater {
}

@end

