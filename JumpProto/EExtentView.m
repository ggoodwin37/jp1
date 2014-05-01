//
//  EExtentView.h
//

#import "EWorldView.h"
#import "AspectController.h"
#import "CGPointW.h"
#import "gutil.h"
#import "constants.h"
#import "SpriteManager.h"
#import "EBlockPresetSpriteNames.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// EWorldView
@interface EWorldView (private)
-(void)initText;
@end


@implementation EWorldView

@synthesize level;
@synthesize worldRect;
@synthesize currentToolMode;
@synthesize document;
@synthesize gridVisible;
@synthesize geoModeVisible;
@synthesize worldViewEventCallback;
@synthesize docDirty;
@synthesize groupOverlayDrawer;
@synthesize drawGroupOverlay;
@synthesize activeGroupId;
@synthesize currentSnap;
@synthesize currentTouchEventPanZoomed;  // whether the current event ever caused a pan/zoom (cancelling other tools).
@synthesize blockMRUList;
@synthesize freeDrawStartPointWorld;
@synthesize freeDrawEndPointWorld;

// TODO: general: this class knows about drawing stuff and also about editing commands.
//       need a better abstraction.

-(id)initWithCoder:(NSCoder *)aDecoder
{
	if( self = [super initWithCoder:aDecoder] )
	{
        m_panZoomGestureProcessor = [[EPanZoomProcessor alloc] init];
        [m_panZoomGestureProcessor registerConsumer:self];
        self.worldViewEventCallback = nil;
        
        self.docDirty = NO;
        
        self.activeGroupId = GROUPID_NONE;
        self.currentSnap = 2;
        
        self.groupOverlayDrawer = [[UILabel alloc] init];
        [self initText];
        
        self.cursorVisible = NO;
        
        self.currentTouchEventPanZoomed = NO;
        
        self.blockMRUList = [[EBlockMRUList alloc] initWithMaxSize:8];
        // TODO: consider pre-populating this list with some stuff.
	}
	return self;
}


-(void)dealloc
{
    self.blockMRUList = nil;
    self.groupOverlayDrawer = nil;
    m_blockPresetStateHolder = nil;  // weak
    self.level = nil;    // weak
    self.document = nil; // weak
    self.worldViewEventCallback = nil;  // weak
    [m_panZoomGestureProcessor release]; m_panZoomGestureProcessor = nil;
    
    [super dealloc];
}

// could save one mult or divide each by prefactoring if needed.
#define viewToWorld( input_viewcoord, worldorig, worldsize, viewsize ) ( (worldorig) + (((input_viewcoord)/(viewsize)) * (worldsize) ) )
#define worldToView( input_worldcoord, worldorig, worldsize, viewsize )  ( ((input_worldcoord) - (worldorig)) * (viewsize) / (worldsize) )


