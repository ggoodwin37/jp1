//
//  GlobalCommand.h
//  JumpProto
//
//  Created by gideong on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HitZone.h"
#import "SpriteState.h"

#define GLOBAL_COMMAND_NOTIFICATION_RESETWORLD   (@"GCNResetWorld")
#define GLOBAL_COMMAND_NOTIFICATION_ADVANCEWORLD (@"GCNAdvanceWorld")
#define GLOBAL_COMMAND_NOTIFICATION_RESETDPAD    (@"GCNResetDpad")
#define GLOBAL_COMMAND_NOTIFICATION_EXITPLAY     (@"GCNExitPlay")


/////////////////////////////////////////////////////////////////////////////////////////////////////////// GlobalCommand

@interface GlobalCommand : NSObject
{
    
}

+(void)registerObject:(id)obj forNotification:(NSString *)nStr withSel:(SEL)selector;
+(void)unregisterObject:(id)obj;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// GlobalButton

@interface GlobalButton : NSObject {

    HitZone *m_hitZone;
    NSString *m_nStr;
}

@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) UInt32 color;
@property (nonatomic, readonly) BOOL pressed;
@property (nonatomic, retain) SpriteState *spriteState;  // TODO design: why is this on the base class? it does make the view impl easier...

-(id)initWithBounds:(CGRect)bounds notificationString:(NSString *)nStr color:(UInt32)color;
-(BOOL)handleTouch:(UITouch *)touch at:(CGPoint)p;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteGlobalButton

@interface SpriteGlobalButton : GlobalButton
{
    
}

-(id)initWithBounds:(CGRect)bounds notificationString:(NSString *)nStr color:(UInt32)color spriteDefName:(NSString *)spriteDefName;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// GlobalButtonManager

@interface GlobalButtonManager : NSObject {
    NSMutableArray *m_buttons;
}

-(int)buttonCount;
-(SpriteGlobalButton *)getButtonAtIndex:(int)i;

-(void)handleTouch:(UITouch *)touch at:(CGPoint)p;


@end
