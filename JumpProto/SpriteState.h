//
//  SpriteState.h
//  JumpProto
//
//  Created by gideong on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import "SpriteManager.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteState
@interface SpriteState : NSObject {
    BOOL m_fFlipped;    
}

@property (nonatomic, getter=getIsFlipped, setter=setIsFlipped:) BOOL isFlipped;
@property (nonatomic, readonly, getter=getTexSheet) GLuint texSheet;
@property (nonatomic, readonly, getter=getTexCoords) GLfloat *texCoords;
@property (nonatomic, retain) NSString *resourceName;
@property (nonatomic, readonly, getter=getWorldSize) CGSize worldSize;

-(void)updateWithTimeDelta:(float)delta;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// StaticSpriteState
@interface StaticSpriteState : SpriteState
{
    SpriteDef *m_spriteDef;
}

-(id)initWithSpriteDef:(SpriteDef *)spriteDef;
-(id)initWithSpriteName:(NSString *)spriteName;


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AnimSpriteState
@interface AnimSpriteState : SpriteState
{
    AnimDef *m_animDef;
    int m_currentFrame;
    float m_remainingTimeForCurrentFrame;
}

@property (nonatomic, assign) float animDur;
@property (nonatomic, assign) BOOL wrap;

-(id)initWithAnimDef:(AnimDef *)animDef animDur:(float)animDur;
-(id)initWithAnimName:(NSString *)animName animDur:(float)animDur;


@end