-(void)drawGridToContext:(CGContextRef)context
{
    if( self.worldRect.size.width <= 0.f || self.worldRect.size.height <= 0.f )
    {
        NSAssert( NO, @"bad worldRect." );
        return;
    }
    if( self.frame.size.width <= 0.f || self.frame.size.height <= 0.f )
    {
        NSAssert( NO, @"bad frameRect." );
        return;
    }

    const float gridSpaceWorldUnits = ONE_BLOCK_SIZE_Fl;

    // support for drawing every nth line.
    int lineSkipCounterMax;
    int lineSkipCounter;

    const BOOL dynamicSpacing = NO;
    if( dynamicSpacing )
    {
        float oneBlockWidthInViewUnits = worldToView( gridSpaceWorldUnits, 0.f, self.worldRect.size.width, self.frame.size.width );
        if( oneBlockWidthInViewUnits <= 12.f )
        {
            lineSkipCounterMax = 4;
        }
        else if( oneBlockWidthInViewUnits <= 36.f )
        {
            lineSkipCounterMax = 2;
        }
        else
        {
            lineSkipCounterMax = 1;
        }
    }
    else
    {
        // not dynamic spacing, line skip max is tied to world's snap grid.
        int snapFactor = 1;
        switch( self.currentSnap )
        {
            case 0: default: snapFactor = 1; break;
            case 1: snapFactor = 2; break;
            case 2: snapFactor = 4; break;
            case 3: snapFactor = 8; break;  // aka 2^n
                
        }
        lineSkipCounterMax = snapFactor;
    }
    
    const float grayIntensity = 0.4f;
	CGContextSetRGBStrokeColor( context, grayIntensity, grayIntensity, grayIntensity, 1.0 );
	CGContextSetLineWidth( context, 1.5 );

    float u, umax, v;
    float wo, ws, vs;  // worldOrigin, worldSize, viewSize
    
    // first draw the vertical grid (iterating x)
    wo = self.worldRect.origin.x;
    ws = self.worldRect.size.width;
    vs = self.frame.size.width;
    u = viewToWorld( 0.f, wo, ws, vs );
    u = ceilf( u / gridSpaceWorldUnits ) * gridSpaceWorldUnits;
    umax = viewToWorld( self.frame.size.width, wo, ws, vs );
    lineSkipCounter = (int)(floorf( u / gridSpaceWorldUnits )) % lineSkipCounterMax;
    for( ; u < umax; u += gridSpaceWorldUnits  )
    {
        if( lineSkipCounter == 0 )
        {
            v = worldToView( u, wo, ws, vs );
            CGContextMoveToPoint( context, v, 0.f );
            CGContextAddLineToPoint( context, v, self.frame.size.height );
        }
        ++lineSkipCounter;
        if( lineSkipCounter >= lineSkipCounterMax )
        {
            lineSkipCounter = 0;
        }
    }
    CGContextStrokePath(context);

    // then draw the horizontal grid (iterating y)
    wo = self.worldRect.origin.y;
    ws = self.worldRect.size.height;
    vs = self.frame.size.height;
    u = viewToWorld( 0.f, wo, ws, vs );
    u = ceilf( u / gridSpaceWorldUnits ) * gridSpaceWorldUnits;
    umax = viewToWorld( self.frame.size.height, wo, ws, vs );
    lineSkipCounter =  (int)(floorf( u / gridSpaceWorldUnits )) % lineSkipCounterMax;
    for( ; u < umax; u += gridSpaceWorldUnits  )
    {
        if( lineSkipCounter == 0 )
        {
            v = worldToView( u, wo, ws, vs );
            CGContextMoveToPoint( context, 0.f, v );
            CGContextAddLineToPoint( context, self.frame.size.width, v );
        }
        ++lineSkipCounter;
        if( lineSkipCounter >= lineSkipCounterMax )
        {
            lineSkipCounter = 0;
        }
    }    
	CGContextStrokePath(context);
}


// TODO: the counts could be non-integral
-(void)drawBlockPreset:(EBlockPreset)preset at:(CGRect)rectMaster toContext:(CGContextRef)context xCount:(int)xCount yCount:(int)yCount
{
    if( preset == EBlockPreset_None )
    {
        NSAssert( NO, @"Asked to draw a None preset, that's not supposed to happen." );
        return;
    }
    
    NSString *thisPresetSpriteName = [EBlockPresetSpriteNames getSpriteNameForPreset:preset];
    UIImage *thisImage = [[SpriteManager instance] getImageForSpriteName:thisPresetSpriteName];
    
    float oneTileWidth = rectMaster.size.width / xCount;
    float oneTileHeight = rectMaster.size.height / yCount;

    for( int y = 0; y < yCount; ++y )
    {
        for( int x = 0; x < xCount; ++x )
        {
            CGRect rect = CGRectMake( rectMaster.origin.x + (x * oneTileWidth), rectMaster.origin.y + (y * oneTileHeight),
                                      oneTileWidth, oneTileHeight );
            [thisImage drawInRect:rect];
        }
    }
}


-(void)initText
{
    self.groupOverlayDrawer.textColor = [UIColor whiteColor];
    self.groupOverlayDrawer.font = [UIFont fontWithName:@"Courier-Bold" size:(28.0)];
    self.groupOverlayDrawer.textAlignment = UITextAlignmentCenter;
}


