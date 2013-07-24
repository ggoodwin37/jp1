//
//  TestLayerView.m
//  BASICPROJECT
//
//  Created by gideong on 7/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TestLayerView.h"
#import "AspectController.h"
#import "gutil.h"

@interface TestLayerView (private)

-(void)setupView;

@end

@implementation TestLayerView


-(void)setupView
{
	const float fieldOfViewDeg = 60.0f;
	const float zNear = 0.1f, zFar = 100.0f;
	
	AspectController *ac = [AspectController instance];
	CGRect rect = CGRectMake( 0.0f, 0.0f, ac.xPixel, ac.yPixel );

	glDisable( GL_TEXTURE_2D );

	// set up projection
	float xSize = zNear * tanf( DegToRad(fieldOfViewDeg) / 2.0 );
	float ySize = xSize / (rect.size.width / rect.size.height);
	glViewport( 0, 0, rect.size.width, rect.size.height );
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();
	glFrustumf( -xSize, xSize, -ySize, ySize, zNear, zFar );
	
	// leave it in modelview mode
	glMatrixMode( GL_MODELVIEW );
}

-(void)buildScene
{
	static GLbyte testColorData[] = { 
		0x00, 0xff, 0x00, 0xff, 
		0xff, 0x00, 0x00, 0xff, 
		0x00, 0x00, 0xff, 0xff,
		0xff, 0x00, 0xff, 0xff
	};
	
	static float testQuadVerts[] = {
		0,0,0,
		1,0,0,
		0,1,0,
		1,1,0,
	};

	// generally speaking, can't do one-time setup because other layers will have conflicting settings.
	// normally we'd call this method from the scene loop to ensure our settings were as required.
	[self setupView];
	
	// set up model transform
	glLoadIdentity();
	
	static float xModel = -0.5f;
	static float yModel = -0.5f;
	static float zModel = -3.0f;
	static float offs = -0.1f;
	glTranslatef( xModel, yModel, zModel );
	zModel += offs;
	if( zModel > -1.5f ) offs = -offs;
	if( zModel < -10.0f ) offs = -offs;
	

    // TODO: should be able to push/pop this transform instead, no?
	glTranslatef( 0.5f, 0.5f, 0.0f );  // compensate
	static float xRot = 0.0f;
	static float yRot = 0.0f;
	static float zRot = 0.0f;
//	glRotatef( xRot, 1, 0, 0 );
	glRotatef( yRot, 0, 1, 0 );
	glRotatef( zRot, 0, 0, 1 );
	xRot += 3;
	yRot += 5;
	zRot += 2;
	glTranslatef( -0.5f, -0.5f, 0.0f );  // uncompensate
	
	// draw bg quad
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glVertexPointer(3, GL_FLOAT, 0, testQuadVerts);
	glColorPointer(4, GL_UNSIGNED_BYTE, 0, testColorData );
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	
}


-(void)updateWithTimeDelta:(float)timeDelta
{
}





@end
