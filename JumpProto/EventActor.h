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

enum TinyBtn1StateEnum
{
    TinyBtn1State_Resting,
    TinyBtn1State_Trigging,
    TinyBtn1State_Triggered,
    TinyBtn1State_Resetting,
};
typedef enum TinyBtn1StateEnum TinyBtn1State;

@interface TinyBtn1Actor : Actor {
    ERDirection m_triggerDir;
    TinyBtn1State m_currentState;
    float m_timeRemainingInCurrentState;
    
    ActorBlock *m_anchorBlock;
    ActorBlock *m_stopperBlock;
    ActorBlock *m_triggerBlock;
    ActorBlock *m_plateBlock;

    WorldEventDispatcher *m_dispatcher;  // weak
}

-(id)initAtStartingPoint:(EmuPoint)p triggerDirection:(ERDirection)triggerDirection dispatcher:(WorldEventDispatcher *)dispatcherIn;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TinyRedBluBtnActor
@interface TinyRedBluBtnActor : TinyBtn1Actor {
    NSObject<IRedBluStateProvider> *m_redBluStateProvider;
}

-(id)initAtStartingPoint:(EmuPoint)p triggerDirection:(ERDirection)triggerDirection redBluStateProvider:(NSObject<IRedBluStateProvider> *)redBluStateProvider;

@end
