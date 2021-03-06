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
@interface BaseStrip : NSObject

@property (nonatomic, assign) float depth;

-(id)initWithDepth:(float)depth;
-(float)scaleXForDepth:(float)xIn;
-(void)drawWithXOffs:(float)xOffs yOffs:(float)yOffs;

@end


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


-(float)scaleXForDepth:(float)xIn
{
    return xIn * (1.f - (self.depth / STRIP_DEPTH_MAX));
}


-(void)drawWithXOffs:(float)xOffs yOffs:(float)yOffs
{
}

@end


// ------------------------
// helper element representing a base element in a strip list of elements to draw.
@interface BaseStripEl : NSObject

-(float)getWidth;

@end

@implementation BaseStripEl

-(float)getWidth
{
    NSAssert( NO, @"Don't call base version." );
    return 0.f;
}
@end


// ------------------------
@interface RectBufStrip : BaseStrip {
    GLbyte *m_colorBuf;
    LinkedList *m_elList;
    float m_totalListWidth;  // how wide (in screen coords) is one walk down the list?
    float m_inherentOffset;  // shift this layer to avoid lining up with others. could be used for animation in future.
}

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

        m_elList = [[LinkedList alloc] init];
        m_totalListWidth = 0;

        const size_t colorBufSize = 4 * 6 * sizeof(GLbyte);  // 6 points since we are using triangles mode.
        m_colorBuf = (GLbyte *)malloc( colorBufSize );
    }
    return self;
}


-(void)dealloc
{
    free( m_colorBuf ); m_colorBuf = nil;
    [m_elList release]; m_elList = nil;
    self.rectBuf = nil;
    [super dealloc];
}


// call this during subclass init. This gives subclass a chance to set instance state first.
-(void)createListEls
{
    m_totalListWidth = 0;
    float totalWidth = [AspectController instance].xPixel;
    while( m_totalListWidth < totalWidth )
    {
        BaseStripEl *thisEl = [self createOneEl];
        [m_elList enqueueData:thisEl];
        m_totalListWidth += [thisEl getWidth];
    }
    m_inherentOffset = frandrange( 0.f, m_totalListWidth );  // apply a random offset for now.
}


-(BaseStripEl *)createOneEl
{
    NSAssert( NO, @"Don't call base version.");
    return nil;
}


-(void)pushSolidColorA:(GLbyte)a r:(GLbyte)r g:(GLbyte)g b:(GLbyte)b
{
    for( int i = 0; i < 6; ++i )
    {
        GLbyte *ptr = m_colorBuf + (i * 4);
        ptr[0] = r;
        ptr[1] = g;
        ptr[2] = b;
        ptr[3] = a;
    }
    [self.rectBuf pushRectColors2dBuf:m_colorBuf];
}


// override
-(void)drawWithXOffs:(float)xOffs yOffs:(float)yOffs
{
    float xOffsScaled = [self scaleXForDepth:(xOffs + m_inherentOffset)];
    float xOffsScaledNormalized = xOffsScaled - (m_totalListWidth * floorf( xOffsScaled / m_totalListWidth ) );
    
    // starting from head, burn through nodes until we've skipped over enough to meet the scaled, normalized offset.
    LLNode *currentNode = m_elList.head;
    BaseStripEl *firstEl = (BaseStripEl *)currentNode.data;
    float runningWidth = -[firstEl getWidth];  // sloppy: make sure we draw the element at the edge in all cases.
    float nextWidth;  // this look-ahead allows us to draw slightly offscreen so els can come onscreen smoothly and incrementally.
    do
    {
        BaseStripEl *thisEl = (BaseStripEl *)currentNode.data;
        runningWidth += [thisEl getWidth];
        currentNode = [m_elList nextOrWrap:currentNode];
        BaseStripEl *nextEl = (BaseStripEl *)currentNode.data;  // currentNode has already been inc'd.
        nextWidth = [nextEl getWidth];  // lookahead to next margin.
    } while( runningWidth + nextWidth < xOffsScaledNormalized );
    runningWidth -= xOffsScaledNormalized;
    
    AspectController *ac = [AspectController instance];
    float totalWidth = ac.xPixel;
    while( runningWidth < totalWidth )
    {
        BaseStripEl *thisEl = (BaseStripEl *)currentNode.data;
        [self drawOneEl:thisEl xOffs:runningWidth yMapped:yOffs];
        
        runningWidth += [thisEl getWidth];
        currentNode = [m_elList nextOrWrap:currentNode];
    }
}


