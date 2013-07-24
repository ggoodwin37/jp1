//
//  SpriteStateDrawUtil.h
//  JumpProto
//
//  Created by gideong on 10/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpriteState.h"

@interface SpriteStateDrawUtil : NSObject {
    
}

+(void)setupForSpriteDrawing;
+(void)drawSpriteForState:(SpriteState *)spriteState x:(float)x y:(float)y w:(float)w h:(float)h;

+(void)beginFrame;
+(void)endFrame;

+(void)cleanup;

@end
