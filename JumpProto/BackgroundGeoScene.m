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


-(float)scaleXForDepth:(float)xIn
{
    return xIn / self.depth;
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
    float xOffsScaled = [self scaleXForDepth:xOffs];
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
    // yMapped not used for this strip type.
    
    // TODO: consider pulling these values out as constants or ivars for perf.
    CGFloat x, y, w, h;
    
    // y coord ranges.
    const float yMin = [AspectController instance].yPixel / 2.f;
    const float yMax = 0.f;
    
    // size ranges
    const float sizeMin = 2.f;
    const float sizeMax = 6.f;
    
    // color component ranges
    const int rMin = 0xff;
    const int rMax = 0xff;
    const int gMin = 0xff;
    const int gMax = 0xff;
    const int bMin = 0x00;
    const int bMax = 0xff;
    
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
    float m_hwm, m_hwx, m_lwm, m_lwx;
    float m_hhm, m_hhx, m_lhm, m_lhx;
    GLbyte m_r, m_g, m_b;
    BOOL m_oddEven;
}

-(id)initWithDepth:(float)depthIn rectBuf:(RectCoordBuffer *)rectBufIn hwm:(float)hwmIn hwx:(float)hwxIn lwm:(float)lwmIn lwx:(float)lwxIn hhm:(float)hhmIn hhx:(float)hhxIn lhm:(float)lhmIn lhx:(float)lhxIn r:(GLbyte)rIn g:(GLbyte)gIn b:(GLbyte)bIn;
@end

@implementation AltRectStrip

-(id)initWithDepth:(float)depthIn rectBuf:(RectCoordBuffer *)rectBufIn hwm:(float)hwmIn hwx:(float)hwxIn lwm:(float)lwmIn lwx:(float)lwxIn hhm:(float)hhmIn hhx:(float)hhxIn lhm:(float)lhmIn lhx:(float)lhxIn r:(GLbyte)rIn g:(GLbyte)gIn b:(GLbyte)bIn
{
    if( self = [super initWithDepth:depthIn rectBuf:rectBufIn] )
    {
        m_hwm = hwmIn; m_hwx = hwxIn; m_lwm = lwmIn; m_lwx = lwxIn;
        m_hhm = hhmIn; m_hhx = hhxIn; m_lhm = lhmIn; m_lhx = lhxIn;
        m_r = rIn; m_g = gIn; m_b = bIn;
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
    h = thisEl.height * yMapped;  // TODO: fix this, need a sliding offset, not overall scale.
    [self.rectBuf pushRectGeoCoord2dX1:x Y1:y X2:(x + w) Y2:(y + h)];
    [self pushSolidColorA:0xff r:m_r g:m_g b:m_b];
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
    
    const float centeringOffset = 0.f;  // adjust for any inherent imbalance in y values, e.g. if we only have positive coords.
    float x = yUnmapped + centeringOffset;  // x as in "input" not "x axis"

    // normalize input "towards" [-1, 1] given some typical size of a level.
    //  this defines the total y-space parallax range. ideally this would be equal to the true range of live blocks
    //  for each level such that we had maximum range of motion across the level, but since we are smoothing the edges,
    //  this doesn't need to be exact.
    const float typicalRange = 5000.f;
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
        
        strip = [[[StarsV1Strip alloc] initWithDepth:4.f rectBuf:self.sharedRectBuf] autorelease];
        [m_stripList addObject:strip];

        strip = [[[AltRectStrip alloc] initWithDepth:2.f rectBuf:self.sharedRectBuf
                                                            hwm:100.f hwx:120.f  lwm:80.f   lwx:130.f
                                                            hhm:140.f hhx: 210.f lhm: 300.f lhx: 545.f
                                                            r:0x50 g:0x50 b:0x50] autorelease];
        [m_stripList addObject:strip];

        strip = [[[AltRectStrip alloc] initWithDepth:1.5f rectBuf:self.sharedRectBuf
                                                            hwm:200.f hwx:240.f  lwm:80.f   lwx:130.f
                                                            //hhm:50.f hhx: 180.f lhm: 200.f lhx: 215.f  // TODO: this is faking depth affecting y :P
                                                            hhm:140.f hhx: 210.f lhm: 300.f lhx: 545.f
                                                            r:0x60 g:0x60 b:0x60] autorelease];
        [m_stripList addObject:strip];
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
    //const CGFloat xIncPerSecond = 100.f;
    const CGFloat xIncPerSecond = 0.f;
    static CGFloat yIncPerSecond = 3500.f;
    const CGFloat yValueLimitAbs = 10000.f;
    CGFloat newX = timeDelta * xIncPerSecond + m_fakeWorldOffset.x;
    CGFloat newY = timeDelta * yIncPerSecond + m_fakeWorldOffset.y;
    if( fabsf( newY ) >= yValueLimitAbs ) yIncPerSecond = -yIncPerSecond;
    m_fakeWorldOffset = CGPointMake( newX, newY );
    
#ifdef TIME_STRIPDRAW
    m_timer_timeUntilNextReport -= timeDelta;
#endif
}

@end
