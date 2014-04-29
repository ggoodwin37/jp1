//
//  WorldEvent.h
//  JumpProto
//
//  Created by Gideon Goodwin on 4/28/14.
//
//

#import <Foundation/Foundation.h>

enum WorldEventTypeEnum
{
    WEPressed,
    WEDown,
    WEUp,
    WECount,
};
typedef enum WorldEventTypeEnum WorldEventType;


enum WorldEventFXTypeEnum
{
    WFXNone,
    WFXTest,
    WFXCount,
};
typedef enum WorldEventFXTypeEnum WorldEventFXType;


// WorldEvent ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface WorldEvent : NSObject

-(id)initWithTargetId:(NSString *)targetIdIn type:(WorldEventType)typeIn;

@property (nonatomic, retain) NSString *targetId;
@property (nonatomic, assign) WorldEventType type;

// TODO: current time


@end


// WorldEventFX //////////////////////////////////////////////////////////////////////////////////////////////////////////////

// describes an effect that can be triggered by an event.
@interface WorldEventFX : NSObject

-(id)initWithFXId:(WorldEventFXType)fxTypeIn params:(NSDictionary *)paramsIn;

@property (nonatomic, assign) WorldEventFXType type;
@property (nonatomic, retain) NSDictionary *params;

@end


// WorldEventHandler ////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol WorldEventHandler <NSObject>

-(void)onWorldEvent:(WorldEvent *)event;

@end