-(void)drawBlockGroupOverlayForMarker:(EGridBlockMarker *)marker at:(CGRect)rect toContext:(CGContextRef)context
{
    NSString *overlayText;
    if( marker.props.groupId == GROUPID_NONE )
    {
        overlayText = @"==";
    }
    else
    {
        char c = '?';
        if( (int)marker.props.groupId <= ('Z' - 'A') )
        {
            c = (char)(marker.props.groupId - GROUPID_FIRST + 'A');
        }
        overlayText = [NSString stringWithFormat:@"%c", c];
    }
    self.groupOverlayDrawer.text = overlayText;

    [self.groupOverlayDrawer drawTextInRect:rect];
}


-(void)drawBlockGeoViewWithBoundingBox:(CGRect)boundingBox toContext:(CGContextRef)context colorSeed:(int)seed
{
    srand(seed + 7725); // unmodified seeds are too popular right now, I doubt you've heard of seed 7725.
    unsigned int rComp0 = rand() % 1000;
    unsigned int gComp0 = rand() % 1000;
    unsigned int bComp0 = rand() % 1000;
    
    float rComp1 = (float)rComp0 / 1000;
    float gComp1 = (float)gComp0 / 1000;
    float bComp1 = (float)bComp0 / 1000;
    float mag = sqrt( rComp1 * rComp1 + gComp1 * gComp1 + gComp1 * gComp1 );
    if( mag == 0.f ) mag = 0.3f;  //  suuure
    rComp1 /= mag;
    gComp1 /= mag;
    bComp1 /= mag;
    
    float r = rComp1;
    float g = gComp1;
    float b = bComp1;
    float inset = 4.f;
    CGRect insetBoundingBox = CGRectMake( boundingBox.origin.x + inset,
                                          boundingBox.origin.y + inset,
                                          boundingBox.size.width - 2 * inset,
                                          boundingBox.size.height - 2 * inset );
	CGContextSetRGBStrokeColor( context, r, g, b, 1.f );
	CGContextSetLineWidth( context, 8 );
    CGContextAddRect( context, insetBoundingBox );
    CGContextStrokePath( context );
}


-(void)drawCursorWithBoundingBox:(CGRect)boundingBox toContext:(CGContextRef)context
{
	CGContextSetRGBStrokeColor( context, 1.f, 1.f, 0.f, 0.75f );
	CGContextSetLineWidth( context, 4 );
    CGContextAddRect( context, boundingBox );
    CGContextStrokePath( context );
}


-(float)snapCoord:(float)u
{
    int snapFactor = 1;
    switch( self.currentSnap )
    {
        case 0: default: snapFactor = 1; break;
        case 1: snapFactor = 2; break;
        case 2: snapFactor = 4; break;
        case 3: snapFactor = 8; break;  // aka 2^n
            
    }
    float f = GRID_SIZE_Fl * snapFactor;

    return f * floorf( u / f );
}


-(float)snapCoordUp:(float)u
{
    int snapFactor = 1;
    switch( self.currentSnap )
    {
        case 0: default: snapFactor = 1; break;
        case 1: snapFactor = 2; break;
        case 2: snapFactor = 4; break;
        case 3: snapFactor = 8; break;  // aka 2^n
            
    }
    float f = GRID_SIZE_Fl * snapFactor;
    
    return f * ceilf( u / f );
}


