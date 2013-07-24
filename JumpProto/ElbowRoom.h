//
//  ElbowRoom.h
//  JumpProto
//
//  Created by gideong on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ERDirection.h"
#import "Block.h"

#define ERMaxDistance   (0x00ffffff)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////// EREdge
// core edge cache element.

@interface EREdge : NSObject
{
    
}

@property (nonatomic, assign) Emu majorVal;
@property (nonatomic, assign) Emu minorLowVal;
@property (nonatomic, assign) Emu minorHighVal;
@property (nonatomic, assign) Block *block;  // weak
@property (nonatomic, assign) ERDirection dir;  // used for optimized one-axis-move case.

@property (nonatomic, assign) int cacheIndex;
@property (nonatomic, assign) id containingCache; // weak


-(BOOL)equals:(EREdge *)other;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////// ERSortedEdgeCache
// the core sorted edge cache.

@interface ERSortedEdgeCache : NSObject
{
    NSMutableArray *m_sortedCache;
    
    // see discussion of sorting selectors here:
    // http://stackoverflow.com/questions/805547/how-to-sort-an-nsmutablearray-with-custom-objects-in-it
    
    // optimization: we need lots of short-lived buffers, so just store one locally and reuse it.
    NSMutableArray *m_workingEdgeList;
}

-(void)addEdge:(EREdge *)edge;
-(void)removeEdge:(EREdge *)edge;
-(void)moveEdge:(EREdge *)edge toMajorVal:(Emu)majorVal;
-(NSArray *)collidingEdgeListForEdge:(EREdge *)edge positiveDirection:(BOOL)fPos sortHint:(int *)sortHint;

@end



////////////////////////////////////////////////////////////////////////////////////////////////////////////////// ERCacheStrip
// this class wraps the core sorted cache with space range info and hash. the deterministic hash key allows us
//  to refer to unique instances per space range (which can be created on demand).
// this represents one axis direction. so the owner will need 4 copies, positive x, etc.

@interface ERCacheStrip : NSObject
{
    ERSortedEdgeCache *m_edgeCache;
    
}

// this tuple uniquely identifies one instance of this class.
@property (nonatomic, readonly) Emu stripMinVal;  // define the strip parallel to major axis that we own.
@property (nonatomic, readonly) Emu stripMaxVal;
@property (nonatomic, readonly) ERDirection dir;    // this cache contains only edges facing this direction


-(id)initWithMinVal:(Emu)minVal maxVal:(Emu)maxVal dir:(ERDirection)dir;

-(EREdge *)addEdgeForBlock:(Block *)block;  

// if self.dir=Left, this method checks for block.rightEdge collision with edges.
// out param is for retrieving the list of things we ran into (usually this
//  list will have length 1, but it's interesting if we can accurately hit
//  multiple things at once).
-(Emu)cacheStripGetElbowRoomForBlock:(Block *)block outEdgeList:(NSArray **)outEdgeList;


// hashcode for this tuple
+(NSNumber *)getHashCodeForMinVal:(Emu)minVal maxVal:(Emu)maxVal dir:(ERDirection)dir;

@end



////////////////////////////////////////////////////////////////////////////////////////////////////////////////// ERSOInfo

@interface ERSOInfo : NSObject
{
}
@property (nonatomic, readonly) NSMutableArray *edgeList;     // the edges that were added for this SO.

// TODO: move this to WorldFrameState
//@property (nonatomic, retain) NSMutableArray *downEdgeList; // the last known list of edges directly below this SO.

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////// ElbowRoom

@interface ElbowRoom : NSObject
{
    NSMutableDictionary *m_stripTable;
    
    Emu m_stripSize;

    // map of Block* -> ERBlockInfo*, which caches data about blocks used for more efficient ER stuff.
    NSMutableDictionary *m_blockInfoCache;
    
    // optimization: avoid constantly initializing this temporary array
    NSMutableArray *m_resultCollidingEdgeList;    
    
}

@property (nonatomic, getter = getStripSize, setter = setStripSize:) Emu stripSize;

-(void)addBlock:(Block *)block;
-(void)removeBlock:(Block *)block;
-(void)singleAxisMoveBlock:(Block *)block withOffset:(EmuPoint)offset;

-(Emu)getElbowRoomForSO:(ASolidObject *)solidObject inDirection:(ERDirection)dir;
-(Emu)getElbowRoomForSO:(ASolidObject *)solidObject inDirection:(ERDirection)dir outCollidingEdgeList:(NSArray **)outCollidingEdgeList;
-(void)reset;

// TODO: move this to WorldFrameState
//-(void)setDownEdgeList:(NSMutableArray *)edgeList forSO:(ASolidObject *)solidObject;
//-(NSArray *)getDownEdgeListForSO:(ASolidObject *)solidObject;

+(NSString *)getStringForDir:(ERDirection)dir;

-(int)test_getCacheStripCount;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////// ERStats

#define ERSTATS_REPORT_INTERVAL_S  (2.f)

//#define LOG_ER_STATS

@interface ERStats : NSObject
{
    int count_edgeCompare;
    int count_edgeEquality;
    int count_addEdge;
    int count_removeEdge;
    int count_moveEdge;
    int count_getEdgeList;
    int count_getERNoList;
    int count_getERList;
    int count_deduplicate;

    long m_timer_addEdge;
    long m_timer_moveEdge;
    long m_timer_getEdgeList;
    long m_timer_getERNoList;
    long m_timer_getERList;
    long m_timer_deduplicate;
    
    int time_addEdge;
    int time_moveEdge;
    int time_getEdgeList;
    int time_getERNoList;
    int time_getERList;
    int time_deduplicate;
    
    float m_timeRemainingBeforeReport;
}

+(void)initStaticInstance;
+(void)releaseStaticInstance;
+(ERStats *)instance;

-(void)reset;
-(void)updateWithTimeDelta:(float)delta;

-(void)inc_edgeCompare;
-(void)inc_edgeEquality;
-(void)inc_addEdge;
-(void)startTimer_addEdge;
-(void)stopTimer_addEdge;
-(void)inc_removeEdge;
-(void)inc_moveEdge;
-(void)startTimer_moveEdge;
-(void)stopTimer_moveEdge;
-(void)inc_getEdgeList;
-(void)startTimer_getEdgeList;
-(void)stopTimer_getEdgeList;
-(void)inc_getERNoList;
-(void)inc_getERList;
-(void)startTimer_getERNoList;
-(void)stopTimer_getERNoList;
-(void)startTimer_getERList;
-(void)stopTimer_getERList;
-(void)inc_deduplicate;
-(void)startTimer_deduplicate;
-(void)stopTimer_deduplicate;

@end



