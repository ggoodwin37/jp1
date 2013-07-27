//
//  BlockUpdater.h
//  JumpProto
//
//  Created by gideong on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Block.h"
#import "IElbowRoom.h"
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
    NSObject<IElbowRoom> *m_elbowRoom;
}
@property (nonatomic, retain) NSObject<IElbowRoom> *elbowRoom;

-(id)initWithElbowRoom:(NSObject<IElbowRoom> *)elbowRoom;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ERFrameCacheBlockUpdater

@interface ERFrameCacheBlockUpdater : ERBlockUpdater {
@public
    WorldFrameCache *m_worldFrameCache;
}
@property (nonatomic, retain) WorldFrameCache *frameCache;

-(id)initWithElbowRoom:(NSObject<IElbowRoom> *)elbowRoom frameCache:(WorldFrameCache *)frameCacheIn;

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



