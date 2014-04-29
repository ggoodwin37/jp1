//
//  WorldEvent.m
//  JumpProto
//
//  Created by Gideon Goodwin on 4/28/14.
//
//

#import "WorldEvent.h"

// WorldEvent ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation WorldEvent

@synthesize targetId, type;

-(id)initWithTargetId:(NSString *)targetIdIn type:(WorldEventType)typeIn
{
    if( self = [super init] )
    {
        self.targetId = targetIdIn;
        self.type = typeIn;
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

@synthesize type, params;

-(id)initWithFXId:(WorldEventFXType)fxTypeIn params:(NSDictionary *)paramsIn
{
    if( self = [super init] )
    {
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

