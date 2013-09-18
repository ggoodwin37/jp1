//
//  DpadFeedbackLayerView.m
//  JumpProto
//
//  Created by gideong on 7/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DpadFeedbackLayerView.h"
#import "DebugLogLayerView.h"
#import "GlobalCommand.h"

@interface DpadFeedbackLayerView (private)
-(void)onGlobalCommand_resetDpad;

@end

@implementation DpadFeedbackLayerView

@synthesize dpadInput = m_dpadInput;

-(id)initWithBounds:(CGRect)bounds forTouchZone:(TouchZone)touchZone
{
    if( self = [super init] )
    {
        m_bounds = bounds;
        m_touchZone = touchZone;
        m_dpadInput = nil;
        
        m_leftPressed = NO;
        m_rightPressed = NO;
        
        [GlobalCommand registerObject:self forNotification:GLOBAL_COMMAND_NOTIFICATION_RESETDPAD withSel:@selector(onGlobalCommand_resetDpad)];

    }
    return self;
}


-(void)dealloc
{
    [GlobalCommand unregisterObject:self];
    m_dpadInput = nil;  // is a weak reference, no release
    [super dealloc];
}


-(void)onGlobalCommand_resetDpad
{
    m_meanPointLeft = CGPointMake( 0.f, 0.f );
    m_meanPointRight = CGPointMake( 0.f, 0.f );
    m_leftPressed = NO;
    m_rightPressed = NO;
}


-(void)drawMeanPoints
{
    if( m_dpadInput == nil )
        return;
    
    if( (m_meanPointLeft.x == 0  && m_meanPointLeft.y == 0  ) ||
        (m_meanPointRight.x == 0 && m_meanPointRight.y == 0 )    )
        return;

    static GLbyte colorTableMeanPointLeft[] = { 
        0xff, 0x00, 0x00, 0xcc, 
        0xff, 0x00, 0x00, 0xcc, 
        0xff, 0x00, 0x00, 0xcc, 
        0xff, 0x00, 0x00, 0xcc, 
    };


    static GLbyte colorTableMeanPointRight[] = { 
        0x00, 0x00, 0xff, 0xcc, 
        0x00, 0x00, 0xff, 0xcc, 
        0x00, 0x00, 0xff, 0xcc, 
        0x00, 0x00, 0xff, 0xcc, 
    };

    
    static GLfloat diamondVerts[] = {
        0.0f,  1.0f, 0.0f, 
        0.6f,  0.0f, 0.0f, 
       -0.6f,  0.0f, 0.0f, 
        0.0f, -1.0f, 0.0f, 
    };

    
    float x, y;
    float scaleFactor = 10.f;
   
    // left meanPoint
    glLoadIdentity();
    x = m_meanPointLeft.x;
    y = m_meanPointLeft.y;
	glTranslatef( x, y, 0.f );
    glScalef( scaleFactor, scaleFactor, 0.f );
    
    glColorPointer( 4, GL_UNSIGNED_BYTE, 0, colorTableMeanPointLeft );
    glVertexPointer( 3, GL_FLOAT, 0, diamondVerts );
    glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );

    // right meanPoint
    glLoadIdentity();
    x = m_meanPointRight.x;
    y = m_meanPointRight.y;
	glTranslatef( x, y, 0.f );
    glScalef( scaleFactor, scaleFactor, 0.f );
    
    glColorPointer( 4, GL_UNSIGNED_BYTE, 0, colorTableMeanPointRight );
    glVertexPointer( 3, GL_FLOAT, 0, diamondVerts );
    glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );
    
}


-(void)drawArrows
{
    static GLbyte colorTablePressed[] = { 
        0xdd, 0xdd, 0xff, 0xf0, 
        0xdd, 0xdd, 0xff, 0xf0, 
        0xdd, 0xdd, 0xff, 0xf0, 
    };
    
    static GLbyte colorTableNotPressed[] = { 
        0x55, 0x55, 0x55, 0xcc, 
        0x55, 0x55, 0x55, 0xcc, 
        0x55, 0x55, 0x55, 0xcc, 
    };
    
    static GLfloat triangleVerts[] = {
        0.0f, 0.5f, 0.0f, 
        0.5f, 1.0f, 0.0f, 
        0.5f, 0.0f, 0.0f, 
    };
    
    float x, y;
    float scaleFactor = 50.f;
    
    // left arrow
    glLoadIdentity();
    x = m_bounds.origin.x + ( 1.f * m_bounds.size.width / 3.f );
    y = m_bounds.origin.y + ( 7.f * m_bounds.size.height / 8.f );
	glTranslatef( x, y, 0.f );
    glScalef( scaleFactor, scaleFactor, 0.f );
    
    glColorPointer( 4, GL_UNSIGNED_BYTE, 0, m_leftPressed ? colorTablePressed : colorTableNotPressed );
    glVertexPointer( 3, GL_FLOAT, 0, triangleVerts );
    glDrawArrays( GL_TRIANGLE_STRIP, 0, 3 );
    
    // right arrow
    glLoadIdentity();
    x = m_bounds.origin.x + ( 2.f * m_bounds.size.width / 3.f );
    y = m_bounds.origin.y + ( 7.f * m_bounds.size.height / 8.f );
	glTranslatef( x, y, 0.f );
    glScalef( scaleFactor, scaleFactor, 0.f );
    glRotatef( 180.f, 0, 1, 0 );
    
    glColorPointer( 4, GL_UNSIGNED_BYTE, 0, m_rightPressed ? colorTablePressed : colorTableNotPressed );
    glVertexPointer( 3, GL_FLOAT, 0, triangleVerts );
    glDrawArrays( GL_TRIANGLE_STRIP, 0, 3 );
}


// override
-(void)buildScene
{
    // b-mode disables dpad, so we shouldn't show dpad feedback either.
    if( [m_dpadInput.bModeHolder isBModeActive] ) return;
    
    [self setupStandardOrthoView];
    glDisable( GL_TEXTURE_2D );
    glEnableClientState( GL_COLOR_ARRAY );
    glEnableClientState( GL_VERTEX_ARRAY );
    
    [self drawMeanPoints];
    [self drawArrows];

}


// override
-(void)updateWithTimeDelta:(float)timeDelta
{
}


-(void)tryUpdateMeanPoints
{
    if( m_dpadInput != nil )
    {
        m_meanPointLeft = [[m_dpadInput sorterForZone:m_touchZone] calculateMeanPointLeft];
        m_meanPointRight = [[m_dpadInput sorterForZone:m_touchZone] calculateMeanPointRight];
        
        //DebugOut( ([NSString stringWithFormat:@"lm %fx%f rm %fx%f.", m_meanPointLeft.x, m_meanPointLeft.y, m_meanPointRight.x, m_meanPointRight.y ]) );
    }
}


-(void)setDpadInputRef:(DpadInput *)ref
{
    m_dpadInput = ref;  // assign (weak)
    [self tryUpdateMeanPoints];
}


-(void)onDpadEvent:(DpadEvent *)event
{
    if( event.touchZone != m_touchZone )
        return;
    
    [self tryUpdateMeanPoints];
    
    switch( event.button )
    {
        case DpadLeftButton:
            m_leftPressed = (event.type == DpadPressed);
            break;
        
        case DpadRightButton:
            m_rightPressed = (event.type == DpadPressed);
            break;
            
        case DpadUnknownButton:
            // reset mean pips
            m_meanPointLeft = CGPointMake( 0.f, 0.f );
            m_meanPointRight = CGPointMake( 0.f, 0.f );
            break;
            
        default:
            break;
    }
    
}





@end
