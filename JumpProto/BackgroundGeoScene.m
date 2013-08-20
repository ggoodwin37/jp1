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
#include "gutil.h"


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
        self.intensityFactor = frand();
        self.altitudeFactor = self.intensityFactor;
        self.paddingFactor = frand();
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
        const int minNumStars = 30;
        m_maxDistanceBetweenStars = [AspectController instance].xPixel / minNumStars;
        
        const size_t colorBufSize = 4 * 6 * sizeof(GLbyte);  // 6 points since we are using triangles mode.
        m_colorBuf = (GLbyte *)malloc( colorBufSize );
        
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


-(void)setSolidColorA:(GLbyte)a r:(GLbyte)r g:(GLbyte)g b:(GLbyte)b
{
    for( int i = 0; i < 6; ++i )
    {
        GLbyte *ptr = m_colorBuf + (i * 4);
        ptr[0] = r;
        ptr[1] = g;
        ptr[2] = b;
        ptr[3] = a;
    }
}

// override
-(void)drawWithXOffs:(float)xOffs yOffs:(float)yOffs
{
    // TODO: some kind of coord transform required here to account for depth?
    // TODO: offset into list
    AspectController *ac = [AspectController instance];
    float totalWidth = ac.xPixel;
    float runningWidth = 0.f;
    LLNode *currentNode = m_starList.head;
    
    CGFloat x, y, w, h;
    while( runningWidth < totalWidth )
    {
        StarsV1El *thisEl = (StarsV1El *)currentNode.data;
        
        x = runningWidth;
        
        const float yMin = 300.f;
        const float yMax = 0.f;
        y = ac.yPixel - FLOAT_INTERP(yMin, yMax, thisEl.altitudeFactor);
        
        const float sizeMin = 2.f;
        const float sizeMax = 6.f;
        w = FLOAT_INTERP(sizeMin, sizeMax, thisEl.intensityFactor);
        h = w;
        [self.rectBuf pushRectGeoCoord2dX1:x Y1:y X2:(x + w) Y2:(y + h)];
        
        const int rMin = 0xff;
        const int rMax = 0xff;
        const int gMin = 0xff;
        const int gMax = 0xff;
        const int bMin = 0x00;
        const int bMax = 0xff;
        
        [self setSolidColorA:0xff
                           r:BYTE_INTERP(rMin, rMax, thisEl.intensityFactor)
                           g:BYTE_INTERP(gMin, gMax, thisEl.intensityFactor)
                           b:BYTE_INTERP(bMin, bMax, thisEl.intensityFactor)];
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
        srandom(time(NULL));
        m_stripScene = [[Test1StripScene alloc] init];
        m_fakeWorldOffset = CGPointMake( 0.f, 0.f );

#ifdef TIME_STRIPDRAW
        m_timer_timeUntilNextReport = TIME_STRIPDRAW_REPORT_PERIOD;
        m_timer_timesDidDraw = 0;
        m_timer_millisecondsSpentDrawing = 0;
#endif
    }
    return self;
}


-(void)dealloc
{
    [m_stripScene release]; m_stripScene = nil;
    [super dealloc];
}



#ifdef TIME_STRIPDRAW
// shamelessly c&p'd from worldView, should really extract this to something more reusable.

-(void)stripDrawTimer_pre
{
    m_timer_start = getUpTimeMs();
}


-(void)stripDrawTimer_post
{
    int delta = (int)( getUpTimeMs() - m_timer_start );
    if( delta < 0 )
    {
        NSLog( @"stripDrawTimer_post: wraparound case." );  // am I imagining this?
        return;
    }
    
    m_timer_millisecondsSpentDrawing += delta;
    ++m_timer_timesDidDraw;
    
    if( m_timer_timeUntilNextReport <= 0.f )
    {
        if( m_timer_timesDidDraw > 0 && m_timer_millisecondsSpentDrawing > 0 )
        {
            float avgMs = ((float)m_timer_millisecondsSpentDrawing) / ((float)m_timer_timesDidDraw);
            NSLog( @"BackgroundGeoScene draw avg: %fms.", avgMs );
        }
        m_timer_timeUntilNextReport = TIME_STRIPDRAW_REPORT_PERIOD;
        m_timer_timesDidDraw = 0;
        m_timer_millisecondsSpentDrawing = 0;
    }
    
}
#endif


-(void)buildScene
{
#ifdef TIME_STRIPDRAW
    [self stripDrawTimer_pre];
#endif

    // TODO: hook up real world offsets
    [m_stripScene drawAllStripsWithXOffs:m_fakeWorldOffset.x yOffs:m_fakeWorldOffset.y];

#ifdef TIME_STRIPDRAW
    [self stripDrawTimer_post];
#endif
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
    
#ifdef TIME_STRIPDRAW
    m_timer_timeUntilNextReport -= timeDelta;
#endif
}

@end
