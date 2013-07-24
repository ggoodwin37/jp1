//
//  EAGLView.m
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import "EAGLView.h"

#import "ES1Renderer.h"
#import "gutil.h"

@interface EAGLView (private)

-(void)doInit;

@end

@implementation EAGLView

@synthesize animating, touchHandlerDelegate;
@dynamic animationFrameInterval;

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


// designated initializer.
-(void)doInit
{
	// Get the layer
	CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
	
	eaglLayer.opaque = TRUE;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
	
	// this app uses ES1 only!
	renderer = [[ES1Renderer alloc] init];
	if (!renderer)
	{
		[self release];
		NSAssert( false, @"Couldn't create ES1 renderer problem?" );
		return;
	}
	
	self.userInteractionEnabled = YES;
	self.multipleTouchEnabled = YES;
	
	animating = FALSE;
	displayLinkSupported = FALSE;
	animationFrameInterval = 1;
	displayLink = nil;
	animationTimer = nil;

	// A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
	// class is used as fallback when it isn't available.
	NSString *reqSysVer = @"3.1";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
	{
		displayLinkSupported = TRUE;
		NSLog( @"Using displayLink." );
	}
	else
	{
		NSLog( @"Not using displayLink." );
	}
}


-(id)initWithFrame:(CGRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]))
    {
        NSLog( @"EAGLView initWithFrame. %f, %f   %f x %f.", frameRect.origin.x, frameRect.origin.y, frameRect.size.width, frameRect.size.height );
		[self doInit];
    }
	
    return self;
}


- (BOOL)canBecomeFirstResponder
{ return YES; }


- (void)setRenderDelegate:(id<ES1RenderDelegate>)theDelegate
{
	renderer.renderDelegate = theDelegate;
}

- (void)drawView:(id)sender
{
	CFTimeInterval timeStamp = 0.0;
	if( displayLinkSupported && displayLink )
	{
		timeStamp = [displayLink timestamp];
	}
	else
	{
		timeStamp = (float)getUpTimeMs() / 1000.0f;
	}
    [renderer renderWithTimeStamp:timeStamp];
	
}


- (void)layoutSubviews
{
    [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    // Frame interval defines how many display frames must pass between each time the
    // display link fires. The display link will only fire 30 times a second when the
    // frame internal is two on a display that refreshes 60 times a second. The default
    // frame interval setting of one will fire 60 times a second when the display refreshes
    // at 60 times a second. A frame interval setting of less than one results in undefined
    // behavior.
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;

        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
	[renderer resetTimeStamp];
	
    if (!animating)
    {
        if (displayLinkSupported)
        {
            // CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
            // if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
            // not be called in system versions earlier than 3.1.

            displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
            [displayLink setFrameInterval:animationFrameInterval];
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        else
            animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(drawView:) userInfo:nil repeats:TRUE];

        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        if (displayLinkSupported)
        {
            [displayLink invalidate];
            displayLink = nil;
        }
        else
        {
            [animationTimer invalidate];
            animationTimer = nil;
        }

        animating = FALSE;
    }
}

- (void)dealloc
{
    [renderer release]; renderer = nil;

    [super dealloc];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog( @"controller touchesBegan, there are %d touches in set, and %d in event.", [touches count], [[event allTouches] count] );
	if( touchHandlerDelegate )
	{
		[touchHandlerDelegate touchesBegan:touches withEvent:event];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog( @"layerSceneView touchesMoved, there are %d touches in set, and %d in event.", [touches count], [[event allTouches] count] );
	if( touchHandlerDelegate )
	{
		[touchHandlerDelegate touchesMoved:touches withEvent:event];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog( @"layerSceneView touchesEnded, there are %d touches in set, and %d in event.", [touches count], [[event allTouches] count] );
	if( touchHandlerDelegate )
	{
		[touchHandlerDelegate touchesEnded:touches withEvent:event];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog( @"layerSceneView touchesCancelled, there are %d touches in set, and %d in event.", [touches count], [[event allTouches] count] );
	if( touchHandlerDelegate )
	{
		[touchHandlerDelegate touchesCancelled:touches withEvent:event];
	}
}


- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{	
}

// this default shake recognizer sucks, requires way too much motion to count a shake.
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	//if (motion == UIEventSubtypeMotionShake )
	//{
	//	[[NSNotificationCenter defaultCenter] postNotificationName:@"shake" object:self];
	//}
}



@end