-(void)drawOneEl:(BaseStripEl *)el xOffs:(float)xOffs yMapped:(float)yMapped
{
    NSAssert( NO, @"Don't call base version." );
}

@end


// ------------------------
// helper element representing a single drawable star used by StarsV1Strip
@interface StarsV1El : BaseStripEl
@property (nonatomic, assign) float intensityFactor;
@property (nonatomic, assign) float altitudeFactor;
@property (nonatomic, assign) float rightMargin;

@end

@implementation StarsV1El

-(id)initWithRightMargin:(float)rightMarginIn
{
    if( self = [super init] )
    {
        self.intensityFactor = frand();
        self.altitudeFactor = self.intensityFactor;
        self.rightMargin = rightMarginIn;
    }
    return self;
}


// override
-(float)getWidth
{
    return self.rightMargin;
}

@end


// ------------------------
@interface StarsV1Strip : RectBufStrip
{
    
}
@end

@implementation StarsV1Strip

-(id)initWithDepth:(float)depthIn rectBuf:(RectCoordBuffer *)rectBufIn
{
    if( self = [super initWithDepth:depthIn rectBuf:rectBufIn] )
    {
        [self createListEls];
    }
    return self;
}


// override
-(BaseStripEl *)createOneEl
{
    const int minNumStars = 60;
    float maxDistanceBetweenStars = [AspectController instance].xPixel / minNumStars;
    float thisMargin = frand() * maxDistanceBetweenStars;
    return [[[StarsV1El alloc] initWithRightMargin:thisMargin] autorelease];
}


// override
-(void)drawOneEl:(BaseStripEl *)el xOffs:(float)xOffs yMapped:(float)yMapped
{
    static BOOL initializedStatics = NO;
    static float halfScreen, yRangeMin, yRangeMax, sizeMin, sizeMax;
    static int rMin, rMax, gMin, gMax, bMin, bMax;
    if( !initializedStatics )
    {
        // y ranges
        initializedStatics = YES;
        halfScreen = [AspectController instance].yPixel / 2.f;
        yRangeMin = halfScreen * 0.9f;
        yRangeMax = halfScreen * 1.1f;
        
        // size ranges
        sizeMin = 2.f;
        sizeMax = 6.f;

        // color component ranges
        rMin = 0xff;
        rMax = 0xff;
        gMin = 0xff;
        gMax = 0xff;
        bMin = 0x00;
        bMax = 0xff;
    }
    
    CGFloat x, y, w, h;
    
    const float yMin = FLOAT_INTERP(yRangeMin, yRangeMax, yMapped);
    const float yMax = 0.f;
    
    StarsV1El *starsEl = (StarsV1El *)el;
    x = xOffs;
    y = [AspectController instance].yPixel - FLOAT_INTERP(yMin, yMax, starsEl.altitudeFactor);
    w = FLOAT_INTERP(sizeMin, sizeMax, starsEl.intensityFactor);
    h = w;
    [self.rectBuf pushRectGeoCoord2dX1:x Y1:y X2:(x + w) Y2:(y + h)];
    
    [self pushSolidColorA:0xff
                        r:BYTE_INTERP(rMin, rMax, starsEl.intensityFactor)
                        g:BYTE_INTERP(gMin, gMax, starsEl.intensityFactor)
                        b:BYTE_INTERP(bMin, bMax, starsEl.intensityFactor)];
    
    [self.rectBuf incPtr];
}

@end


// ------------------------
// helper element representing a single drawable el used by AltRectStrip
@interface AltRectStripEl : BaseStripEl
@property (nonatomic, assign) float width;
@property (nonatomic, assign) float height;

@end

@implementation AltRectStripEl

-(id)initWithWidth:(float)widthIn height:(float)heightIn
{
    if( self = [super init] )
    {
        self.width = widthIn;
        self.height = heightIn;
    }
    return self;
}


// override
-(float)getWidth
{
    return self.width;
}

@end


// ------------------------
@interface AltRectStrip : RectBufStrip
{
    // not even gonna try to explain this.
    BOOL m_topDown;
    float m_hwm, m_hwx, m_lwm, m_lwx;
    float m_hhm, m_hhx, m_lhm, m_lhx;
    GLbyte m_r, m_g, m_b, m_a;
    BOOL m_oddEven;
}

