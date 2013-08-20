//
//  BackgroundGeoScene.m
//  BASICPROJECT
//
//  Created by gideong on 2013.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "BackgroundGeoScene.h"
#import "LinkedList.h"
#import "AspectController.h"


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
@property (nonatomic, retain) RectCoordBuffer *rectBuf;

-(id)initWithDepth:(float)depthIn rectBuf:(RectCoordBuffer *)rectBufIn;

@end

@implementation RectBufStrip

@synthesize rectBuf;

-(id)initWithDepth:(float)depthIn rectBuf:(RectCoordBuffer *)rectBufIn;
{
    if( self = [super initWithDepth:depthIn] )
    {
        self.rectBuf = rectBufIn;
    }
    return self;
}


-(void)dealloc
{
    self.rectBuf = nil;
    [super dealloc];
}

@end


// ------------------------
// helper element representing a single drawable star used by StarsV1Strip
@interface StarsV1El : NSObject
@property (nonatomic, assign) float intensityFactor;
@property (nonatomic, assign) float altitudeFactor;
@property (nonatomic, assign) float paddingFactor;
@end

@implementation StarsV1El

-(id)init
{
    if( self = [super init] )
    {
        // TODO randomly pick these on some distribution.
        self.intensityFactor = 1.f;
        self.altitudeFactor = 1.f;
        self.paddingFactor = 1.f;
    }
    return self;
}

@end


// ------------------------
@interface StarsV1Strip : RectBufStrip
{
    GLbyte *m_colorBuf;
    LinkedList *m_starList;
    float m_maxDistanceBetweenStars;
    
}
@end

@implementation StarsV1Strip

-(id)initWithDepth:(float)depthIn rectBuf:(RectCoordBuffer *)rectBufIn;
{
    if( self = [super initWithDepth:depthIn rectBuf:rectBufIn] )
    {
        m_starList = [[LinkedList alloc] init];
        m_maxDistanceBetweenStars = 5.f;
        
        const size_t colorBufSize = 4 * 6 * sizeof(GLbyte);  // 6 points since we are using triangles mode.
        m_colorBuf = (GLbyte *)malloc( colorBufSize );
        memset( m_colorBuf, 0xff, colorBufSize );  // TODO more interesting colors than pure white. can vary by star.
        
        float totalWidth = [AspectController instance].xPixel;
        float runningWidth = 0;
        while( runningWidth < totalWidth )
        {
            StarsV1El *thisEl = [[[StarsV1El alloc] init] autorelease];
            [m_starList enqueueData:thisEl];
            runningWidth += thisEl.paddingFactor * m_maxDistanceBetweenStars;
        }
    }
    return self;
}


-(void)dealloc
{
    free( m_colorBuf ); m_colorBuf = nil;
    [m_starList release]; m_starList = nil;
    [super dealloc];
}


// override
-(void)drawWithXOffs:(float)xOffs yOffs:(float)yOffs
{
    // TODO: some kind of coord transform required here to account for depth?
    // TODO: offset into list
    float totalWidth = [AspectController instance].xPixel;
    float runningWidth = 0.f;
    LLNode *currentNode = m_starList.head;
    
    CGFloat x, y, w, h;
    while( runningWidth < totalWidth )
    {
        StarsV1El *thisEl = (StarsV1El *)currentNode.data;
        
        // TODO: figure out correct x, y, size, color, etc.
        x = runningWidth;
        y = 500.f;
        w = 2.f;
        h = 2.f;
        
        [self.rectBuf pushRectGeoCoord2dX1:x Y1:y X2:(x + w) Y2:(y + h)];
        [self.rectBuf pushRectColors2dBuf:m_colorBuf];
        [self.rectBuf incPtr];

        runningWidth += thisEl.paddingFactor * m_maxDistanceBetweenStars;
        currentNode = currentNode.next ? currentNode.next : m_starList.head;
    }
    
    
}

@end


// ------------------------
@implementation BaseStripScene
@synthesize sharedRectBuf;

-(id)init
{
    if( self = [super init] )
    {
        const int rectBufCapacity = 256;  // TODO: revisit this once you have settled on some strips.
        self.sharedRectBuf = [[[RectCoordBuffer alloc] initWithTexEnabled:NO capacity:rectBufCapacity] autorelease];
        m_stripList = [[NSMutableArray arrayWithCapacity:16] retain];
    }
    return self;
}


-(void)dealloc
{
    [m_stripList release]; m_stripList = nil;
    self.sharedRectBuf = nil;
    [super dealloc];
}


-(void)setupView
{
}


-(void)drawAllStripsWithXOffs:(float)xOffs yOffs:(float)yOffs
{
    [self setupView];
    for( int i = 0; i < [m_stripList count]; ++i )
    {
        BaseStrip *thisStrip = (BaseStrip *)[m_stripList objectAtIndex:i];
        [thisStrip drawWithXOffs:xOffs yOffs:yOffs];
    }
    [self.sharedRectBuf flush];
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
        [m_stripList addObject:[[[StarsV1Strip alloc] initWithDepth:1.f rectBuf:self.sharedRectBuf] autorelease]];
    }
    return self;
}


// override
-(void)setupView
{
    // a basic ortho view 1:1 with screen pixels, no texturing.
    AspectController *ac = [AspectController instance];
    
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    glOrthof( 0.f, ac.xPixel, 0.f, ac.yPixel, -1.f, 1.f );
    glMatrixMode( GL_MODELVIEW );
    
    glDisable( GL_TEXTURE_2D );
    glEnableClientState( GL_COLOR_ARRAY );
    glEnableClientState( GL_VERTEX_ARRAY );

    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    glEnable( GL_BLEND );
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
