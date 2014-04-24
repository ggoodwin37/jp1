#import <QuartzCore/QuartzCore.h>
#import "JumpProtoLaunchViewPhoneController.h"

@interface JumpProtoLaunchViewPhoneController (private)

@end


@implementation JumpProtoLaunchViewPhoneController

-(id)init
{
    if( self = [super init] )
    {
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)aDecoder
{
    if( self = [super initWithCoder:aDecoder] )
    {
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


// override
-(BOOL)shouldShowCreateNewLevelOption
{
    return NO;
}

@end