// TODO: restricted rect version? need to manage dirty rect manually, handle different coordinate transforms, and
//       update draw methods to optionally only draw some subset.
-(void)drawGridDocumentToContext:(CGContextRef)context
{
    if( self.document == nil )
    {
        NSLog( @"EWorldView drawGridDocumentToContext: no document." );
        return;
    }
    
    float xWorldMin, xWorldMax;
    xWorldMin = viewToWorld( 0.f, self.worldRect.origin.x, self.worldRect.size.width, self.frame.size.width );
    xWorldMin = floorf( xWorldMin / ONE_BLOCK_SIZE_Fl ) * ONE_BLOCK_SIZE_Fl;
    xWorldMax = viewToWorld( self.frame.size.width, self.worldRect.origin.x, self.worldRect.size.width, self.frame.size.width );
    xWorldMax = ceilf( xWorldMax / ONE_BLOCK_SIZE_Fl ) * ONE_BLOCK_SIZE_Fl;

    float yWorldMin, yWorldMax;
    yWorldMin = viewToWorld( 0.f, self.worldRect.origin.y, self.worldRect.size.height, self.frame.size.height );
    yWorldMin = floorf( yWorldMin / ONE_BLOCK_SIZE_Fl ) * ONE_BLOCK_SIZE_Fl;
    yWorldMax = viewToWorld( self.frame.size.height, self.worldRect.origin.y, self.worldRect.size.height, self.frame.size.height );
    yWorldMax = ceilf( yWorldMax / ONE_BLOCK_SIZE_Fl ) * ONE_BLOCK_SIZE_Fl;

    float vx, vy, vw, vh;
    
    float xWorldCur, yWorldCur;

    NSArray *gridMarkers = [self.document getValues];
    for( int iMarker = 0; iMarker < [gridMarkers count]; ++iMarker )
    {
        EGridBlockMarker *thisMarker = (EGridBlockMarker *)[gridMarkers objectAtIndex:iMarker];
        if( thisMarker.shadowParent != nil )
        {
            // don't draw shadows since we'll just draw the parent block exactly once.
            continue;
        }
        xWorldCur = thisMarker.gridLocation.xGrid * ONE_BLOCK_SIZE_Fl;
        yWorldCur = thisMarker.gridLocation.yGrid * ONE_BLOCK_SIZE_Fl;

        // TODO: do I really have to handle culling?
        //       seems like something that CoreGraphics would be good at. should profile this.
        
        // cull offscreen blocks
        if( xWorldCur >= xWorldMax )
        {
            continue;
        }
        if( yWorldCur >= yWorldMax )
        {
            continue;
        }
        if( xWorldCur < xWorldMin - (thisMarker.gridSize.xGrid * ONE_BLOCK_SIZE_Fl) )
        {
            continue;
        }
        if( yWorldCur < yWorldMin - (thisMarker.gridSize.yGrid * ONE_BLOCK_SIZE_Fl) )
        {
            continue;
        }
        
        // this block is (at least partially) onscreen, so draw it.
        vx = worldToView( xWorldCur, self.worldRect.origin.x, self.worldRect.size.width, self.frame.size.width);
        vy = worldToView( yWorldCur, self.worldRect.origin.y, self.worldRect.size.height, self.frame.size.height);
        vw = worldToView( thisMarker.gridSize.xGrid * ONE_BLOCK_SIZE_Fl, 0.f, self.worldRect.size.width, self.frame.size.width);
        vh = worldToView( thisMarker.gridSize.yGrid * ONE_BLOCK_SIZE_Fl, 0.f, self.worldRect.size.height, self.frame.size.height);
        CGRect boundingBox = CGRectMake( vx, vy, vw, vh);
        
        if( self.geoModeVisible )
        {
            [self drawBlockGeoViewWithBoundingBox:boundingBox toContext:context colorSeed:(int)thisMarker.preset];
        }
        else
        {
            // TODO: support non-integral case?
            NSString *thisPresetSpriteName = [EBlockPresetSpriteNames getSpriteNameForPreset:thisMarker.preset];
            SpriteDef *spriteDef = [[SpriteManager instance] getSpriteDef:thisPresetSpriteName];
            int xCount = MAX( 1, thisMarker.gridSize.xGrid / spriteDef.worldSize.width );
            int yCount = MAX( 1, thisMarker.gridSize.yGrid / spriteDef.worldSize.height );
            [self drawBlockPreset:thisMarker.preset at:boundingBox toContext:context xCount:xCount yCount:yCount];
        }
  
        if( self.drawGroupOverlay )
            [self drawBlockGroupOverlayForMarker:thisMarker at:boundingBox toContext:context];
    }
    
    if( self.cursorVisible )
    {
        float xMin = fminf( self.freeDrawStartPointWorld.x, self.freeDrawEndPointWorld.x );
        float yMin = fminf( self.freeDrawStartPointWorld.y, self.freeDrawEndPointWorld.y );
        float xMax = fmaxf( self.freeDrawStartPointWorld.x, self.freeDrawEndPointWorld.x );
        float yMax = fmaxf( self.freeDrawStartPointWorld.y, self.freeDrawEndPointWorld.y );
        xMin = [self snapCoord:xMin];
        xMax = [self snapCoordUp: xMax];
        yMin = [self snapCoord:yMin];
        yMax = [self snapCoordUp: yMax];
        
        vw = worldToView( (xMax - xMin), 0.f, self.worldRect.size.width, self.frame.size.width);
        vh = worldToView( (yMax - yMin), 0.f, self.worldRect.size.height, self.frame.size.height);
        vx = worldToView( xMin, self.worldRect.origin.x, self.worldRect.size.width, self.frame.size.width);
        vy = worldToView( yMin, self.worldRect.origin.y, self.worldRect.size.height, self.frame.size.height);
        CGRect boundingBox = CGRectMake( vx, vy, vw, vh);
        
        [self drawCursorWithBoundingBox:boundingBox toContext:context];
    }
}


