//
//  BlockUpdater.h
//  JumpProto
//
//  Created by gideong on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Block.h"
#import "ElbowRoom.h"
#import "WorldFrameState.h"

// order note: these updaters are intended to execute in the order listed here.

/////////////////////////////////////////////////////////////////////////////////////////////////////////// BlockUpdater

@interface BlockUpdater : NSObject {
    
}

-(void)updateSolidObject:(ASolidObject *)solidObject withTimeDelta:(float)delta;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ERBlockUpdater

@interface ERBlockUpdater : BlockUpdater {
@public
    ElbowRoom *m_elbowRoom;
}
@property (nonatomic, retain) ElbowRoom *elbowRoom;

-(id)initWithElbowRoom:(ElbowRoom *)elbowRoom;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ERFrameCacheBlockUpdater

@interface ERFrameCacheBlockUpdater : ERBlockUpdater {
@public
    WorldFrameCache *m_worldFrameCache;
}
@property (nonatomic, retain) WorldFrameCache *frameCache;

-(id)initWithElbowRoom:(ElbowRoom *)elbowRoom frameCache:(WorldFrameCache *)frameCacheIn;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldBlockUpdater

@class World;

@interface WorldBlockUpdater : BlockUpdater {
}
@property (nonatomic, assign) World *world;  // weak

-(id)initWithWorld:(World *)world;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// FrameCacheClearerUpdater

// clears out cached data each frame.
@interface FrameCacheClearerUpdater : ERFrameCacheBlockUpdater {
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AbuttListUpdater

// checks each SO and build abutt list in each direction.
@interface AbuttListUpdater : ERFrameCacheBlockUpdater {
}

// TODO: a possible optimization is to remember when we don't need to check a direction, then
//       never check that direction at all until something changes. note that the other SO may
//       have newly come into contact with us (rather than vice versa), so we can't just check
//       this when we move, have to check other guy too.
//      (this can be generalized for both abutt and non-abutt case).

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ApplyMotiveUpdater

// adjusts each SO to account for motive velocity.
// motive is intrinsic starting velocity that represents "pushing against under my own power"
// e.g. walking, strong moving platforms, etc.
@interface ApplyMotiveUpdater : ERFrameCacheBlockUpdater {
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ApplyGravityMotiveUpdater

// applies downward velocity due to gravity
@interface ApplyGravityMotiveUpdater : ERFrameCacheBlockUpdater {
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// GravFrictionUpdater

// applies horizontal friction decelaration.
@interface GravFrictionUpdater : ERFrameCacheBlockUpdater {
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// PropagateMovementUpdater

// propagates movement due to velocity along all abutting blocks.
@interface PropagateMovementUpdater : ERFrameCacheBlockUpdater {
    NSMutableArray *m_groupPropStack;  // scratch array used to prevent group propagation loops.
}
@property (nonatomic, retain) AbuttListUpdater *abuttListUpdater;


-(id)initWithElbowRoom:(ElbowRoom *)elbowRoom frameCache:(WorldFrameCache *)frameCacheIn abuttListUpdater:(AbuttListUpdater *)abuttListUpdaterIn;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// OpposingMotiveUpdater

// handles opposing motive blocks that otherwise wouldn't bounce (because they miss our static bounce detection).
@interface OpposingMotiveUpdater : ERFrameCacheBlockUpdater {
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteStateUpdater

// updates SpriteStates for Blocks.
@interface SpriteStateUpdater : BlockUpdater {
    
}
@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// BottomOfTheWorldUpdater

// handles blocks that have fallen below the bottom of the world.
@interface BottomOfTheWorldUpdater : WorldBlockUpdater {
    
}
@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////// BUStats

#define BUSTATS_REPORT_INTERVAL_S  (2.f)

//#define LOG_BU_STATS

@interface BUStats : NSObject
{
    int time_velocityUpdater;
    
    float m_timeRemainingBeforeReport;
    long m_timerStart;
}

+(void)initStaticInstance;
+(void)releaseStaticInstance;
+(BUStats *)instance;

-(void)reset;
-(void)updateWithTimeDelta:(float)delta;

-(void)startTimer;

-(void)stopTimer_velocityUpdater;

@end



