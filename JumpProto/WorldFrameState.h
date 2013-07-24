//
//  WorldFrameState.h
//  JumpProto
//
//  Created by Gideon Goodwin on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  Things that get cached each frame and used by multiple updaters.


#import <Foundation/Foundation.h>
#import "ElbowRoom.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldFrameCacheEntry

@interface WorldFrameCacheEntry : NSObject
{
    NSMutableArray *m_abuttListUp;
    NSMutableArray *m_abuttListLeft;
    NSMutableArray *m_abuttListRight;
    NSMutableArray *m_abuttListDown;
}

// used to prevent multiple movement propagation if a block rests on top of two moving blocks.
@property (nonatomic, assign) Emu gravityTallyForFrameSoFar;
@property (nonatomic, assign) ASolidObject *gravityTallyOwningSO;  // weak
@property (nonatomic, assign) BOOL newAbuttersThisFrame;

-(void)copyAbuttingBlocksFromEdgeList:(NSArray *)edgeList forDirection:(ERDirection)dir;
-(NSArray *)getAbuttListForDirection:(ERDirection)dir;
-(void)clearAbuttListForDirection:(ERDirection)dir;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldFrameCache

@interface WorldFrameCache : NSObject
{
    NSMutableDictionary *m_SOToCacheEntryMap;
}

-(WorldFrameCacheEntry *)ensureEntryForSO:(ASolidObject *)solidObject;

// TODO: need to remove SOs from map at some point?
-(void)removeEntryForSO:(ASolidObject *)solidObject;

-(void)hardReset;
-(void)resetForSO:(ASolidObject *)solidObject;

@end