-(void)drawInContext:(CGContextRef)context
{
    [super drawInContext:context];
    
    [self drawGridDocumentToContext:context];
    if( self.gridVisible )
    {
        [self drawGridToContext:context];
    }
}


-(void)setCenterPoint:(CGPoint)centerPoint
{
    // preserve existing w/h
    float w = self.worldRect.size.width;
    float h = self.worldRect.size.height;
    float offsetW = w / 2.f;
    float offsetH = h / 2.f;
    self.worldRect = CGRectMake( centerPoint.x - offsetW, centerPoint.y - offsetH, w, h );
}


-(void)doSetBlock:(EBlockPreset)preset xGrid:(NSUInteger)xGrid yGrid:(NSUInteger)yGrid wGrid:(NSUInteger)wGrid hGrid:(NSUInteger)hGrid
{
    BOOL fChangedState = [self.document setPreset: preset
                                          atXGrid: xGrid yGrid: yGrid
                                                w: wGrid h: hGrid
                                          groupId: GROUPID_NONE];
    if( fChangedState )
    {
        [self setNeedsDisplay];
        self.docDirty = YES;
        
        // if this is other than an erase, store in MRU
        if( preset != EBlockPreset_None )
        {
            EBlockMRUEntry *mruEntry = [[[EBlockMRUEntry alloc] initWithPreset:preset] autorelease];
            [self.blockMRUList pushEntry:mruEntry];
        }
    }
}


-(void)eraseBlockWithTouches:(NSSet *)touches
{
    if( self.document == nil )
    {
        NSLog( @"EWorldView drawBlock: no document." );
        return;
    }
    
    UITouch *touch;
    NSEnumerator *enumerator = [touches objectEnumerator];
    while( touch = (UITouch *)[enumerator nextObject] )
    {
        CGPoint touchPView = [touch locationInView:self];
        float wx = [self snapCoord: viewToWorld(touchPView.x, self.worldRect.origin.x, self.worldRect.size.width, self.frame.size.width)];
        float wy = [self snapCoord: viewToWorld(touchPView.y, self.worldRect.origin.y, self.worldRect.size.height, self.frame.size.height)];
        CGPoint touchPWorld = CGPointMake( wx, wy );
        NSUInteger xGrid = (NSUInteger)floorf( touchPWorld.x / ONE_BLOCK_SIZE_Fl );
        NSUInteger yGrid = (NSUInteger)floorf( touchPWorld.y / ONE_BLOCK_SIZE_Fl );
        NSUInteger wGrid = 1;
        NSUInteger hGrid = 1;
        
        [self doSetBlock:EBlockPreset_None xGrid:xGrid yGrid:yGrid wGrid:wGrid hGrid:hGrid];
    }
}


