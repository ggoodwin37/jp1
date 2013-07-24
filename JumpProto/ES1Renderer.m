//
//  ES1Renderer.m
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import "ES1Renderer.h"

@implementation ES1Renderer

@synthesize renderDelegate;

// Create an OpenGL ES 1.1 context
- (id)init
{
    if ((self = [super init]))
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

        if (!context || ![EAGLContext setCurrentContext:context])
        {
            [self release];
            return nil;
        }
		
		// GL setup happens in resizeFromLayer:
	}

    return self;
}


- (void)renderWithTimeStamp:(CFTimeInterval)timeStamp
{
	
	[renderDelegate renderNextFrameWithTimeStamp:timeStamp];

	
	// draw it
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);  // make sure colorbuffer (not depthbuffer) is bound.
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];


	// give the delegate a chance to do some stuff after we show the frame.
	[renderDelegate afterPresentScene];
	
}


-(void)resetTimeStamp
{
	[renderDelegate resetTimeStamp];
}


- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{	
	// Create main framebuffer object.
	glGenFramebuffersOES(1, &defaultFramebuffer);
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);

	// create primary color renderbuffer with backing provided by the CALayer
	glGenRenderbuffersOES(1, &colorRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);

	// read color renderbuffer dims so we know how much storage is needed for depth buffer.
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	// create depth buffer for main framebuffer
	glGenRenderbuffersOES(1, &depthRenderBuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderBuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderBuffer);
	
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
	NSLog( @"ES1Renderer resizeFromLayer OK: %dx%d.", backingWidth, backingHeight );

	glViewport(0, 0, backingWidth, backingHeight);

    return YES;
}

- (void)dealloc
{
    // Tear down GL
    if (defaultFramebuffer)
    {
        glDeleteFramebuffersOES(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }

    if (colorRenderbuffer)
    {
        glDeleteRenderbuffersOES(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }

	if( depthRenderBuffer )
	{
		glDeleteRenderbuffersOES(1, &depthRenderBuffer);
		depthRenderBuffer = 0;
	}
	
    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];

    [context release];
    context = nil;

    [super dealloc];
}

@end
