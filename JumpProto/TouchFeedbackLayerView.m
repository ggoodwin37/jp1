//
//  TouchFeedbackLayerView.m
//  JumpProto
//
//  Created by gideong on 7/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TouchFeedbackLayerView.h"
#import "AspectController.h"
#import "gutil.h"
#import "CGPointW.h"


@interface TouchFeedbackLayerView (private)

-(void)setupView;
-(void)setupRenderData;

@end

@implementation TouchFeedbackLayerView


-(id)init
{
    if( self = [super init] )
    {
        m_touchStack = [[NSMutableArray arrayWithCapacity:10] retain];
        [self setupRenderData];
    }
    return self;    
}

-(void)dealloc
{
    free( m_vertexData );
    free( m_colorData );
    [m_touchStack release]; m_touchStack = nil;
    [super dealloc];
}

-(void)setupRenderData
{
    // TODO: this should be a class
    
    m_vertexCount = 48;
    m_vertexData = (GLfloat *)malloc( m_vertexCount * 3 * sizeof( GLfloat ) );
    m_colorData = (GLbyte *)malloc( m_vertexCount * 4 * sizeof( GLbyte ) );
    
    float theta = 0.f;
    float deltaTheta = M_PI * 2 / (float)m_vertexCount;
    for( int i = 0; i < m_vertexCount; ++i )
    {
        m_vertexData[ (i * 3) + 0 ] = cosf( theta );
        m_vertexData[ (i * 3) + 1 ] = sinf( theta );
        m_vertexData[ (i * 3) + 2 ] = 0.f;
        theta += deltaTheta;
        
        m_colorData[ (i * 4) + 0 ] = 0x00;
        m_colorData[ (i * 4) + 1 ] = 0x22;
        m_colorData[ (i * 4) + 2 ] = 0xdd;
        m_colorData[ (i * 4) + 3 ] = 0xbb;
    }
    
}


-(void)setupView
{
	const float zNear = -0.01;
	const float zFar = 0.01;

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof( 0.0f, [AspectController instance].xPixel, 0.0f, [AspectController instance].yPixel, zNear, zFar );

	glMatrixMode(GL_MODELVIEW);

#if 1
	// normal blend func
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
#else
	// no blending; helps debug texture/object bounds.
	glBlendFunc(GL_ONE, GL_ZERO);
#endif
	glEnable(GL_BLEND);

}


// override
-(void)buildScene
{

    [self setupView];

    
    GLfloat xScale = 40.f,
            yScale = 40.f,
            theta = 0.f;
    

    for( int i = 0; i < [m_touchStack count]; ++i )
    {
        CGPointW *p = [m_touchStack objectAtIndex:i];

        glLoadIdentity();
        glTranslatef( p.x, p.y, 0.0f );
        glScalef( xScale, yScale, 1.f );
        glRotatef( theta, 0.0f, 0.0f, 1.0f );
        
        // render the shape in color.
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_COLOR_ARRAY);
        glVertexPointer(3, GL_FLOAT, 0, m_vertexData );
        glColorPointer(4, GL_UNSIGNED_BYTE, 0, m_colorData );
        glDrawArrays(GL_TRIANGLE_FAN, 0, m_vertexCount );
        glDisableClientState(GL_COLOR_ARRAY);
        glDisableClientState(GL_VERTEX_ARRAY);

    }

}


// override
-(void)updateWithTimeDelta:(float)timeDelta
{
    // add animating variables here
}


-(void)clearTouches
{
    [m_touchStack removeAllObjects];    
}


-(void)pushTouchAt:(CGPoint)p
{
    [m_touchStack addObject: [CGPointW fromPoint:p] ];
}


@end
