//
//  SpriteStateDrawUtil.m
//  JumpProto
//
//  Created by gideong on 10/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpriteStateDrawUtil.h"
#import "RectCoordBuffer.h"

@implementation SpriteStateDrawUtil

static RectCoordBuffer *g_rectCoordBuffer = nil;

-(id)init
{
    NSAssert( NO, @"Don't instantiate SpriteStateDrawUtil." );
    return nil;
}

+(void)setupForSpriteDrawing
{
	glEnable( GL_TEXTURE_2D );
    glEnableClientState( GL_TEXTURE_COORD_ARRAY );
    glEnableClientState( GL_COLOR_ARRAY );
    glEnableClientState( GL_VERTEX_ARRAY );

#if 1
    // disable texture filtering, which gives us a super pixelated look.
    // This may look bad if we are scaling down, but I expect to only scale up.
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST ); 
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST ); 
#else
    // enable linear filtering. this makes each individual block look better when not at 1:1 scale,
    //  but creates "grid line" artifacts due to blending in blank padding pixels.
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
#endif
    
#if 1
	// normal blend func
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
#else
	// no blending; helps debug texture/object bounds.
	glBlendFunc(GL_ONE, GL_ZERO);
#endif
	glEnable(GL_BLEND);
}


+(void)drawSpriteForState:(SpriteState *)spriteState x:(float)x y:(float)y w:(float)w h:(float)h
{
    if( nil == spriteState )
    {
        return;
    }
    
    // it's also possible that spriteState has an influence on these, for size effects.
    float x1 = x;
    float y1 = y;
    float x2 = x + w;
    float y2 = y + h;
    if( spriteState.isFlipped )
    {
        float tmp = x2;
        x2 = x1; x1 = tmp;
    }

    [g_rectCoordBuffer pushRectGeoCoord2dX1:x1 Y1:y1 X2:x2 Y2:y2];
    [g_rectCoordBuffer pushRectTexCoord2dBuf:spriteState.texCoords];
    [g_rectCoordBuffer setTexName:spriteState.texSheet];
    [g_rectCoordBuffer incPtr];
}


+(void)beginFrame
{
    if( g_rectCoordBuffer == nil )
    {
        // TODO: tune this value down if possible
        int capacity = 30 * 20 * 2;  // guess at typical screen size (in sprites) is 30 * 20, times fudge factor.
        g_rectCoordBuffer = [[RectCoordBuffer alloc] initWithTexEnabled:YES capacity:capacity];
    }
}


+(void)endFrame
{
    [g_rectCoordBuffer flush];
}


+(void)cleanup
{
    [g_rectCoordBuffer release]; g_rectCoordBuffer = nil;
}

@end
