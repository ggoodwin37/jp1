//
//  MainDrawController.m
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "MainDrawController.h"
#import "BackgroundLayerView.h"
#import "TestLayerView.h"
#import "TestSpriteSheetLayerView.h"
#import "SpriteStateDrawUtil.h"

@interface MainDrawController (private)

-(void)initLayers;

@end

@implementation MainDrawController

@synthesize touchFeedbackLayer = m_touchFeedbackLayer, debugLogLayer = m_debugLogLayer,
            dpadFeedbackLayerViewLeft = m_dpadFeedbackLayerViewLeft, dpadFeedbackLayerViewRight = m_dpadFeedbackLayerViewRight,
            worldView = m_worldView, globalButtonView = m_globalButtonView;

-(id)init
{
	if( self = [super init] )
	{

		//LogStopWatch *stopWatch;
		
		m_timeOfLastFrame = m_timeSinceLastFrame = 0.0f;
		
		[self initLayers];
	}
	return self;
}

-(void)initLayers
{
	// create required layers: fire n forget
	BackgroundLayerView *backgroundLayerView = [[BackgroundLayerView alloc] init];
    //TestSpriteSheetLayerView *testLayerView = [[TestSpriteSheetLayerView alloc] init];
    
    // create required layers: retained
    m_touchFeedbackLayer = [[TouchFeedbackLayerView alloc] init];
#ifdef DEBUG_LOG_LAYER_ACTIVE
    m_debugLogLayer = [[DebugLogLayerView alloc] init];
#endif
    AspectController *ac = [AspectController instance];
    CGRect rectLeft = CGRectMake( 0, 0, ac.xPixel / 2, ac.yPixel );
    CGRect rectRight = CGRectMake( ac.xPixel / 2, 0, ac.xPixel / 2, ac.yPixel );
    m_dpadFeedbackLayerViewLeft = [[DpadFeedbackLayerView alloc] initWithBounds:rectLeft forTouchZone:LeftTouchZone];
    m_dpadFeedbackLayerViewRight = [[DpadFeedbackLayerView alloc] initWithBounds:rectRight forTouchZone:RightTouchZone];
    m_worldView = [[WorldView alloc] init];
    m_globalButtonView = [[GlobalButtonView alloc] init];

	// add them to array
	m_layerList = [[NSArray arrayWithObjects:
                    
                    backgroundLayerView,
                    //testLayerView,
                    m_worldView,
                    m_globalButtonView,
                    m_dpadFeedbackLayerViewLeft,
                    m_dpadFeedbackLayerViewRight,
                    m_touchFeedbackLayer,
#ifdef DEBUG_LOG_LAYER_ACTIVE
                    m_debugLogLayer,
#endif                    
                    nil] retain];

	// release temp layers only (now owned by the list)
    //[testLayerView release];
	[backgroundLayerView release];
}


-(void)dealloc
{
    [m_globalButtonView release]; m_globalButtonView = nil;
#ifdef DEBUG_LOG_LAYER_ACTIVE
    [m_debugLogLayer release]; m_debugLogLayer = nil;
#endif
    [m_touchFeedbackLayer release]; m_touchFeedbackLayer = nil;
    [m_dpadFeedbackLayerViewLeft release]; m_dpadFeedbackLayerViewLeft = nil;
    [m_dpadFeedbackLayerViewRight release]; m_dpadFeedbackLayerViewRight = nil;
    [m_worldView release]; m_worldView = nil;
    [m_layerList release]; m_layerList = nil;
    
    [SpriteStateDrawUtil cleanup];  // release statically-held assets
    
    [super dealloc];
}


// do core scene and logic work for a frame. presentRenderbuffer() will be called by sender.
-(void)renderNextFrameWithTimeStamp:(CFTimeInterval)timeStamp
{
	for( int i = 0; i < [m_layerList count]; ++i )
	{
		LayerView *thisLayer = [m_layerList objectAtIndex:i];
		[thisLayer buildScene];
	}
	
	// avoid a huge spike in timeDelta for second frame (since timeOfLastFrame = 0 initially).
	if( m_timeOfLastFrame > 0.0 )
	{
		m_timeSinceLastFrame = timeStamp - m_timeOfLastFrame;
	}
	m_timeOfLastFrame = timeStamp;
}


-(void)afterPresentScene
{

	for( int i = 0; i < [m_layerList count]; ++i )
	{
		LayerView *thisLayer = [m_layerList objectAtIndex:i];
		[thisLayer updateWithTimeDelta:m_timeSinceLastFrame];
	}
	
	//NSLog( @"--- frame done ------------" );
	
}


// called by owner to indicate that time has been interrupted and we should reset stored values.
-(void)resetTimeStamp
{
	m_timeOfLastFrame = m_timeSinceLastFrame = 0.0f;
}

@end
