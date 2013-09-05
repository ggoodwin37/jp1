//
//  Block.h
//  JumpProto
//
//  Created by gideong on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpriteState.h"
#import "ISolidObject.h"

typedef UInt32 BlockToken;


/////////////////////////////////////////////////////////////////////////////////////////////////////////// BlockEdgeDirMask

enum BlockEdgeDirMaskEnum
{
    BlockEdgeDirMask_None = 0,
    BlockEdgeDirMask_Up = 1,
    BlockEdgeDirMask_Left = 2,
    BlockEdgeDirMask_Right= 4,
    BlockEdgeDirMask_Down = 8,
    BlockEdgeDirMask_Full = BlockEdgeDirMask_Up | BlockEdgeDirMask_Left | BlockEdgeDirMask_Right | BlockEdgeDirMask_Down,
    
};

typedef enum BlockEdgeDirMaskEnum BlockEdgeDirMask;


/////////////////////////////////////////////////////////////////////////////////////////////////////////// BlockState
@interface BlockState : NSObject {
    EmuPoint m_p;
    EmuPoint m_v;
    EmuSize m_d;
}

@property (nonatomic, getter=getP, setter=setP:) EmuPoint p;
@property (nonatomic, getter=getV, setter=setV:) EmuPoint v;
@property (nonatomic, getter=getD, setter=setD:) EmuSize d;
@property (nonatomic, assign) EmuPoint vIntrinsic;

-(void)setRect:(EmuRect)rect;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// BlockRedBluStateEnum
enum BlockRedBluStateEnum
{
    BlockRedBlueState_None = 0,
    BlockRedBlueState_Red = 1,
    BlockRedBlueState_Blu = 2,
};

typedef enum BlockRedBluStateEnum BlockRedBluState;


/////////////////////////////////////////////////////////////////////////////////////////////////////////// BlockProps
@interface BlockProps : NSObject {
    NSString *m_tokenAsString;
}
@property (nonatomic, assign) BlockToken token;

@property (nonatomic, assign) BOOL canMoveFreely;
@property (nonatomic, assign) BOOL affectedByGravity;
@property (nonatomic, assign) BOOL affectedByFriction;
@property (nonatomic, assign) EmuPoint initialVelocity;  // this becomes vIntrinsic

@property (nonatomic, assign) float bounceFactor;

@property (nonatomic, assign) UInt32 solidMask;
@property (nonatomic, assign) UInt32 hurtyMask;
@property (nonatomic, assign) UInt32 eventSolidMask;
@property (nonatomic, assign) UInt32 springyMask;

@property (nonatomic, assign) BOOL isWallJumpable;
@property (nonatomic, assign) BOOL isGoalBlock;
@property (nonatomic, assign) BOOL isActorBlock;
@property (nonatomic, assign) BOOL isPlayerBlock;
@property (nonatomic, assign) BOOL isAiHint;
@property (nonatomic, assign) BOOL followsAiHints;

@property (nonatomic, assign) Emu xConveyor;

@property (nonatomic, assign) int weight;

@property (nonatomic, readonly, getter=getTokenAsString) NSString *tokenAsString;  // lazy

@property (nonatomic, assign) BlockRedBluState redBluState;

+(BlockToken)nextToken;

-(void)copyFrom:(BlockProps *)other;
-(bool)equalTo:(BlockProps *)other;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// Block
@class BlockGroup;

@interface Block : NSObject<ISolidObject> {
}

@property (nonatomic, readonly) BlockState *state;
@property (nonatomic, readonly) BlockProps *props;
@property (nonatomic, assign) GroupId groupId;

@property (nonatomic, assign) BlockGroup *owningGroup;  // weak backref to group

@property (nonatomic, assign) BlockEdgeDirMask shortCircuitER;  // optimization used by blocks in groups:
                                                              // skip ER checks in certain directions if we know another block in group is there.

// readonly shortcuts to state
// (can set these via the state member if needed)
@property (nonatomic, readonly, getter=getX) Emu x;
@property (nonatomic, readonly, getter=getY) Emu y;
@property (nonatomic, readonly, getter=getW) Emu w;
@property (nonatomic, readonly, getter=getH) Emu h;
@property (nonatomic, readonly, getter=getToken) BlockToken token;
@property (nonatomic, readonly) NSString *key;

+(BlockEdgeDirMask)getOpposingEdgeMaskForDir:(ERDirection)dir;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteStateMap
@interface SpriteStateMap : NSObject {
    CGSize m_size;
    SpriteState **m_data;
}
@property (nonatomic, readonly) CGSize size;

-(id)initWithSize:(CGSize)size;
-(SpriteState *)getSpriteStateAtX:(int)x y:(int)y;
-(void)setSpriteStateAtX:(int)x y:(int)y to:(SpriteState *)spriteState;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteBlock
@interface SpriteBlock : Block {
    
}

@property (nonatomic, retain) SpriteStateMap *spriteStateMap;
@property (nonatomic, assign, getter=getDefaultSpriteState,
                              setter=setDefaultSpriteState:) SpriteState *defaultSpriteState; // setter retains

-(id)initWithRect:(EmuRect)rect spriteStateMap:(SpriteStateMap *)spriteStateMap;

-(void)setAllSpritesTo:(SpriteState *)spriteState;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ActorBlock
@class Actor;

@interface ActorBlock : SpriteBlock {
    
}

@property (nonatomic, assign) Actor *owningActor;  // weak

-(id)initAtPoint:(EmuPoint)p;
-(id)initAtPoint:(EmuPoint)p spriteStateMap:(SpriteStateMap *)spriteStateMap;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// GibBlock
@interface GibBlock : SpriteBlock {
    
}

@end

