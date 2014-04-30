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
@property (nonatomic, readonly) long timestamp;  // getUpTimeMs()

@end


// WorldEventFX //////////////////////////////////////////////////////////////////////////////////////////////////////////////

// describes an effect that can be triggered by an event.
@interface WorldEventFX : NSObject

-(id)initWithTargetId:(NSString *)targetIdIn fxType:(WorldEventFXType)fxTypeIn params:(NSDictionary *)paramsIn;

@property (nonatomic, retain) NSString *targetId;  // TODO: do we need this? can we just set up the mapping from targetId to block at load?
@property (nonatomic, assign) WorldEventFXType type;
@property (nonatomic, retain) NSDictionary *params;

@end


// WorldEventHandler ////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol WorldEventHandler <NSObject>

-(void)onWorldEvent:(WorldEvent *)event;

@end


// WorldEventDispatcher /////////////////////////////////////////////////////////////////////////////////////////////////////

@interface WorldEventDispatcher : NSObject<WorldEventHandler>
{
    NSMutableDictionary *m_worldEventListeners; // a map of lists
}

-(void)registerListener:(NSObject<WorldEventHandler> *)listener forTargetId:(NSString *)targetId;

@end

