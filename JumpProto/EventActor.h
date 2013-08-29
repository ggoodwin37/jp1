//
//  EventActor.h
//  JumpProto
//
//  Created by Gideon iOS on 8/28/13.
//
//

#import <Foundation/Foundation.h>
#import "Actor.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// TinyBtn1Actor

// TODO: consider adding another state, trigging, so that the sliding down of the trigger block happens first,
//       then we fire the event only once the stopper has touched the bottom block.
enum TinyBtn1StateEnum
{
    TinyBtn1State_Resting,
    TinyBtn1State_Triggered,
    TinyBtn1State_Resetting,
};
typedef enum TinyBtn1StateEnum TinyBtn1State;

@interface TinyBtn1Actor : Actor {
    TinyBtn1State m_currentState;
    float m_timeRemainingInCurrentState;
    
    ActorBlock *m_bottomBlock;
    ActorBlock *m_stopperBlock;
    ActorBlock *m_triggerBlock;
    ActorBlock *m_plateBlock;
}

@end