-(id)initWithDepth:(float)depthIn rectBuf:(RectCoordBuffer *)rectBufIn topDown:(BOOL)topDownIn hwm:(float)hwmIn hwx:(float)hwxIn lwm:(float)lwmIn lwx:(float)lwxIn hhm:(float)hhmIn hhx:(float)hhxIn lhm:(float)lhmIn lhx:(float)lhxIn r:(GLbyte)rIn g:(GLbyte)gIn b:(GLbyte)bIn a:(GLbyte)aIn;
@end

@implementation AltRectStrip

-(id)initWithDepth:(float)depthIn rectBuf:(RectCoordBuffer *)rectBufIn topDown:(BOOL)topDownIn hwm:(float)hwmIn hwx:(float)hwxIn lwm:(float)lwmIn lwx:(float)lwxIn hhm:(float)hhmIn hhx:(float)hhxIn lhm:(float)lhmIn lhx:(float)lhxIn r:(GLbyte)rIn g:(GLbyte)gIn b:(GLbyte)bIn a:(GLbyte)aIn
{
    if( self = [super initWithDepth:depthIn rectBuf:rectBufIn] )
    {
        m_topDown = topDownIn;
        m_hwm = hwmIn; m_hwx = hwxIn; m_lwm = lwmIn; m_lwx = lwxIn;
        m_hhm = hhmIn; m_hhx = hhxIn; m_lhm = lhmIn; m_lhx = lhxIn;
        m_r = rIn; m_g = gIn; m_b = bIn; m_a = aIn;
        m_oddEven = NO;
        [self createListEls];
    }
    return self;
}

// override
-(BaseStripEl *)createOneEl
{
    float targetW;
    float targetH;
    if( m_oddEven )
    {
        targetW = frandrange( m_hwm, m_hwx );
        targetH = frandrange( m_hhm, m_hhx );
    } else {
        targetW = frandrange( m_lwm, m_lwx );
        targetH = frandrange( m_lhm, m_lhx );
    }
    m_oddEven = !m_oddEven;
    
    AltRectStripEl *newEl = [[[AltRectStripEl alloc] initWithWidth:targetW height:targetH] autorelease];
    return newEl;
}


