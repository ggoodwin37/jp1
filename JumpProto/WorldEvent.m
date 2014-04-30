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

