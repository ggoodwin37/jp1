//
//  LayerView.m
//  BASICPROJECT
//
//  Created by gideong on 7/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LayerView.h"
#import "AspectController.h"

@implementation LayerView


-(void)buildScene
{
}


-(void)updateWithTimeDelta:(float)timeDelta
{
}


-(void)setupStandardOrthoView
{
	const float zNear = -0.01;
	const float zFar = 0.01;
    
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof( 0.0f, [AspectController instance].xPixel, 0.0f, [AspectController instance].yPixel, zNear, zFar );
    
	glMatrixMode(GL_MODELVIEW);
}


-(void)drawRectAt:(CGRect)rect r:(GLbyte)r g:(GLbyte)g b:(GLbyte)b a:(GLbyte)a
{
    static GLbyte rectColors[] = { 
        0x00, 0x00, 0x00, 0x00, 
        0x00, 0x00, 0x00, 0x00, 
        0x00, 0x00, 0x00, 0x00, 
        0x00, 0x00, 0x00, 0x00, 
    };
    
    
    static GLfloat rectVerts[] = {
        0.0f,  0.0f, 0.0f, 
        0.0f,  0.0f, 0.0f, 
        0.0f,  0.0f, 0.0f, 
        0.0f,  0.0f, 0.0f, 
    };
    
    for( int setColor = 0; setColor < 4; ++setColor )
    {
        rectColors[ (setColor * 4) + 0 ] = r;
        rectColors[ (setColor * 4) + 1 ] = g;
        rectColors[ (setColor * 4) + 2 ] = b;
        rectColors[ (setColor * 4) + 3 ] = a;
    }
    
    rectVerts[  0 ] = rect.origin.x;
    rectVerts[  1 ] = rect.origin.y;
    rectVerts[  3 ] = rect.origin.x + rect.size.width;
    rectVerts[  4 ] = rect.origin.y;
    rectVerts[  6 ] = rect.origin.x;
    rectVerts[  7 ] = rect.origin.y + rect.size.height;
    rectVerts[  9 ] = rect.origin.x + rect.size.width;
    rectVerts[ 10 ] = rect.origin.y + rect.size.height;
    
    glLoadIdentity();
    glColorPointer( 4, GL_UNSIGNED_BYTE, 0, rectColors );
    glVertexPointer( 3, GL_FLOAT, 0, rectVerts );
    glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );
}





@end
