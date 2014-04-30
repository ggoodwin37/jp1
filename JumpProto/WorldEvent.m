//
//  WorldEvent.m
//  JumpProto
//
//  Created by Gideon Goodwin on 4/28/14.
//
//

#import "WorldEvent.h"
#import "gutil.h"

// WorldEvent ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation WorldEvent

@synthesize targetId, type, timestamp = m_timestamp;

-(id)initWithTargetId:(NSString *)targetIdIn type:(WorldEventType)typeIn
{
    if( self = [super init] )
    {
        self.targetId = targetIdIn;
        self.type = typeIn;
        m_timestamp = getUpTimeMs();
    }
    return self;
}


-(void)dealloc
{
    self.targetId = nil;
    [super dealloc];
}


@end


// WorldEventFX //////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation WorldEventFX

@synthesize targetId, type, params;

-(id)initWithTargetId:(NSString *)targetIdIn fxType:(WorldEventFXType)fxTypeIn params:(NSDictionary *)paramsIn
{
    if( self = [super init] )
    {
        self.targetId = targetIdIn;
        self.type = fxTypeIn;
        self.params = paramsIn;
    }
    return self;
}


-(void)dealloc
{
    self.params = nil;
    [super dealloc];
}

@end


// WorldEventDispatcher /////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation WorldEventDispatcher

-(id)init
{
    if( self = [super init] )
    {
        m_worldEventListeners = [[NSMutableDictionary alloc] initWithCapacity:64];
    }
    return self;
}


-(void)dealloc
{
    [m_worldEventListeners release]; m_worldEventListeners = nil;
    [super dealloc];
}


-(void)registerListener:(NSObject<WorldEventHandler> *)listener forTargetId:(NSString *)targetId
{
    NSMutableArray *thisList = [m_worldEventListeners objectForKey:targetId];
    if( thisList == nil )
    {
        thisList = [[[NSMutableArray alloc] initWithCapacity:8] autorelease];
        [m_worldEventListeners setObject:thisList forKey:targetId];
    }
    [thisList addObject:listener];
}


// WorldEventHandler
-(void)onWorldEvent:(WorldEvent *)event
{
    NSArray *thisList = [m_worldEventListeners objectForKey:event.targetId];
    if( thisList == nil )
    {
        // nobody gives a shit.
        return;
    }
    for( int i = 0; i < [thisList count]; ++i )
    {
        NSObject<WorldEventHandler> *thisHandler = (NSObject<WorldEventHandler> *)[thisList objectAtIndex:i];
        [thisHandler onWorldEvent:event];
    }
}

@end
