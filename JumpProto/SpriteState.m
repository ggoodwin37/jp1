//
//  SpriteState.m
//  JumpProto
//
//  Created by gideong on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpriteState.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteState
@implementation SpriteState

@synthesize resourceName;

-(GLuint)getTexSheet
{
    NSAssert( NO, @"SpriteState base impl getTexSheet called. You should be calling an override." );
    return 0;
}


-(GLfloat *)getTexCoords
{
    NSAssert( NO, @"SpriteState base impl getTexCoords called. You should be calling an override." );
    return nil;
}


-(void)updateWithTimeDelta:(float)delta
{
    // by default, do nothing
}


-(BOOL)getIsFlipped
{
    return m_fFlipped;    
}


-(void)setIsFlipped:(BOOL)isFlipped
{
    m_fFlipped = isFlipped;
}

-(CGSize)getWorldSize
{
    NSAssert( NO, @"SpriteState base impl getWorldSize called. You should be calling an override." );
    return CGSizeMake( 0, 0 );
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// StaticSpriteState
@implementation StaticSpriteState


-(id)initWithSpriteDef:(SpriteDef *)spriteDef
{
    if( self = [super init] )
    {
        m_spriteDef = [spriteDef retain];  // consider making this weak instead?        
    }
    return self;
}


-(void)dealloc
{
    self.resourceName = nil;
    [m_spriteDef release]; m_spriteDef = nil;
    [super dealloc];
}


-(id)initWithSpriteName:(NSString *)spriteName
{
    SpriteDef *spriteDef = [[SpriteManager instance] getSpriteDef:spriteName];
    if( nil == spriteDef )
    {
        NSLog( @"StaticSpriteState initWithSpriteName: failed to get sprite called %@.", spriteName );
        return nil;
    }
    
    StaticSpriteState *spriteState = (StaticSpriteState *) [self initWithSpriteDef:spriteDef];
    spriteState.resourceName = spriteName;
    return spriteState;
}


// override
-(GLuint)getTexSheet
{
    if( nil == m_spriteDef )
    {
        NSAssert( NO, @"StaticSpriteState getTexSheet: no spriteDef set." );
        return 0;
    }
    return m_spriteDef.spriteSheet.texName;
}


// override
-(GLfloat *)getTexCoords
{
    if( nil == m_spriteDef )
    {
        NSAssert( NO, @"StaticSpriteState getTexCoords: no spriteDef set." );
        return nil;
    }
    return m_spriteDef.texCoordsCache;
}


// override
-(BOOL)getIsFlipped
{
    return [super getIsFlipped] || m_spriteDef.isFlipped;    
}


// override
-(CGSize)getWorldSize
{
    if( nil == m_spriteDef )
    {
        NSAssert( NO, @"StaticSpriteState getWorldSize: no spriteDef set." );
        return CGSizeMake( 0, 0 );
    }
    return m_spriteDef.worldSize;
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AnimSpriteState

@interface AnimSpriteState (private)

-(AnimFrameDef *)getCurrentFrame;

@end

@implementation AnimSpriteState

@synthesize animDur = m_totalDur;
@synthesize wrap;

-(id)initWithAnimDef:(AnimDef *)animDef animDur:(float)animDur
{
    if( self = [super init] )
    {
        m_animDef = [animDef retain];  // consider making this weak instead?
        m_totalDur = animDur;
        
        m_currentFrame = 0;
        m_remainingTimeForCurrentFrame = m_totalDur * [self getCurrentFrame].relativeDur;
        
        self.wrap = YES;
    }
    return self;
}


-(void)dealloc
{
    self.resourceName = nil;
    [m_animDef release]; m_animDef = nil;
    [super dealloc];
}


-(id)initWithAnimName:(NSString *)animName animDur:(float)animDur
{
    AnimDef *animDef = [[SpriteManager instance] getAnimDef:animName];
    if( nil == animDef )
    {
        NSLog( @"AnimSpriteState initWithAnimName: failed to get anim called %@.", animName );
        return nil;
    }
    
    AnimSpriteState *spriteState = (AnimSpriteState *) [self initWithAnimDef:animDef animDur:animDur];
    spriteState.resourceName = animName;
    return spriteState;
}


-(AnimFrameDef *)getCurrentFrame
{
    if( nil == m_animDef )
    {
        return nil;
    }
    return (AnimFrameDef *)[m_animDef getFrame:m_currentFrame];
}


// override
-(GLuint)getTexSheet
{
    if( nil == m_animDef )
    {
        NSAssert( NO, @"AnimSpriteState getTexSheet: no animDef set." );
        return 0;
    }

    return [self getCurrentFrame].sprite.spriteSheet.texName;
}


// override
-(GLfloat *)getTexCoords
{
    if( nil == m_animDef )
    {
        NSAssert( NO, @"AnimSpriteState getTexCoords: no animDef set." );
        return nil;
    }
    
    return [self getCurrentFrame].sprite.texCoordsCache;
}


-(void)updateWithTimeDelta:(float)delta
{
    float timeRemaining = delta;
    while( timeRemaining > 0.f )
    {
        if( m_remainingTimeForCurrentFrame > timeRemaining )
        {
            m_remainingTimeForCurrentFrame -= timeRemaining;
            timeRemaining = 0.f;
        }
        else
        {
            timeRemaining -= m_remainingTimeForCurrentFrame;
            ++m_currentFrame;
            if( m_currentFrame >= [m_animDef getNumFrames] )
            {
                if( self.wrap )
                {
                    m_currentFrame = 0;
                }
                else
                {
                    m_currentFrame = [m_animDef getNumFrames] - 1;
                }
            }
            m_remainingTimeForCurrentFrame = m_totalDur * [self getCurrentFrame].relativeDur;
        }
    }
}


// override
-(BOOL)getIsFlipped
{
    return [super getIsFlipped] || [self getCurrentFrame].sprite.isFlipped;    
}


// override
-(CGSize)getWorldSize
{
    if( nil == m_animDef )
    {
        NSAssert( NO, @"AnimSpriteState getWorldSize: no animDef set." );
        return CGSizeMake( 0, 0 );
    }
    return [self getCurrentFrame].sprite.worldSize;
}

@end


