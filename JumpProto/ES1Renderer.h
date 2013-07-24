//
//  ES1Renderer.h
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.


#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>

#import "ES1RenderDelegate.h"

@interface ES1Renderer : NSObject
{
@private
    EAGLContext *context;

    // The pixel dimensions of the CAEAGLLayer
    GLint backingWidth;
    GLint backingHeight;

    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view
    GLuint defaultFramebuffer, colorRenderbuffer, depthRenderBuffer;

	// the app render delegate
	id<ES1RenderDelegate>		renderDelegate;
}

@property(nonatomic, retain) id<ES1RenderDelegate>   renderDelegate;

- (void)renderWithTimeStamp:(CFTimeInterval)timeStamp;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
-(void)resetTimeStamp;

@end
