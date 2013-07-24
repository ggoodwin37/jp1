//
//  TestSpriteSheetLayerView.m
//  JumpProto
//
//  Created by Gideon Goodwin on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TestSpriteSheetLayerView.h"
#import "SpriteManager.h"

@implementation TestSpriteSheetLayerView


+(void)setupForSpriteDrawing
{
	glEnable( GL_TEXTURE_2D );
    glEnableClientState( GL_TEXTURE_COORD_ARRAY );
    glEnableClientState( GL_COLOR_ARRAY );
    glEnableClientState( GL_VERTEX_ARRAY );
    
#if 0
	// normal blend func
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
#else
	// no blending; helps debug texture/object bounds.
	glBlendFunc(GL_ONE, GL_ZERO);
#endif
	glEnable(GL_BLEND);
}


+(void)drawSpriteSheet:(SpriteSheet *)spriteSheet toRect:(CGRect)targetRect
{
    if( nil == spriteSheet )
    {
        return;
    }
    
    static GLfloat vert[] = {
        0.0f, 0.0f, 0.0f, 
        0.0f, 0.0f, 0.0f, 
        0.0f, 0.0f, 0.0f, 
        0.0f, 0.0f, 0.0f, 
    };
    
    static GLbyte color[] = { 
        0xff, 0xff, 0xff, 0xff, 
        0xff, 0xff, 0xff, 0xff, 
        0xff, 0xff, 0xff, 0xff, 
        0xff, 0xff, 0xff, 0xff, 
    };
    
    static GLfloat texCoords[] = {
      0.f, 0.f,
      1.f, 0.f,
      0.f, 1.f,
      1.f, 1.f,
    };
    
    float x1 = targetRect.origin.x;
    float y1 = targetRect.origin.y;
    float x2 = x1 + targetRect.size.width;
    float y2 = y1 + targetRect.size.height;
    
    const BOOL yFlip = YES;
    if( yFlip )
    {
        vert [0]  = x1;
        vert [1]  = y2;
        vert [3]  = x2;
        vert [4]  = y2;
        vert [6]  = x1;
        vert [7]  = y1;
        vert [9]  = x2;
        vert [10] = y1;
    }
    else
    {
        vert [0]  = x1;
        vert [1]  = y1;
        vert [3]  = x2;
        vert [4]  = y1;
        vert [6]  = x1;
        vert [7]  = y2;
        vert [9]  = x2;
        vert [10] = y2;
    }
    glVertexPointer( 3, GL_FLOAT, 0, vert );
    glColorPointer( 4, GL_UNSIGNED_BYTE, 0, color );
    
    glBindTexture( GL_TEXTURE_2D, spriteSheet.texName );
    glTexCoordPointer( 2, GL_FLOAT, 0, texCoords );
    
    // disable texture filtering, which gives us a super pixelated look.
    // This may look bad if we are scaling down, but I expect to only scale up.
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST ); 
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST ); 
    
    glLoadIdentity();
    glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );
}


// override
-(void)buildScene
{
    [TestSpriteSheetLayerView setupForSpriteDrawing];
    NSArray *testSheetArray = [SpriteManager instance].spriteSheetListForTestPurposes;
    
    SpriteSheet *thisSpriteSheet;
    CGRect targetRect;
    float xStep, yStep, xInit, yInit, xMax;

    const float padding = 32.f;
    float workingSpaceX = 1024.f - padding;
    float workingSpaceY = 768.f - padding;
    
    float workingSpace = fminf( workingSpaceX, workingSpaceY );  // pretty braindead for now, just expect 1
    float dim = workingSpace / ((float)[testSheetArray count]);
    
    xInit = (1024.f - workingSpace) / 2.f;
    xMax =  1024.f - xInit;
    yInit = (768.f - dim ) / 2.f;

    xStep = dim;
    yStep = 0;
    
    float x = xInit;
    float y = yInit;
    for( int i = 0; i < [testSheetArray count]; ++i )
    {
        thisSpriteSheet = (SpriteSheet *)[testSheetArray objectAtIndex:i];
        targetRect = CGRectMake( x, y, dim, dim );
        [TestSpriteSheetLayerView drawSpriteSheet:thisSpriteSheet toRect:targetRect];
        
        x += xStep;
        if( x >= xMax )
        {
            x = xInit;
            y += yStep;
        }
    }
}


-(void)updateWithTimeDelta:(float)timeDelta
{
}


@end