-(void)freeDrawBlock:(EBlockPreset)preset
{
    float xMin = fminf( self.freeDrawStartPointWorld.x, self.freeDrawEndPointWorld.x );
    float yMin = fminf( self.freeDrawStartPointWorld.y, self.freeDrawEndPointWorld.y );
    float xMax = fmaxf( self.freeDrawStartPointWorld.x, self.freeDrawEndPointWorld.x );
    float yMax = fmaxf( self.freeDrawStartPointWorld.y, self.freeDrawEndPointWorld.y );
    xMin = [self snapCoord:xMin];
    xMax = [self snapCoordUp: xMax];
    yMin = [self snapCoord:yMin];
    yMax = [self snapCoordUp: yMax];
    
    if( xMin == xMax || yMin == yMax )
    {
        return;
    }
    
    NSUInteger xGrid = (NSUInteger)floorf( xMin / ONE_BLOCK_SIZE_Fl );
    NSUInteger yGrid = (NSUInteger)floorf( yMin / ONE_BLOCK_SIZE_Fl );
    NSUInteger wGrid = (NSUInteger)floorf( (xMax - xMin) / ONE_BLOCK_SIZE_Fl );
    NSUInteger hGrid = (NSUInteger)floorf( (yMax - yMin) / ONE_BLOCK_SIZE_Fl );
    
    [self doSetBlock:preset xGrid:xGrid yGrid:yGrid wGrid:wGrid hGrid:hGrid];
}



// TODO: consume this from new MRU UI
-(void)selectMRUEntryAtIndex:(int)index
{
    NSAssert( index >= 0 && index < [self.blockMRUList getCurrentSize], @"Don't be an ass." );
    EBlockMRUEntry *entry = [self.blockMRUList getEntryAtOffset:index];
    [m_blockPresetStateHolder currentBlockPresetUpdated:entry.preset];
}


-(void)handleGrabWithTouches:(NSSet *)touches
{
    if( self.document == nil )
    {
        NSLog( @"EWorldView handleGrabWithEvent: no document." );
        return;
    }
    
    UITouch *touch;
    EBlockPreset grabbedPreset = EBlockPreset_None;
    NSEnumerator *enumerator = [touches objectEnumerator];
    while( touch = (UITouch *)[enumerator nextObject] )
    {
        CGPoint touchPView = [touch locationInView:self];
        CGPoint touchPWorld = CGPointMake( viewToWorld(touchPView.x, self.worldRect.origin.x, self.worldRect.size.width, self.frame.size.width),
                                           viewToWorld(touchPView.y, self.worldRect.origin.y, self.worldRect.size.height, self.frame.size.height) );
        EGridBlockMarker *marker = [self.document getMarkerAt:touchPWorld];
        if( marker != nil && marker.shadowParent != nil )
        {
            marker = marker.shadowParent;
        }
        if( marker != nil )
        {
            grabbedPreset = marker.preset;
        }
        else
        {
            grabbedPreset = EBlockPreset_None;
        }
    }
    [m_blockPresetStateHolder currentBlockPresetUpdated:grabbedPreset];
}


-(void)setGroup:(GroupId)groupId withTouches:(NSSet *)touches
{
    if( self.document == nil )
    {
        NSLog( @"EWorldView setGroup: no document." );
        return;
    }
    
    UITouch *touch;
    NSEnumerator *enumerator = [touches objectEnumerator];
    while( touch = (UITouch *)[enumerator nextObject] )
    {
        CGPoint touchPView = [touch locationInView:self];
        CGPoint touchPWorld = CGPointMake( viewToWorld(touchPView.x, self.worldRect.origin.x, self.worldRect.size.width, self.frame.size.width),
                                           viewToWorld(touchPView.y, self.worldRect.origin.y, self.worldRect.size.height, self.frame.size.height) );
        
        EGridBlockMarker *marker = [self.document getMarkerAt:touchPWorld];
        if( marker.shadowParent != nil ) marker.shadowParent.props.groupId = self.activeGroupId;
        else marker.props.groupId = self.activeGroupId;
    }
    [self setNeedsDisplay];
}


-(int)getEventTouchCount:(UIEvent *)event
{
    return (int)[[event touchesForView:self] count];
}


-(void)tryResetCurrentTouchEventPanZoomedForEvent:(UIEvent *)event
{
    // if there are no remaining touches, reset pan/zoom flag.
    // iterate over touches and check their phase, rather than just counting remaining touches.
    //  this is because it's possible for more than one touch to have ended in the same event.
    int touchCount = [self getEventTouchCount:event];
    int numDone = 0;
    NSSet *viewTouches = [event touchesForView:self];
    NSEnumerator *enumerator = [viewTouches objectEnumerator];
    UITouch *touch;
    while( touch = (UITouch *)[enumerator nextObject] )
    {
        if( touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled )
        {
            ++numDone;
        }
    }
    if( numDone == touchCount )
    {
        self.currentTouchEventPanZoomed = NO;
    }
}


