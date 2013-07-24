//
//  DpadInput.h
//  JumpProto
//
//  Created by gideong on 7/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HitZone.h"


enum TouchZoneEnum
{
    LeftTouchZone,
    RightTouchZone,
    TouchZoneCount,
};
typedef enum TouchZoneEnum TouchZone;


enum DpadEventTypeEnum
{
    DpadPressed,
    DpadReleased,
    DpadEventCount,

};
typedef enum DpadEventTypeEnum DpadEventType;


enum DpadButtonEnum
{
    DpadNotHandled,
    DpadUnknownButton,
    DpadLeftButton,
    DpadRightButton,
    
    DpadButtonCount,
};
typedef enum DpadButtonEnum DpadButton;


// DpadEvent ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DpadEvent : NSObject {

    DpadEventType m_buttonEventType;
    DpadButton          m_button;
    NSTimeInterval      m_timeStamp;
    TouchZone m_touchZone;
}

-(id)initWithButton:(DpadButton)button eventType:(DpadEventType)eventType timeStamp:(NSTimeInterval)timeStamp touchZone:(TouchZone)touchZone;
-(NSString *)debugString;

@property (nonatomic, readonly) DpadEventType type;
@property (nonatomic, readonly) DpadButton button;
@property (nonatomic, readonly) NSTimeInterval timeStamp;
@property (nonatomic, readonly) TouchZone touchZone;

@end



// DpadTouchSorterStack ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DpadTouchSorterStack : NSObject
{
    NSMutableArray *m_stack;
    int m_maxDepth;
    
}


-(id)initWithMaxDepth:(int)maxDepth;
-(void)pushTouchAt:(CGPoint)p;
-(CGPoint)calculateMeanPoint;
-(int)count;

@end



// DpadTouchLRSorter /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DpadTouchLRSorter : NSObject
{
    CGRect m_bounds;
    DpadTouchSorterStack *m_leftStack;
    DpadTouchSorterStack *m_rightStack;
    
    float m_lowCountGuessThreshold;
    
    HitZone *m_hitZone;
    
}

-(id)initWithBounds:(CGRect)bounds;
-(DpadButton)detectButtonFromTouchPoint:(CGPoint)p eventType:(DpadEventType)eventType affectsMeanPoint:(BOOL)affectsMeanPoint;
-(CGPoint)calculateMeanPointLeft;
-(CGPoint)calculateMeanPointRight;


@end




// DpadEventDelegate ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol DpadEventDelegate <NSObject>

-(void)onDpadEvent:(DpadEvent *)event;

@end



// DpadInput ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DpadInput : NSObject {
    
    NSMutableSet           *m_eventDelegates;
    
    id  m_leftTouchLRSorter, m_rightTouchLRSorter;
    
    BOOL m_stateCache_LL, m_stateCache_LR, m_stateCache_RL, m_stateCache_RR;
}


-(void)registerEventDelegate:(id<DpadEventDelegate>)theDelegate;
-(void)handleTouch:(UITouch *)touch at:(CGPoint)p;
-(DpadTouchLRSorter *)sorterForZone:(TouchZone)touchZone;
-(void)resetEventDelegates;

@end
