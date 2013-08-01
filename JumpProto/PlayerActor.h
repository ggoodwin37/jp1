//
//  PlayerActor.h
//  JumpProto
//
//  Created by Gideon iOS on 7/28/13.
//
//

#import <Foundation/Foundation.h>
#import "Actor.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// PlayerActor

@interface PlayerActor : CreatureActor
{
    NSMutableArray *m_eventQueue;
    
    BOOL m_isDirLeftPressed;
    BOOL m_isDirRightPressed;
    BOOL m_isGibbed;
    BOOL m_isWallJumping;
    
    float m_postWallJumpFlip;
    
    SpriteState *m_stillSpriteState;
    SpriteState *m_runningSpriteState;
    SpriteState *m_jumpUpSpriteState;
    SpriteState *m_jumpDownSpriteState;
    SpriteState *m_wallJumpSpriteState;
}


@property (nonatomic, assign) BOOL isDirLeftPressed;
@property (nonatomic, assign) BOOL isDirRightPressed;
@property (nonatomic, assign) BOOL isGibbed;
@property (nonatomic, assign) BOOL isWallJumping;

-(void)onDpadEvent:(DpadEvent *)event;
-(void)processNextInputEvent;
-(NSString *)getStaticFrameName;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// PR2PlayerActor

@interface PR2PlayerActor : PlayerActor
{
}
@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// Rob16PlayerActor

@interface Rob16PlayerActor : PlayerActor
{
}
@end
