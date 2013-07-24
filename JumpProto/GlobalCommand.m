//
//  GlobalCommand.m
//  JumpProto
//
//  Created by gideong on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GlobalCommand.h"
#import "AspectController.h"
#import "DebugLogLayerView.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// GlobalCommand

@implementation GlobalCommand

+(void)registerObject:(id)obj forNotification:(NSString *)nStr withSel:(SEL)selector
{
    [[NSNotificationCenter defaultCenter] addObserver:obj selector:selector name:nStr object:nil];
}


+(void)unregisterObject:(id)obj
{
    [[NSNotificationCenter defaultCenter] removeObserver:obj];
}

@end



/////////////////////////////////////////////////////////////////////////////////////////////////////////// GlobalButton

@interface GlobalButton (private)

-(void)fireNotification;

@end


@implementation GlobalButton

@synthesize bounds = m_bounds, color = m_color, pressed = m_pressed, spriteState;

-(id)initWithBounds:(CGRect)bounds notificationString:(NSString *)nStr color:(UInt32)color
{
    if( self = [super init] )
    {
        m_bounds = bounds;
        m_nStr = nStr;
        m_color = color;
        
        m_hitZone = [[RectHitZone alloc] initWithRect:m_bounds];
    }
    return self;
}


-(void)dealloc
{
    [m_hitZone release]; m_hitZone = nil;
    [super dealloc];
}


-(BOOL)handleTouch:(UITouch *)touch at:(CGPoint)p
{
    if( ![m_hitZone containsPoint:p] )
        return NO;
    
    // TODO: may want to add toggle buttons or something
    switch( touch.phase )
    {
        case UITouchPhaseEnded:
            m_pressed = NO;
            [self fireNotification];
            return YES;
        case UITouchPhaseBegan:
            m_pressed = YES;
            // fallthrough
        case UITouchPhaseCancelled:
        case UITouchPhaseMoved:
        case UITouchPhaseStationary:
            return NO;

        default:
            NSAssert( NO, @"unknown touch phase at globalButton." );
            return NO;
    }
}


-(void)fireNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:m_nStr object:self];
}



@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteGlobalButton

@implementation SpriteGlobalButton

-(id)initWithBounds:(CGRect)bounds notificationString:(NSString *)nStr color:(UInt32)color spriteDefName:(NSString *)spriteDefName;
{
    if( self = [super initWithBounds:bounds notificationString:nStr color:color] )
    {
        self.spriteState = [[[StaticSpriteState alloc] initWithSpriteName:spriteDefName] autorelease];
    }
    return self;
}


-(void)dealloc
{
    self.spriteState = nil;
    [super dealloc];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// GlobalButtonManager

@interface GlobalButtonManager (private)

-(void)initButtons;

@end

@implementation GlobalButtonManager

-(id)init
{
    if( self = [super init] )
    {
        m_buttons = [[NSMutableArray arrayWithCapacity:10] retain];
        [self initButtons];
        
    }
    return self;
}


-(void)dealloc
{
    [m_buttons release]; m_buttons = nil;
    [super dealloc];
}


-(void)initButtons
{
    GlobalButton *button;
    float x, y, w, h;
    CGRect bounds;
    
    w = h = 40.f;
    y = 10.f;
    
    // the exit button is left-aligned
    x = 10.f;
    bounds = CGRectMake( x, y, w, h );
    button = [[SpriteGlobalButton alloc] initWithBounds:bounds notificationString:GLOBAL_COMMAND_NOTIFICATION_EXITPLAY color:0xaaaaaa spriteDefName:@"icon_close"];
    [m_buttons addObject:button];
    [button release];
    
    // the other buttons are right-aligned
    x = [AspectController instance].xPixel - 10.f - w;
    
    bounds = CGRectMake( x, y, w, h );
    button = [[SpriteGlobalButton alloc] initWithBounds:bounds notificationString:GLOBAL_COMMAND_NOTIFICATION_RESETWORLD color:0x00aaff spriteDefName:@"icon_resetLevel"];
    [m_buttons addObject:button];
    [button release];
    x -= (w + 10.f);
    
    bounds = CGRectMake( x, y, w, h );
    button = [[SpriteGlobalButton alloc] initWithBounds:bounds notificationString:GLOBAL_COMMAND_NOTIFICATION_ADVANCEWORLD color:0x0000ff spriteDefName:@"icon_nextLevel"];
    [m_buttons addObject:button];
    [button release];
    x -= (w + 10.f);
   
    
    bounds = CGRectMake( x, y, w, h );
    button = [[SpriteGlobalButton alloc] initWithBounds:bounds notificationString:GLOBAL_COMMAND_NOTIFICATION_RESETDPAD color:0xdd2288 spriteDefName:@"icon_resetDpad"];
    [m_buttons addObject:button];
    [button release];
    x -= (w + 10.f);
}


-(int)buttonCount
{
    return [m_buttons count];
}


-(SpriteGlobalButton *)getButtonAtIndex:(int)i
{
    return (SpriteGlobalButton *)[m_buttons objectAtIndex:i];    
}


-(void)handleTouch:(UITouch *)touch at:(CGPoint)p
{
    for( int i = 0; i < [self buttonCount]; ++i )
    {
        [[self getButtonAtIndex:i] handleTouch:touch at:p];
    }
}


@end