-(CGPoint)getWorldPointFromTouchSet:(NSSet *)touchSet
{
    UITouch *anyTouch = (UITouch *)[touchSet anyObject];
    
    CGPoint touchPView = [anyTouch locationInView:self];
    float wx = viewToWorld(touchPView.x, self.worldRect.origin.x, self.worldRect.size.width, self.frame.size.width);
    float wy = viewToWorld(touchPView.y, self.worldRect.origin.y, self.worldRect.size.height, self.frame.size.height);
    return CGPointMake( wx, wy );
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    int touchCount = [self getEventTouchCount:event];
    if( touchCount == 1 )
    {
        if( self.currentToolMode == ToolModeDrawBlock )
        {
            self.freeDrawStartPointWorld = [self getWorldPointFromTouchSet:touches];
            self.freeDrawEndPointWorld = self.freeDrawStartPointWorld;
            self.cursorVisible = YES;
            [self setNeedsDisplay];
        }
    }
    else
    {
        self.cursorVisible = NO;
        [self setNeedsDisplay];
        self.currentTouchEventPanZoomed = YES;  // this event caused a pan/zoom, no other tools can execute for this event.
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    int touchCount = [self getEventTouchCount:event];
    if( touchCount == 1 )
    {
        if( !self.currentTouchEventPanZoomed )
        {
            self.freeDrawEndPointWorld = [self getWorldPointFromTouchSet:touches];
            self.cursorVisible = YES;
            [self setNeedsDisplay];
        }
    }
    else if( touchCount == 2 )
    {
        [m_panZoomGestureProcessor touchesMoved:touches withEvent:event inView:self];
    }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( !self.currentTouchEventPanZoomed )
    {
        if( self.currentToolMode == ToolModeDrawBlock )
        {
            [self freeDrawBlock:[m_blockPresetStateHolder getCurrentBlockPreset]];
        }
        else if( self.currentToolMode == ToolModeErase )
        {
            [self eraseBlockWithTouches:touches];
        }
        else if( self.currentToolMode == ToolModeGroup )
        {
            [self setGroup:self.activeGroupId withTouches:touches];
        }
        else if( self.currentToolMode == ToolModeGrab )
        {
            [self handleGrabWithTouches:touches];
            
            // inform event delegate that a block was grabbed (so that the tool mode can get switched back to Draw)
            if( self.worldViewEventCallback != nil )
            {
                [self.worldViewEventCallback onGrabbedPreset];
            }
        }
        self.cursorVisible = NO;
        [self setNeedsDisplay];
    }
    [self tryResetCurrentTouchEventPanZoomedForEvent:event];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self tryResetCurrentTouchEventPanZoomedForEvent:event];
}


-(void)onZoomByFactor:(float)factor centeredOnViewPoint:(CGPoint)centerPointView
{
    float wNew = self.worldRect.size.width * factor;
    float hNew = self.worldRect.size.height * factor;

    // translates to adjust for non-true center point, then zooms, then translates back.
    
    float xCenterDeltaView = centerPointView.x - ( self.frame.size.width / 2.f );
    float yCenterDeltaView = centerPointView.y - ( self.frame.size.height / 2.f );
    float xCenterDeltaWorld = viewToWorld( xCenterDeltaView, 0.f, self.worldRect.size.width, self.frame.size.width );
    float yCenterDeltaWorld = viewToWorld( yCenterDeltaView, 0.f, self.worldRect.size.height, self.frame.size.height );
    
    float xCenterWorld = self.worldRect.origin.x + (self.worldRect.size.width / 2.f);
    xCenterWorld -= xCenterDeltaWorld * factor;
    float xNew = xCenterWorld + xCenterDeltaWorld - (wNew / 2.f);
    
    float yCenterWorld = self.worldRect.origin.y + (self.worldRect.size.height / 2.f);
    yCenterWorld -= yCenterDeltaWorld * factor;
    float yNew = yCenterWorld + yCenterDeltaWorld - (hNew / 2.f);

    xNew = fmaxf( xNew, 0.f );
    yNew = fmaxf( yNew, 0.f );

    self.worldRect = CGRectMake( xNew, yNew, wNew, hNew );

    [self setNeedsDisplay];
}


