//
//  GlobalButtonView.m
//  JumpProto
//
//  Created by gideong on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GlobalButtonView.h"
#import "SpriteStateDrawUtil.h"

@implementation GlobalButtonView

@synthesize buttonManager = m_buttonManager;

-(id)init
{
    if( self = [super init] )
    {
        m_buttonManager = nil;
        
    }
    return self;
}


-(void)dealloc
{
    m_buttonManager = nil;  // weak
    [super dealloc];
}


-(void)drawSpriteButton:(SpriteGlobalButton *)button
{
    const float padding = 4.f;
    float x = button.bounds.origin.x + padding;
    float y = button.bounds.origin.y + padding;
    float w = button.bounds.size.width - (2.f * padding);
    float h = button.bounds.size.height - (2.f * padding);
    [SpriteStateDrawUtil drawSpriteForState:button.spriteState x:x y:y w:w h:h];
}


-(void)setupForColoredButton
{
    glDisable( GL_TEXTURE_2D );
    glEnableClientState( GL_COLOR_ARRAY );
    glEnableClientState( GL_VERTEX_ARRAY );
}


-(void)drawColoredButton:(GlobalButton *)button
{
    
    UInt32 r = (button.color & 0xff0000) >> 16;
    UInt32 g = (button.color & 0x00ff00) >> 8;
    UInt32 b = (button.color & 0x0000ff) >> 0;
    UInt32 a = 0xff;
    
    CGRect borderRect = CGRectMake( button.bounds.origin.x, button.bounds.origin.y, button.bounds.size.width, button.bounds.size.height );
    [self drawRectAt:borderRect r:r g:g b:b a:a];
    
    if( button.bounds.size.width > 2.f && button.bounds.size.height > 2.f )
    {
        const float fadeFactor = 0.6f;
        float ri = (float)r * fadeFactor;
        float gi = (float)g * fadeFactor;
        float bi = (float)b * fadeFactor;
        if( button.pressed )
        {
            ri = 0xff;
            gi = 0xff;
            bi = 0xff;            
        }
        CGRect innerRect = CGRectMake( button.bounds.origin.x + 1.f, button.bounds.origin.y + 1.f, button.bounds.size.width- 2.f, button.bounds.size.height - 2.f );
        [self drawRectAt:innerRect r:(GLbyte)ri g:(GLbyte)gi b:(GLbyte)bi a:a];
    }
    
}


// override
-(void)buildScene
{
    [SpriteStateDrawUtil beginFrame];
    
    if( m_buttonManager == nil )
        return;
    
    [self setupStandardOrthoView];
        
    int count = [m_buttonManager buttonCount];
    for( int i = 0; i < count; ++i )
    {
        GlobalButton *thisButton = [m_buttonManager getButtonAtIndex:i];
        
        [self setupForColoredButton];
        [self drawColoredButton:thisButton];
        
        if( thisButton.spriteState != nil )
        {
            [SpriteStateDrawUtil setupForSpriteDrawing];
            [self drawSpriteButton:(SpriteGlobalButton *)thisButton];
        }
    }
    [SpriteStateDrawUtil endFrame];
}



// override
-(void)updateWithTimeDelta:(float)timeDelta
{
}




@end
