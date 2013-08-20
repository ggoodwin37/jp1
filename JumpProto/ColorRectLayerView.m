//
//  ColorRectLayerView.h
//  BASICPROJECT
//
//  Created by gideong on 8/19/2013.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "ColorRectLayerView.h"

@interface ColorRectLayerView (private)
@end

@implementation ColorRectLayerView


-(void)setupView
{
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    glOrthof( 0.f, 1.f, 0.f, 1.f, -1.f, 1.f );
    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();
    
    glDisable( GL_TEXTURE_2D );
    glEnableClientState( GL_COLOR_ARRAY );
    glEnableClientState( GL_VERTEX_ARRAY );
    
    glDisable( GL_BLEND );
}

-(void)buildScene
{//  ll lr tl tr
	static GLbyte ColorRectLayerView_colorData[] = {
		0x11, 0x11, 0x50, 0xff,
		0x20, 0x20, 0x60, 0xff,
		0x00, 0x00, 0x10, 0xff,
		0x00, 0x00, 0x08, 0xff
	};
	
	static float ColorRectLayerView_vertData[] = {
		0,0,0,
		1,0,0,
		0,1,0,
		1,1,0,
	};
    
	[self setupView];
	glVertexPointer(3, GL_FLOAT, 0, ColorRectLayerView_vertData);
	glColorPointer(4, GL_UNSIGNED_BYTE, 0, ColorRectLayerView_colorData );
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


-(void)updateWithTimeDelta:(float)timeDelta
{
}

@end
