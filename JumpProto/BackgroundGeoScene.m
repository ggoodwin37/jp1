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
@interface RectBufStrip : BaseStrip
{
    RectCoordBuffer *m_rectCoordBuffer;
}

-(id)initWithDepth:(float)depthIn capacity:(int)capacity;

@end

@implementation RectBufStrip

-(id)initWithDepth:(float)depthIn capacity:(int)capacity
{
    if( self = [super initWithDepth:depthIn] )
    {
        m_rectCoordBuffer = [[RectCoordBuffer alloc] initWithTexEnabled:NO capacity:capacity];
    }
    return self;
}


-(void)dealloc
{
    [m_rectCoordBuffer release]; m_rectCoordBuffer = nil;
    [super dealloc];
}


// override
-(void)drawWithXOffs:(float)xOffs yOffs:(float)yOffs
{
    // TODO
}

@end


// ------------------------
@interface Test1Strip : RectBufStrip
@end

@implementation Test1Strip

-(id)initWithDepth:(float)depthIn
{
    if( self = [super initWithDepth:depthIn capacity:8] )
    {
        // TODO: any old shit
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
  // TODO: some kind of coord transform required here to account for depth?    
    
    
    
    
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
        BaseStrip *thisStrip = (BaseStrip *)[m_stripList objectAtIndex:i];
        [thisStrip drawWithXOffs:xOffs yOffs:yOffs];
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
        m_stripScene = [[Test1StripScene alloc] init];
        m_fakeWorldOffset = CGPointMake( 0.f, 0.f );
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
    // TODO: hook up real world offsets
    [m_stripScene drawAllStripsWithXOffs:m_fakeWorldOffset.x yOffs:m_fakeWorldOffset.y];
}


-(void)updateWithTimeDelta:(float)timeDelta
{
    // fake movement: x increases unbounded, y bounces back and forth between two extremes.
    const CGFloat xIncPerSecond = 10.f;   // TODO tune
    static CGFloat yIncPerSecond = 10.f;  // TODO tune
    const CGFloat yValueLimitAbs = 100.f; // TODO tune
    CGFloat newX = timeDelta * xIncPerSecond + m_fakeWorldOffset.x;
    CGFloat newY = timeDelta * yIncPerSecond + m_fakeWorldOffset.y;
    if( fabsf( newY ) >= yValueLimitAbs ) yIncPerSecond = -yIncPerSecond;
    m_fakeWorldOffset = CGPointMake( newX, newY );
}

@end