-(void)onPanByViewUnits:(CGPoint)vector
{
    // convert view units to world units first.
    float deltaXWorld = self.worldRect.size.width  * (vector.x / self.frame.size.width );
    float deltaYWorld = self.worldRect.size.height * (vector.y / self.frame.size.height );
    
    float xNewUnclipped = self.worldRect.origin.x - deltaXWorld;
    float yNewUnclipped = self.worldRect.origin.y - deltaYWorld;
    
    float xNew = fmaxf( 0.f, xNewUnclipped );
    float yNew = fmaxf( 0.f, yNewUnclipped );
    
    if( xNew != xNewUnclipped || yNew != yNewUnclipped )
    {
        NSLog( @"clipping edit view rect to a zero" );
    }
    
    self.worldRect = CGRectMake( xNew, yNew, self.worldRect.size.width, self.worldRect.size.height );
    
    [self setNeedsDisplay];
}


-(void)setPresetStateHolder:(id<ICurrentBlockPresetStateHolder>)holder
{
    m_blockPresetStateHolder = holder;  // weak;
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EPanZoomProcessor

@implementation EPanZoomProcessor

-(id)init
{
    if( self = [super init] )
    {
    }
    return self;
}


-(void)dealloc
{
    m_consumer = nil;  // weak
    [super dealloc];
}


-(void)registerConsumer:(id<IPanZoomResultConsumer>)consumer
{
    m_consumer = consumer;  // weak
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event inView:(UIView *)view
{
}


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event inView:(UIView *)view
{
    // every move event causes both a pan and a zoom (either of which may be a no-op).
    NSSet *viewTouches = [event touchesForView:view];
    UITouch *touch;
    int touchCount = (int)[viewTouches count];
    if( touchCount != 2 )
    {
        NSAssert( NO, @"Assume panZoomProcessor only gets events with 2 active touches." );
        return;
    }

    NSMutableArray *pPArray = [NSMutableArray array];  // array (of size 2) of previous points
    NSMutableArray *pCArray = [NSMutableArray array];  // array (of size 2) of current points
    
    NSEnumerator *enumerator = [viewTouches objectEnumerator];
    while( touch = (UITouch *)[enumerator nextObject] )
    {
        CGPointW *prevPositionForTouch = [CGPointW fromPoint:[touch previousLocationInView:view]];
        CGPointW *curPositionForTouch = [CGPointW fromPoint:[touch locationInView:view]];
        [pPArray addObject:prevPositionForTouch];
        [pCArray addObject:curPositionForTouch];
    }
    
    CGPointW *pws0 = (CGPointW *)[pPArray objectAtIndex:0];
    CGPointW *pws1 = (CGPointW *)[pPArray objectAtIndex:1];
    CGPointW *pwc0 = (CGPointW *)[pCArray objectAtIndex:0];
    CGPointW *pwc1 = (CGPointW *)[pCArray objectAtIndex:1];
    CGPoint psCenter = CGPointMake( (pws0.x + pws1.x) / 2.f, (pws0.y + pws1.y) / 2.f);
    CGPoint pcCenter = CGPointMake( (pwc0.x + pwc1.x) / 2.f, (pwc0.y + pwc1.y) / 2.f);
    
    float sDistance = sqrtf( ((pws1.x - pws0.x) * (pws1.x - pws0.x)) + ((pws1.y - pws0.y) * (pws1.y - pws0.y)) );
    float cDistance = sqrtf( ((pwc1.x - pwc0.x) * (pwc1.x - pwc0.x)) + ((pwc1.y - pwc0.y) * (pwc1.y - pwc0.y)) );
    
    float zoomFactor = 1.f;
    if( cDistance != 0.f )
    {
        zoomFactor = sDistance / cDistance;
    }
    [m_consumer onZoomByFactor:zoomFactor centeredOnViewPoint:psCenter];
    
    CGPoint panVector = subtractVectors( pcCenter, psCenter );
    [m_consumer onPanByViewUnits:panVector];
}


-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event inView:(UIView *)view
{
}


-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event inView:(UIView *)view
{
}

@end

