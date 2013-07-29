//
//  BadGuyActor.h
//  JumpProto
//
//  Created by Gideon iOS on 7/28/13.
//
//

#import <Foundation/Foundation.h>
#import "Actor.h"

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


