#import <QuartzCore/QuartzCore.h>
#import "JumpProtoLaunchViewController.h"

@interface JumpProtoLaunchViewController (private)

@end


@implementation JumpProtoLaunchViewController

@synthesize loadFromDiskSwitch;

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
    self.loadFromDiskSwitch = nil;
    [super dealloc];
}


// override
-(void)onAwake
{
    [super onAwake];
    self.loadFromDiskSwitch.on = YES;
}


// override
-(BOOL)shouldLoadFromDisk
{
    return self.loadFromDiskSwitch.on;
}

@end
