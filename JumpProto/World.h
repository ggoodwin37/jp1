//
//  World.h
//  JumpProto
//
//  Created by gideong on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Block.h"
#import "ElbowRoom.h"
#import "BlockUpdater.h"
#import "Actor.h"
#import "ActorUpdater.h"
#import "BlockGroup.h"
#import "WorldFrameState.h"

@interface World : NSObject<DpadEventDelegate> {
    
    NSMutableArray *m_worldSOs;
    NSMutableArray *m_frameStateBlockUpdaters;
    NSMutableArray *m_updateGraphWorkers;
    NSMutableArray *m_worldStateBlockUpdaters;
    PlayerActor *m_playerActor;
    NSMutableArray *m_npcActors;
    ElbowRoom *m_elbowRoom;
    WorldFrameCache *m_worldFrameCache;
    
    NSMutableArray *m_playerActorUpdaters;
    NSMutableArray *m_actorUpdaters;
    
    NSMutableDictionary *m_groupTable;
    
    // for calculating average update duration.
    UInt32 m_totalDur;
    UInt32 m_totalUpdates;
    float m_timeUntilNextSpeedReport;
    
    int m_burnFrames;
    
    BOOL m_loadTestWorldFromDisk;
    
    NSMutableArray *m_deadActorsThisFrame;
    NSMutableArray *m_deadSOsThisFrame;
}

@property (nonatomic, retain) NSString *levelName;
@property (nonatomic, retain) NSString *levelDescription;
@property (nonatomic, readonly) ElbowRoom *elbowRoom;
@property (nonatomic, readonly) WorldFrameCache *frameCache;

@property (nonatomic, assign) Emu yBottom;

@property (nonatomic, readonly, getter=getNpcActors) NSMutableArray *npcActors;

-(void)showTestWorld:(NSString *)preferredStartingWorld loadFromDisk:(BOOL)loadFromDisk;
-(void)resetTestWorld;
-(void)advanceTestWorld;

-(int)worldSOCount;
-(ASolidObject *)getWorldSO:(int)i;

-(PlayerActor *)getPlayerActor;

-(void)updateWithTimeDelta:(float)timeDelta;

// worldBlocks are blocks not owned by any actor or group.
-(void)addWorldBlock:(Block *)block;
-(void)removeWorldSO:(ASolidObject *)solidObject;

-(void)initPlayerAt:(EmuPoint)p;

-(BlockGroup *)ensureGroupForId:(GroupId)groupId;
-(void)addBlock:(Block *)block toGroup:(BlockGroup *)group;

-(void)addNPCActor:(Actor *)actor;

-(void)reset;

-(void)onDpadEvent:(DpadEvent *)event;

-(void)onPlayerDying;
-(void)onPlayerDied;
-(void)onPlayerWon;
-(void)onActorDied:(Actor *)actor;
-(void)onSODied:(ASolidObject *)solidObject;


// test only
// TODO: remove eventually. Are some of the methods above test only too?
-(int)test_getCacheStripCount;


@end
