//
//  BackgroundGeoScene.m
//  BASICPROJECT
//
//  Created by gideong on 2013.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "BackgroundGeoScene.h"
#import "RectCoordBuffer.h"


// ------------------------
@implementation BaseStrip

@synthesize depth;

-(id)initWithDepth:(float)depthIn
{
    if( self = [super init] )
    {
        self.depth = depthIn;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(void)drawWithXOffs:(float)xOffs yOffs:(float)yOffs
{
}

@end


// ------------------------
@interface Test1Strip : BaseStrip
@end

@implementation Test1Strip

-(id)initWithDepth:(float)depthIn
{
    if( self = [super initWithDepth:depthIn] )
    {
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


// override
-(void)drawWithXOffs:(float)xOffs yOffs:(float)yOffs
{
}

@end


// ------------------------
@implementation BaseStripScene

-(id)init
{
    if( self = [super init] )
    {
        m_stripList = [[NSMutableArray arrayWithCapacity:16] retain];
    }
    return self;
}


-(void)dealloc
{
    [m_stripList release]; m_stripList = nil;
    [super dealloc];
}


-(void)drawAllStripsWithXOffs:(float)xOffs yOffs:(float)yOffs
{
    for( int i = 0; i < [m_stripList count]; ++i )
    {
        //BaseStrip *thisStrip = (BaseStrip *)[m_stripList objectAtIndex:i];
        // TODO
    }
}

@end


// ------------------------
@interface Test1StripScene : BaseStripScene
@end

@implementation Test1StripScene

-(id)init
{
    if( self = [super init] )
    {
        [m_stripList addObject:[[[Test1Strip alloc] initWithDepth:1.f] autorelease]];
    }
    return self;
}
@end

// ------------------------
@interface BackgroundGeoSceneLayerView (private)


@end

@implementation BackgroundGeoSceneLayerView

-(id)init
{
    if( self = [super init] )
    {
        // TODO: a subclass instead
        m_stripScene = [[BaseStripScene alloc] init];
    }
    return self;
}


-(void)dealloc
{
    [m_stripScene release]; m_stripScene = nil;
    [super dealloc];
}


-(void)buildScene
{
	//glClearColor(0.1f, 0.1f, 0.3f, 1.0f);
	//glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    // TODO: hook up offsets.
    [m_stripScene drawAllStripsWithXOffs:0 yOffs:0];
    
}


-(void)updateWithTimeDelta:(float)timeDelta
{
}

@end
