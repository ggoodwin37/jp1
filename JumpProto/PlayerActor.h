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
}


@property (nonatomic, assign) BOOL isDirLeftPressed;
@property (nonatomic, assign) BOOL isDirRightPressed;
@property (nonatomic, assign) BOOL isGibbed;

-(void)onDpadEvent:(DpadEvent *)event;
-(void)processNextInputEvent;
-(NSString *)getStaticFrameName;

@end