// override
-(void)drawOneEl:(BaseStripEl *)el xOffs:(float)xOffs yMapped:(float)yMapped
{
    AltRectStripEl *thisEl = (AltRectStripEl *)el;
    CGFloat x, y, w, h;
    x = xOffs;
    y = 0;
    w = thisEl.width;
    
    // adjust height for depth and yMapped (based on worldY):
    //  when we are at the bottom of the world, the deepest layers should be higher
    //  as we approach the top of the world, the deepest layers and shallowest should converge around yMax (y-goes-up)
    //  this will be opposite for topdown mode.

    const float yPix = [AspectController instance].yPixel;
    const float minOffset = 0.05f * yPix;
    const float maxOffset = 0.45f * yPix;
    float depthFactor = self.depth / STRIP_DEPTH_MAX;
    float offset = FLOAT_INTERP(minOffset, maxOffset, depthFactor);
    
    float yFactor;
    if( m_topDown )
    {
        yFactor = yMapped;
    } else {
        yFactor = 1.f - yMapped;
    }
    offset *= yFactor;
    h = thisEl.height + offset;
    
    if( m_topDown )
    {
        y = yPix - h;
    }
    
    [self.rectBuf pushRectGeoCoord2dX1:x Y1:y X2:(x + w) Y2:(y + h)];
    [self pushSolidColorA:m_a r:m_r g:m_g b:m_b];
    [self.rectBuf incPtr];
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


-(float)mapYOffs:(float)yUnmapped
{
    // input value is any y value. output is mapped onto [0, 1);
    
    const float centeringOffset = -5000.f;  // adjust for any inherent imbalance in y values, e.g. if we only have positive coords.
    float x = yUnmapped + centeringOffset;  // x as in "input" not "x axis"

    // normalize input "towards" [-1, 1] given some typical size of a level.
    //  this defines the total y-space parallax range. ideally this would be equal to the true range of live blocks
    //  for each level such that we had maximum range of motion across the level, but since we are smoothing the edges,
    //  this doesn't need to be exact.
    const float typicalRange = 7000.f;
    x = x / typicalRange;
    
    // smooth clipping function: y = x / sqrt( x * x + 1 )  (sigmoid function)
    float result = x / sqrtf( x * x + 1.f );
    result = (result + 1.f) / 2.f;  // [-1,1] -> [0, 1]
    
    //NSLog( @"mapY: in=%f out=%f", yUnmapped, result );
    return result;
}


-(void)drawAllStripsWithXOffs:(float)xOffs yOffs:(float)yOffs
{
    float unitY = [self mapYOffs:yOffs];
    [self setupView];
    for( int i = 0; i < [m_stripList count]; ++i )
    {
        BaseStrip *thisStrip = (BaseStrip *)[m_stripList objectAtIndex:i];
        [thisStrip drawWithXOffs:xOffs yOffs:unitY];
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
        id strip;
        
        // stars
        strip = [[[StarsV1Strip alloc] initWithDepth:95.f rectBuf:self.sharedRectBuf] autorelease];
        [m_stripList addObject:strip];
        
        // hills
        strip = [[[AltRectStrip alloc] initWithDepth:75.f rectBuf:self.sharedRectBuf
                                             topDown:NO
                                                 hwm:128.f hwx:345.f lwm:90.f lwx:180.f
                                                 hhm:100.f hhx:164.f lhm:100.f lhx:228.f
                                                   r:0x10 g:0x80 b:0x10 a:0xff] autorelease];
        [m_stripList addObject:strip];

        // buildings
        for( int i = 0; i < 2; ++i ) {
            float depth = 50.f - (i * 10.f);
            int c = 0x40 + (i * 12);
            strip = [[[AltRectStrip alloc] initWithDepth:depth rectBuf:self.sharedRectBuf
                                                 topDown:NO
                                                     hwm:64.f hwx:64.f lwm:64.f lwx:64.f
                                                     hhm:0.f hhx:64.f lhm:64.f lhx:128.f
                                                       r:c g:c b:c a:0xff] autorelease];
            [m_stripList addObject:strip];
        }
        
        // clouds
        for( int i = 0; i < 3; ++i ) {
            float depth = 20.f - (i * 10.f);
            int c = 0x70 + (i * 12);
            strip = [[[AltRectStrip alloc] initWithDepth:depth rectBuf:self.sharedRectBuf
                                                 topDown:YES
                                                     hwm:300.f hwx:400.f lwm:200.f lwx:300.f
                                                     hhm:0.f hhx:100.f lhm:0.f lhx:100.f
                                                       r:c g:c b:c a:0x40] autorelease];
            [m_stripList addObject:strip];
        }
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

-(id)initWithWorldView:(WorldView *)worldViewIn;
{
    if( self = [super init] )
    {
        srandom((unsigned int)time(NULL));
        m_stripScene = [[Test1StripScene alloc] init];
        m_worldView = [worldViewIn retain];
        
#ifdef FAKE_MOTION
        m_fakeWorldOffset = CGPointMake( 0.f, 0.f );
#endif

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
    [m_worldView release]; m_worldView = nil;
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

    float xOffs, yOffs;
#ifdef FAKE_MOTION
    xOffs = m_fakeWorldOffset.x;
    yOffs = m_fakeWorldOffset.y;
#else
    CGPoint focalPoint = m_worldView.cameraFocalPoint;
    const float xScale = 0.15f;
    const float yScale = 1.f;
    xOffs = focalPoint.x * xScale;
    yOffs = focalPoint.y * yScale;
    //NSLog(@"yOffs=%f", yOffs );
#endif
    [m_stripScene drawAllStripsWithXOffs:xOffs yOffs:yOffs];

#ifdef TIME_STRIPDRAW
    [self stripDrawTimer_post];
#endif
}


-(void)updateWithTimeDelta:(float)timeDelta
{
#ifdef FAKE_MOTION
    // fake movement: x increases unbounded, y bounces back and forth between two extremes.
    const CGFloat xIncPerSecond = 400.f;
    static CGFloat yIncPerSecond = 3500.f;
    const CGFloat yValueLimitAbs = 10000.f;
    CGFloat newX = timeDelta * xIncPerSecond + m_fakeWorldOffset.x;
    CGFloat newY = timeDelta * yIncPerSecond + m_fakeWorldOffset.y;
    if( fabsf( newY ) >= yValueLimitAbs ) yIncPerSecond = -yIncPerSecond;
    m_fakeWorldOffset = CGPointMake( newX, newY );
#endif
    
#ifdef TIME_STRIPDRAW
    m_timer_timeUntilNextReport -= timeDelta;
#endif
}

@end
